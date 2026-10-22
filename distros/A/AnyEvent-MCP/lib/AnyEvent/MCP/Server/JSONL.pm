=head1 NAME

AnyEvent::MCP::Server::JSONL - MCP over a newline-delimited byte stream

=head1 DESCRIPTION

Use this transport for stdio servers or an existing stream connection.
It implements L<AnyEvent::MCP::Server> over newline-delimited UTF-8 JSON-RPC:
one line is one complete message. Keep diagnostic output off the protocol
stream; a banner or log message on stdout is not a JSON-RPC response.

Unlike HTTP, replies can complete in a different order from requests.
The JSON-RPC ids associate them with the correct calls.

=head1 EXAMPLE

An application that already owns its tool registry and lifetime can
serve one stdio MCP connection:

   use AnyEvent;
   use AnyEvent::MCP::Server::JSONL;

   my $server = AnyEvent::MCP::Server::JSONL->new (
      toolsets => [$tools],
   );
   $server->accept (\*STDIN, \*STDOUT);
   AE::cv->recv;

C<$tools> is an L<AnyEvent::MCP::Server::Toolset>. Keep stdout reserved
for MCP messages and write diagnostics to stderr. The application is
responsible for its event loop and termination. If you do not need to
manage those details, use L<AnyEvent::MCP::Server::Simple/mcp_stdio>.
The matching client transport is L<AnyEvent::MCP::Client::JSONL>.

=head1 METHODS

=over

=item $handle = $server->accept ($fh, $fh_out)

Starts handling C<$fh>. If C<$fh_out> is supplied, it receives outgoing
messages; otherwise C<$fh> is used in both directions. Both handles belong
to the server until the connection closes.

With separate input/output handles, input EOF waits for pending replies
and drains the output before closing. EOF on a bidirectional socket closes
it immediately and cancels outstanding requests.

C<max_size> limits a buffered incoming message, defaulting to 1 MiB.

=item $server->close

Closes the server's connections and cancels outstanding requests.

=back

=head1 EVENTS

=over

=item on_connection_error => $callback->($server, $handle, $message)

Called for stream errors before closing the connection.

=item on_connection_close => $callback->($server, $handle)

Called after a connection has closed.

=item on_close => $callback->($server)

Called by C<close> after closing all connections.

=back

=head1 MANAGED SHUTDOWN

=over

=item $server->request_idle_exit

Requests a managed shutdown, once, from a spawned stdio multibroker child
whose peer advertised C<anyevent-mcp/multibroker> version 1. The application
decides when it is idle. The method returns true when it sends the notification, or undef when
there is no eligible connection or it has already sent one.
The broker can ignore the notification. When it sends shutdown, the server
answers before draining the stream and closing its connections. Closing
the server lets Simple's blocking starter return; an embedding application
controls its own process lifetime.

C<on_idle_shutdown>, if supplied, is C<$callback->($server)> returning true
to accept or false to decline a late shutdown request (for example, if
application work has resumed). Outstanding MCP requests also prevent
acceptance.

=back

=cut

package AnyEvent::MCP::Server::JSONL;

use common::sense;
use parent "AnyEvent::MCP::Server";
use AnyEvent::Handle ();
use AnyEvent ();
use JSON::XS ();
use Scalar::Util qw(weaken);

sub accept {
   my ($self, $fh, $fh_out) = @_;

   delete $self->{_closed};
   weaken $self;

   my $handle = AnyEvent::Handle->new (
      fh       => $fh,
      rbuf_max => $self->{max_size} || 1024 * 1024,
      on_read  => sub { $self->_read ($_[0]) if $self },
      on_error => sub {
         my ($handle, $fatal, $message) = @_;

         $self->event (connection_error => $handle, $message) if $self;
         $self->_close ($handle) if $self;
      },
      on_eof => sub {
         return unless $self;
         my ($handle) = @_;

         if ($handle->{mcp_out}) {
            $handle->{mcp_eof} = 1;
            $self->_drain ($handle);
         } else {
            $self->_close ($handle);
         }
      },
   );

   if ($fh_out) {
      $handle->{mcp_out} = AnyEvent::Handle->new (
         fh       => $fh_out,
         on_error => sub {
            $self->event (connection_error => $_[0], $_[2]) if $self;
            $self->close if $self;
         },
      );
   }

   $handle->{mcp_peer} = {};
   $handle->{mcp_peer}{mcp_handle} = $handle;
   weaken $handle->{mcp_peer}{mcp_handle};
   $self->{connections}{$handle} = $handle;

   $handle
}

