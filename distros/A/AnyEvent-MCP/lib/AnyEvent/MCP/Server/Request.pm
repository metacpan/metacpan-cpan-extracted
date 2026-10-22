=head1 NAME

AnyEvent::MCP::Server::Request - one MCP request

=head1 DESCRIPTION

Each incoming request gets a Request object. The handler can reply
immediately, or keep the object and reply when asynchronous work finishes.
Returning from the handler does not complete the request; calling
C<reply>, C<result> or C<error> does.

There is one important consequence: do not reply after cancellation or after
another callback has already completed the request. Check C<finished> in
late asynchronous callbacks. A second reply is a programming error.

You normally receive this object as the first argument to a
L<AnyEvent::MCP::Server::Toolset> callback. See
L<AnyEvent::MCP::Server::Simple/TUTORIAL> for complete synchronous and
asynchronous examples rather than constructing requests yourself.

=head1 PUBLIC FIELDS

Request fields are accessed directly through the hash.

=over

=item $req->{server}

The server handling this request.

=item $req->{id}

The JSON-RPC request id, used to associate the response with the request.

=item $req->{method}

The JSON-RPC method name, such as C<tools/call>.

=item $req->{protocol_version}

The protocol revision used for this request. Modern requests supply it in
C<_meta>; legacy requests use the initialized peer or HTTP version.

=item $req->{peer}

The connection's peer hash reference, supplied by the transport or embedder.
It holds transport context and legacy state, rather than a user identity.
Modern client identity and capabilities come from this request's C<_meta>.

=item $req->{params}

The original decoded JSON-RPC parameters. For a tool call, this hash contains
C<name>, C<arguments> and any C<_meta> supplied by the client. These are the
protocol parameters, rather than just the tool arguments.

=item $req->{tool}

The tool name from C<< $req->{params}{name} >>. Present for tool calls.

=item $req->{args}

The tool argument hash reference from C<< $req->{params}{arguments} >>.
Present for tool calls. The tool callback also receives this same reference
as its second parameter, for convenience.

=item $req->{toolset}

The Toolset invoking the tool callback. Set by the Toolset when it dispatches
the call; absent for requests dispatched without a Toolset.

=item $req->{finished}

True after a reply or cancellation. Replying to a finished request is an
error. Notifications and progress after completion are ignored.

=item $req->{cancelled}

True if the request was cancelled. An asynchronous handler can check this
before attempting to reply.

=back

=head1 METHODS

=over

=item $grant = $req->require_permission ({ %request })

Synchronously checks a permission request using the server's C<permissions>
object. C<%request> has the fields described by
L<AnyEvent::MCP::Server::Permissions/check>. Returns the granted sandbox-grant
array reference; it can be reduced from the requested set.

A denial dies. A missing permission throws a special exception handled by
Server, which asks and retries the handler. Multiple checks are supported:
one-time grants belong to this tool invocation and survive permission retries.
They do not authorize later calls. Current rules are checked on every retry.

Complete all checks before side effects or asynchronous work starts.
The handler can run more than once. Do not catch the permission exception
as an ordinary tool error; let it reach Server's dispatch boundary.

=item $req->reply ($result)

Completes the request with the MCP result hash reference C<$result>. The
server adds the JSON-RPC envelope. Tools do not construct JSON-RPC errors.
Dies if the request has already finished.

Use this method for arbitrary MCP results, including structured errors,
large results and results requiring a particular content representation.

=item $req->error ($message)

Replies with C<isError> set to true and C<$message> as one text content item.
Use C<reply> for errors with structured content or other content types.

=item $req->result ($data)

Replies with the hash reference C<$data> as C<structuredContent>, and its
JSON encoding as one text content item for clients that consume only text.

This deliberately duplicates the data. Use C<reply> for large results or
when JSON text is unsuitable, including clients that encode text as JSON
again. Arrays and scalars must be wrapped in an object explicitly.

=item $req->notify ($method, $params)

Sends a notification associated with this request. C<$method> is the
notification method name and C<$params> its parameter hash reference.

A notification does not complete the request. Delivery is best effort:
notifications can be dropped if the transport does not implement delivery.
Calls after completion are ignored.

=item $req->progress ($progress, $total, $message)

Sends a progress notification if the client supplied a progress token in
C<< $req->{params}{_meta}{progressToken} >>. C<$progress> is the amount
completed; C<$total> and C<$message> can be omitted or undefined.

Uses C<notify>, with the same best-effort delivery. Calls after completion
are ignored.

=item $req->cancel ($reason)

Marks the request as cancelled and calls C<on_cancel>, allowing the handler
to stop work and release resources. C<$reason> is an optional explanation.

Cancellation completes the transport's request bookkeeping without sending
a JSON-RPC response.

=back

=head1 EVENTS

These callbacks are stored in the request hash like other MCP events.

=over

=item on_reply => $callback->($req, $result)

Called once when the request is completed with C<reply>. The server installs
C<$callback> to deliver the result.

=item on_notify => $callback->($req, $method, $params)

Called for each notification while the request is active. The server installs
C<$callback> to deliver notifications through the transport.

=item on_cancel => $callback->($req, $reason)

Called once when the request is cancelled. A handler can set C<$callback>
to cancel its asynchronous operation.

=back

=cut

package AnyEvent::MCP::Server::Request;

use common::sense;
use AnyEvent::MCP ();
use JSON::XS ();

our @ISA = qw(AnyEvent::MCP::Base);

sub require_permission {
   my ($self, $request) = @_;

   my $permissions = $self->{server}{permissions}
      or die "Server has no permission configuration\n";

   $permissions->require_permission ($self, $request)
}

sub reply {
   my ($self, $result) = @_;

   die "MCP request already finished\n"
      if $self->{finished};

   $self->{finished} = 1;

   my $reply = delete $self->{on_reply};
   delete @$self{qw(on_notify on_cancel _reply)};

   $reply->($self, $result) if $reply
}

sub error {
   my ($self, $message) = @_;

   $self->reply ({
      isError => JSON::XS::true,
      content => [{ type => "text", text => $message }],
   })
}

sub result {
   my ($self, $data) = @_;

   ref $data eq "HASH"
      or die "MCP structured result must be an object\n";

   $self->reply ({
      structuredContent => $data,
      content           => [{ type => "text", text => JSON::XS->new->encode ($data) }],
   })
}

sub notify {
   my ($self, $method, $params) = @_;

   return if $self->{finished};

   $self->event (notify => $method, $params)
}

sub progress {
   my ($self, $progress, $total, $message) = @_;

   return unless $self->{on_notify} && !$self->{finished};

   my $meta = $self->{params}{_meta}
      or return;

   return unless exists $meta->{progressToken};

   my $params = {
      progressToken => $meta->{progressToken},
      progress      => $progress,
   };

   $params->{total}   = $total   if defined $total;
   $params->{message} = $message if defined $message;

   $self->notify ("notifications/progress", $params)
}

sub cancel {
   my ($self, $reason) = @_;

   return if $self->{finished};
   $self->{finished} = $self->{cancelled} = 1;

   delete $self->{peer}{requests}{$self->{id}}
      if $self->{peer};

   my $cancel = delete $self->{on_cancel};
   my $reply = delete $self->{_reply};
   delete @$self{qw(on_reply on_notify)};

   $cancel->($self, $reason) if $cancel;
   $reply->(undef) if $reply
}

1
