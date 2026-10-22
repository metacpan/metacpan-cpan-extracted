=head1 NAME

AnyEvent::MCP::Client::Request - a request for client input

=head1 DESCRIPTION

An MCP server may need input from the client before it can finish a tool call.
In that case C<on_request> receives this object. You can retain it while a
human answers a dialog, then call C<reply> or C<error>. A legacy incoming
request uses the same interface.

The fields C<client>, C<id>, C<method>, C<params>, C<operation> (the original
local call, when known), C<protocol_version>, C<finished> and C<cancelled>
are accessible directly. Do not reply after cancellation.

Usually you encounter this object in an
L<AnyEvent::MCP::Client/on_request> callback, rather than constructing it:

   on_request => sub {
      my ($client, $req) = @_;
      if ($req->{method} eq "elicitation/create") {
         $req->reply ({ action => "decline" });
      } else {
         $req->error (-32601, "Unsupported input method");
      }
   },

For real human prompting, see
L<AnyEvent::MCP::Permissions::Ask> instead.

=head1 METHODS

=over

=item $req->reply ($result)

Completes the input request with a result hash reference. Duplicate replies
die. Protocol field spelling, such as C<resultType>, is preserved.

=item $req->error ($code, $message, $data)

Reports a JSON-RPC error. C<$data> is optional. For modern input this fails
the local operation; for legacy requests it sends an error response.

=item $req->cancel

Marks the request finished and cancelled, releases its completion callback
and calls C<< $req->{on_cancel}->($req) >> when present. Repeated cancellation
is harmless. Applications can use C<on_cancel> to close an outstanding prompt.

=back

=cut

package AnyEvent::MCP::Client::Request;

use common::sense;
use AnyEvent::MCP ();
use Scalar::Util qw(weaken);

our @ISA = qw(AnyEvent::MCP::Base);

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (@_);
   weaken $self->{client};
   $self
}

sub _finish {
   my ($self, $success, $result) = @_;

   die "Request already finished\n" if $self->{finished};
   $self->{finished} = 1;
   delete $self->{on_cancel};
   (delete $self->{on_reply})->($success, $result);
}

sub reply {
   my ($self, $result) = @_;

   $result = { resultType => "complete", %$result } if $self->{protocol_version} ge "2026";
   $self->_finish (1, $result);
}

sub error {
   my ($self, $code, $message, $data) = @_;

   $self->_finish (0, { code => $code, message => $message, (defined $data ? (data => $data) : ()) });
}

sub cancel {
   my ($self) = @_;

   return if $self->{finished};
   $self->{finished} = $self->{cancelled} = 1;
   delete $self->{on_reply};
   my $cancel = delete $self->{on_cancel};
   $cancel->($self) if $cancel;
}

1