sub _read {
   my ($self, $handle) = @_;

   weaken $self;

   $handle->push_read (line => sub {
      my ($handle, $line) = @_;

      return unless $self;

      ++$handle->{mcp_active};
      $self->json_rpc (
         $line,
         sub {
            --$handle->{mcp_active};
            return if $handle->{mcp_closed};

            ($handle->{mcp_out} || $handle)->push_write ($_[0] . "\n")
               if defined $_[0];
            $self->_drain ($handle) if $handle->{mcp_eof};
         },
         peer      => $handle->{mcp_peer},
         on_notify => sub {
            return if $handle->{mcp_closed};

            ($handle->{mcp_out} || $handle)->push_write (JSON::XS::encode_json ($_[1]) . "\n");
         },
      );
   });
}

sub request_idle_exit {
   my ($self) = @_;

   return unless $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL} eq "stdio"
      && !$self->{idle_exit_requested};

   for my $handle (values %{$self->{connections}}) {
      next if $handle->{mcp_closed} || !$handle->{mcp_peer}{aemcp_multibroker};

      ($handle->{mcp_out} || $handle)->push_write (JSON::XS::encode_json ({
         jsonrpc => "2.0", method => "anyevent-mcp/idle-exit", params => {},
      }) . "\n");
      $self->{idle_exit_requested} = 1;
      return 1
   }

   undef
}

sub dispatch {
   my ($self, $req) = @_;

   if ($req->{method} eq "anyevent-mcp/shutdown") {
      my $handle = $req->{peer}{mcp_handle};
      my $busy = grep $_->{mcp_active} > ($_ == $handle ? 1 : 0),
                      values %{$self->{connections}};
      my $accepted = $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL} eq "stdio"
         && $req->{peer}{aemcp_multibroker} && $self->{idle_exit_requested}
         && !$self->{_idle_shutting_down} && !$busy
         && (!$self->{on_idle_shutdown} || $self->{on_idle_shutdown}->($self));

      $req->reply ({ accepted => $accepted ? JSON::XS::true : JSON::XS::false });
      if ($accepted) {
         $self->{_idle_shutting_down} = 1;
         my $out = $handle->{mcp_out} || $handle;
         weaken $self;
         if (length $out->{wbuf}) {
            $out->on_drain (sub { $self->close if $self });
         } else {
            AnyEvent::postpone (sub { $self->close if $self });
         }
      }

      return;
   }

   $self->SUPER::dispatch ($req)
}

sub _drain {
   my ($self, $handle) = @_;

   return if $handle->{mcp_active} || $handle->{mcp_closed};

   my $output = $handle->{mcp_out};
   if (length $output->{wbuf}) {
      weaken $self;
      $output->on_drain (sub { $self->_close ($handle) if $self });
   } else {
      $self->_close ($handle);
   }
}

sub _close {
   my ($self, $handle) = @_;

   return if $handle->{mcp_closed};
   $handle->{mcp_closed} = 1;

   my $requests = delete $handle->{mcp_peer}{requests} || {};
   $_->cancel ("Connection closed") for grep defined, values %$requests;

   delete $self->{connections}{$handle};
   $handle->{mcp_out}->destroy if $handle->{mcp_out};
   $handle->destroy;
   $self->event (connection_close => $handle);
}

sub close {
   my ($self) = @_;

   return if $self->{_closed}++;
   delete $self->{listener};
   $self->_close ($_) for values %{$self->{connections} || {}};
   $self->event (close =>);
}

sub DESTROY {
   $_[0]->close
}

1
