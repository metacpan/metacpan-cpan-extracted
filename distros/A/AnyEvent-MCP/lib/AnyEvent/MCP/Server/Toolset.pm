=head1 NAME

AnyEvent::MCP::Server::Toolset - MCP tool declarations and callbacks

=head1 DESCRIPTION

A Toolset answers two questions: which tools exist, and what code should run
when one is called? It holds tool declarations and their callbacks, but no
transport or client state. You can therefore give the same Toolset to
several servers without copying or re-registering the tools.

If your program only needs one standalone server, the function interface in
L<AnyEvent::MCP::Server::Simple> manages a default Toolset for you.

=head1 EXAMPLE

   use AnyEvent::MCP::Server::Toolset;
   use AnyEvent::MCP::Server::HTTP;

   my $tools = AnyEvent::MCP::Server::Toolset->new;
   $tools->tool (echo => "Echo the supplied text",
      {
         type => "object", required => ["text"],
         properties => { text => { type => "string" } },
      },
      sub {
         my ($req, $args) = @_;
         $req->result ({ text => $args->{text} });
      },
   );

   my $server = AnyEvent::MCP::Server::HTTP->new (
      toolsets => [$tools], tokens => [$secret],
   );

Here C<$secret> is an application-provided HTTP token. The server still
needs C<< $server->listen >> and an event loop; see
L<AnyEvent::MCP::Server::HTTP>. The Toolset does not create connections.
For a complete standalone script, use
L<AnyEvent::MCP::Server::Simple/TUTORIAL> instead.

=head1 REQUEST AND TOOL WORKFLOW

Register tools with C<tool>, then pass the Toolset to a server through its
C<toolsets> option. The server handles the protocol and transport; the Toolset
supplies declarations for C<tools/list> and callbacks for C<tools/call>.

For a tool call, the server creates an L<AnyEvent::MCP::Server::Request>,
sets C<< $req->{tool} >> and C<< $req->{args} >>, and calls its C<on_request>
hook. It then finds the first Toolset containing that tool and invokes its
callback as C<$callback->($req, $args)>. C<$args> is the same hash reference
as C<< $req->{args} >>; C<< $req->{toolset} >> identifies the invoking Toolset.

The input schema describes the arguments to the client; the server does not
validate arguments against it. The handler must validate the arguments it
uses and complete the request with one reply.

=head2 Permission checks and retries

Configure the server's C<permissions> option with an
L<AnyEvent::MCP::Server::Permissions> object. The handler can check several
paths or operations in sequence:

   sub {
      my ($req, $args) = @_;

      my $source_grant = $req->require_permission ({
         tool => $req->{tool},
         dimensions => { subject => {
            label => "Source file", value => $args->{source},
            choices => [{ label => "source file", match => $args->{source} }],
         } },
         action => "read", sandbox_grants => ["workdir-read"],
         reason => "read the source file",
      });

      my $destination_grant = $req->require_permission ({
         tool => $req->{tool},
         dimensions => { subject => {
            label => "Destination file", value => $args->{destination},
            choices => [{ label => "destination file", match => $args->{destination} }],
         } },
         action => "write", sandbox_grants => ["workdir-write"],
         reason => "write the destination file",
      });

      ... # read using $source_grant, write using $destination_grant
      $req->result ({ ... });
   }

This example assumes both paths are inside the selected workdir and that
the application enforces the returned grants. C<action> chooses the kind
of operation to authorize; C<sandbox_grants> chooses the worker's authority.
Grant names and their implications belong to the application.
C<require_permission> returns the granted sandbox-grant array reference,
which may be smaller than the requested set. Execute using those grants
rather than assuming that everything requested was allowed.

Grants are separate; Server does not combine them. When reading the source
and writing the destination separately, use each grant for its corresponding
operation.

Combining authority is needed when one operation spans several subjects,
such as renaming a file. Request the required action and sandbox grants for
every affected path: a rename needs write authority for both source and
destination, unlike the read/write example above. Check that every grant
still permits the operation after any reductions. For an application using
C<workdir-write> for a rename within one workdir, after requesting that grant
for both paths:

   my $permissions = $req->{server}{permissions};
   my $source = $permissions->closure ($source_grant);
   my $destination = $permissions->closure ($destination_grant);

   $source->{"workdir-write"} && $destination->{"workdir-write"}
      or die "Rename needs write permission for both paths\n";

C<closure> includes implied sandbox grants. If the operation needs one
combined grant set, use the intersection of these closures, rather than their
union: authority granted for one path must not authorize the other.
Do this before starting the operation.

