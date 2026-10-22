=head1 NAME

AnyEvent::MCP::Helper - asynchronous JSON exchange with an external helper

=head1 SYNOPSIS

   use AnyEvent::MCP::Helper;
   my $job = AnyEvent::MCP::Helper->new (
      helper => ["my-helper", "--option"], timeout => 300,
   );
   $job->ask ($input, sub {
      my ($success, $result) = @_;
      ...
   });

=head1 DESCRIPTION

Runs an executable (or an argument array, never a shell command), writes one
UTF-8 JSON value to its stdin and closes that input. A successful helper
writes one JSON value to stdout and exits zero. Diagnostics use stderr.

C<ask ($input, $done)> calls C<$done-E<gt>($success, $result)> once. On failure,
C<$result> is an error string. One exchange may be active per object.
C<timeout> defaults to 300 seconds and C<max_size> to 1 MiB of output.
C<cancel ($reason)> terminates the helper and completes with failure.
The independent child watcher reaps the helper after cancellation too.

This module handles processes and bytes, not the meaning of the JSON.
It is the transport for local form and permission helpers: an MCP server
or multibroker can ask a human without blocking its AnyEvent loop.
Ordinary server authors should normally use
L<AnyEvent::MCP::Server::Permissions> or the form facilities in
L<AnyEvent::MCP::Permissions::Ask>, not launch helpers directly.
L<AnyEvent::MCP::Permissions::Ask> provides the permission interface;
C<anyevent-mcp-form-elicitation> implements the standard form request/response contract.

=cut

package AnyEvent::MCP::Helper;

use common::sense;
use AnyEvent::MCP ();
use AnyEvent ();
use AnyEvent::Util ();
use AnyEvent::Handle ();
use JSON::XS ();
use Scalar::Util qw(weaken);

our @ISA = qw(AnyEvent::MCP::Base);

sub ask {
   my ($self, $prepared, $done) = @_;

   die "Helper is already active\n" if $self->{on_done};
   $self->{finished} = 0;
   $self->{on_done} = $done;
   delete @$self{qw(status eof)};
   my $helper = $self->{helper} or die "No helper configured\n";
   my $input = JSON::XS::encode_json $prepared;
   my $output = "";
   my $ok = eval {
      my ($parent, $child) = AnyEvent::Util::portable_socketpair;
      die "Cannot create helper socket: $!\n" unless defined $parent && defined $child;
      $self->{cv} = AnyEvent::Util::run_cmd (
         ref $helper eq "ARRAY" ? $helper : [$helper],
         "<" => $child, ">" => $child, '$$' => \$self->{pid}, close_all => 1,
      );
      close $child;
      weaken $self;
      $self->{handle} = AnyEvent::Handle->new (
         fh       => $parent,
         on_error => sub { $self->cancel ("Helper socket: $_[2]") if $self },
         on_read  => sub {
            return unless $self && !$self->{finished};
            $output .= $_[0]{rbuf};
            $_[0]{rbuf} = "";
            $self->cancel ("Helper output exceeds size limit")
               if length $output > ($self->{max_size} || 1024 * 1024);
         },
         on_eof => sub {
            return unless $self && !$self->{finished};
            $self->{eof} = 1;
            $self->_complete ($output);
         },
      );
      $self->{handle}->push_write ($input);
      $self->{handle}->push_shutdown;
      $self->{cv}->cb (sub {
         my $status = $_[0]->recv;
         return unless $self;
         delete $self->{pid}; # The child is reaped even if descendants keep stdout open.
         return if $self->{finished};
         $self->{status} = $status;
         $self->_complete ($output);
      });
      $self->{timer} = AnyEvent->timer (after => $self->{timeout} || 300, cb => sub {
         $self->cancel ("Helper timed out") if $self;
      });
      1
   };
   $self->_finish (0, "$@") unless $ok;
}

sub _complete {
   my ($self, $output) = @_;

   return unless defined $self->{status} && $self->{eof};
   return $self->_finish (0, "Helper exited with status $self->{status}") if $self->{status};
   my $decision = eval { JSON::XS::decode_json $output };
   return $self->_finish (0, "Invalid helper JSON: $@") if $@;
   $self->_finish (1, $decision);
}

sub _finish {
   my ($self, $success, $result) = @_;

   return if $self->{finished};
   $self->{finished} = 1;
   delete @$self{qw(cv timer)};
   (delete $self->{handle})->destroy if $self->{handle};
   my $done = delete $self->{on_done};
   $done->($success, $result) if $done;
}

sub cancel {
   my ($self, $reason) = @_;

   return if $self->{finished};
   kill TERM => delete $self->{pid} if $self->{pid};
   $self->_finish (0, defined $reason ? $reason : "Helper cancelled");
}

sub DESTROY {
   $_[0]->cancel
}

1
