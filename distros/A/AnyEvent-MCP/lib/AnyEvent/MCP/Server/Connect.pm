=head1 NAME

AnyEvent::MCP::Server::Connect - reverse-connecting MCP JSONL server

=head1 DESCRIPTION

This JSONL server connects to a multibroker's HTTP/extension listener using
C<connect =E<gt> "http://host:port/token/alias">. It sends
C<["mcp-connect", token, alias]> and then ordinary MCP JSONL messages.
The TCP initiator remains the MCP server; the multibroker is the MCP client.

This is useful when the MCP server must connect outward, rather than
exposing its own HTTP listener. The multibroker can accept connections
under an alias that becomes a tool-name prefix. For a standalone
server, C<AnyEvent::MCP::Server::Simple> handles the startup details;
use this object directly if your application already owns its event loop.

   use AnyEvent;
   use AnyEvent::MCP::Server::Connect;

   my $server = AnyEvent::MCP::Server::Connect->new (
      connect => "http://127.0.0.1:31740/TOKEN/files",
      toolsets => [$tools],
   );
   $server->start;
   AE::cv->recv;

C<$tools> is an L<AnyEvent::MCP::Server::Toolset> registered by your
application. The URL identifies a raw-TCP extension listener, despite
its C<http://> spelling; it is not an HTTP POST endpoint. See
L<mcp-multibroker/Reverse connections> for setting up the other side.

=head1 METHODS

=over

=item $server->start

Attempt a connection immediately. Retry failures every second, up to sixty
attempts, and start a new retry period after an established connection closes.
Exhaustion closes the server. Outstanding requests are cancelled, not replayed.

=item $server->close

Cancel pending connections and retries, close streams and cancel requests.
Connecting remotely grants no managed child-shutdown authority.

=back

=cut

package AnyEvent::MCP::Server::Connect;

use common::sense;
use parent "AnyEvent::MCP::Server::JSONL";
use AnyEvent::MCP::Extension ();
use AnyEvent::Socket ();
use AnyEvent ();
use JSON::XS ();
use Scalar::Util qw(weaken);

sub new {
   my ($class, %kv) = @_;

   my $self = $class->SUPER::new (%kv);
   $self->{endpoint} = [AnyEvent::MCP::Extension::parse_url $self->{connect}];
   my $on_close = $self->{on_connection_close};
   weaken (my $weak = $self);
   $self->{on_connection_close} = sub {
      $on_close->(@_) if $on_close;
      $weak->start if $weak && !$weak->{_closed};
   };

   $self
}

sub start {
   my ($self) = @_;

   return if $self->{retry};
   delete $self->{_closed};
   $self->{attempts} = 0;
   weaken $self;
   $self->{retry} = AE::timer 0, 1, sub {
      return unless $self;
      return if $self->{connector};

      if (++$self->{attempts} > 60) {
         AE::log warn => "MCP reverse connection: giving up after sixty attempts";
         $self->close;
         return
      }

      my ($host, $port, $token, $alias) = @{$self->{endpoint}};
      $self->{connector} = AnyEvent::Socket::tcp_connect $host, $port, sub {
         delete $self->{connector} if $self;
         my ($fh) = @_;
         return unless $self && !$self->{_closed};

         unless ($fh) {
            AE::log debug => "MCP reverse connection '$alias': $!";
            return
         }

         delete $self->{retry};
         my $handle = $self->accept ($fh);
         $handle->push_write (JSON::XS::encode_json (["mcp-connect", $token, $alias]) . "\n");
      }, sub { 1 };
   };
}

sub request_idle_exit {
   undef
}

sub close {
   my ($self) = @_;

   delete @$self{qw(retry connector)};
   $self->SUPER::close;
}

1;