A denial dies and becomes a tool error. The first missing permission throws
a special exception: Server catches it and asks. Modern MCP asking replies
with C<input_required>; the client supplies the answer in a repeated call.
Local asking, including the legacy fallback, retries the handler internally.
An explicit local asking configuration also applies to modern callers.

The handler starts again from the beginning, including the server's
C<on_request> hook. Earlier one-time grants survive these retries but do not
authorize another tool invocation. Current rules are rechecked, so a new
denial can supersede an earlier approval.

Complete all checks before side effects or asynchronous work. Do not catch
the permission-needed exception as an ordinary tool failure; it must reach
the server's synchronous dispatch boundary. A deferred callback cannot use
that boundary to restart the handler.

=head2 Replies and failures

=over

=item $req->reply ($result)

Sends the MCP result hash reference as supplied. Use this for arbitrary
content, structured errors or large results. The server adds the JSON-RPC
envelope.

=item $req->result ($data)

Sends the hash reference C<$data> as C<structuredContent> and also as JSON in
one text content item. This duplicates the data for clients that consume
only text; use C<reply> when that representation is unsuitable.

=item $req->error ($message)

Sends a tool result with C<isError> set and C<$message> as one text item.

=back

A synchronous handler exception becomes a tool error. Tool failures do not
become JSON-RPC errors; malformed protocol requests and unknown tools are
handled by Server.

Reply exactly once. Replying after completion is a bug and dies. A reply
finishes the request, but returning from the callback does not.

=head2 Asynchronous work and cancellation

The callback may keep C<$req> and return without replying. Reply when the
operation completes. The callback runs in the event loop; use asynchronous
operations rather than blocking it.

Set C<< $req->{on_cancel} >> to stop an outstanding operation. Cancellation
sets C<< $req->{cancelled} >> and C<< $req->{finished} >> and sends no reply.
A late completion callback must check C<< $req->{finished} >> before replying.

Server catches exceptions during synchronous dispatch, not exceptions in
later application callbacks. Such callbacks must handle their own failures.

C<< $req->progress ($progress, $total, $message) >> reports progress when
the client supplied a progress token. Delivery is best effort and may be
dropped by the transport; it does not complete the request.

=head1 METHODS

=over

=item $toolset = AnyEvent::MCP::Server::Toolset->new

Creates an empty tool registry.

=item $toolset->tool ($name, $description, $input_schema, $callback->($req, $args))

Registers a tool named C<$name>. Underscores are converted to hyphens and
duplicate names are rejected.

C<$description> is stripped of surrounding whitespace and common indentation.
C<$input_schema> is a JSON Schema hash reference describing the arguments.

C<$callback> receives an L<AnyEvent::MCP::Server::Request> object C<$req>
and its C<< $req->{args} >> hash reference as C<$args>, for convenience:

   sub {
      my ($req, $args) = @_;

      $req->reply ({
         content => [{ type => "text", text => $args->{text} }],
      });
   }

Registered tools are callbacks, not methods of the Toolset.

=item $definitions = $toolset->list

Returns the array reference of MCP tool definitions in registration order.
C<$definitions> contains no callbacks.

=item $toolset->call ($req)

Invokes the tool named by C<< $req->{tool} >> with C<$req> and
C<< $req->{args} >>. Sets C<< $req->{toolset} >> to this Toolset.

Unknown names and exceptions from the callback are left for the server to
handle.

=back

=cut

package AnyEvent::MCP::Server::Toolset;

use common::sense;
use AnyEvent::MCP ();

our @ISA = qw(AnyEvent::MCP::Base);

sub new {
   my $class = shift;

   $class->SUPER::new (tool => {}, list => [], @_)
}

sub tool {
   my ($self, $name, $description, $input_schema, $callback) = @_;

   $name =~ y/_/-/;

   !exists $self->{tool}{$name}
      or die "duplicate MCP tool '$name'\n";

   my $definition = {
      name        => $name,
      description => AnyEvent::MCP::_clean_text $description,
      inputSchema => $input_schema,
   };

   $self->{tool}{$name} = {
      definition => $definition,
      callback   => $callback,
   };

   push @{$self->{list}}, $definition;
}

sub list {
   $_[0]{list}
}

sub call {
   my ($self, $req) = @_;

   my $name = $req->{tool};

   my $tool = $self->{tool}{$name}
      or die "unknown MCP tool '$name'\n";

   $req->{toolset} = $self;
   $tool->{callback}->($req, $req->{args})
}

1
