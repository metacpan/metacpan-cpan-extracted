=head1 NAME

AnyEvent::MCP::Server - MCP request dispatch and JSON-RPC framing

=head1 DESCRIPTION

An MCP server needs to understand requests, but it does not necessarily need
to own a listening socket. This class handles the protocol: it accepts decoded
JSON-RPC objects (or UTF-8 JSON), dispatches requests and delivers responses
through callbacks. Its subclasses L<AnyEvent::MCP::Server::JSONL> and
L<AnyEvent::MCP::Server::HTTP> handle the actual connections. If you are
writing a standalone server, L<AnyEvent::MCP::Server::Simple> is usually
the easier starting point.

The server implements discovery, initialization, ping and tool listing/calls.
The 2025 compatibility path supports ordinary requests and responses, but
not server-initiated requests. Permission asking supports modern input
challenges as well as local helpers. SSE, subscriptions and schema validation
are not implemented yet.

The usual object-level assembly is a
L<AnyEvent::MCP::Server::Toolset> holding tool callbacks, a Server
handling protocol messages, and a transport accepting connections.
Use L<AnyEvent::MCP::Server::HTTP/FIRST USE> for an executable HTTP
assembly or L<AnyEvent::MCP::Server::JSONL/EXAMPLE> for stdio.
The corresponding client entry point is L<AnyEvent::MCP::Client>.

Only embedders that already own their transport need C<rpc> or
C<json_rpc> directly; these methods do not create connections or run
the event loop.

=head1 METHODS

=over

=item $server = AnyEvent::MCP::Server->new (%config)

Creates the protocol object without opening a listener or starting an
event loop. Options are:

=over

=item toolsets => [$toolset...]

L<AnyEvent::MCP::Server::Toolset> objects searched in order, defaulting to
an empty array. The first Toolset containing a called tool handles it.

=item server_info => { name => $name, version => $version }

Advertised server identity, defaulting to C<AnyEvent::MCP> and this
distribution's version.

=item instructions => $text

Optional human-readable guidance. Surrounding whitespace and common
indentation are stripped. Empty instructions are omitted from discovery
and initialization results.

=item short_instructions => $text

Optional condensed guidance for deciding when to discover this server's tools.
Used instead of C<instructions> in discovery when C<auto_instructions> is true.
Without either short or custom instructions, the full instructions remain
advertised.

=item custom_instructions => $text

Instance-specific purpose, prepended to the advertised instructions.

=item auto_instructions => $boolean

When true, expose full C<instructions>, prefixed by any custom instance
purpose, in a C<meta-instructions> tool's description and call result.
Advertise C<short_instructions> instead, when provided, preceded by any
custom purpose. Append a pointer to the generated tool's description when
short or custom instructions exist. With neither, advertise the original
full instructions without a redundant pointer. Defaults to false;
a conflicting tool name is an error.

=item capabilities => { %capabilities }

Advertised server capabilities, defaulting to C<{ tools =E<gt> {} }>.
Declaring a capability does not implement it.

=item versions => [$version...]

Supported revisions in preference order. Defaults to C<2026-07-28>,
C<2025-11-25>, C<2025-06-18> and C<2025-03-26>. The 2026 protocol uses
discovery and per-request metadata; the 2025 protocol uses initialization.

=item permissions => $permissions

L<AnyEvent::MCP::Server::Permissions> object used by
C<< $req->require_permission >>. The server handles permission-needed
exceptions. The permission object's C<ask> setting chooses between modern
input challenges and local prompts; local asking retries the handler
internally. Checks must precede side effects.

=back

Event callbacks are also constructor options; see L</EVENTS>.

=item $req = $server->rpc ($message, $reply->($message), %context)

Accepts the decoded JSON-RPC hash reference C<$message>. C<$reply> receives
the decoded response, or undef when a notification is accepted or a request
is cancelled. Undef completes transport bookkeeping without a JSON-RPC
response. Returns the Request object for a request, or undef for
notifications and rejected messages.
C<$reply> can be called before this method returns, or later.

C<peer> in C<%context> is a hash reference shared by messages on one connection.
It holds legacy initialization state and weak references to outstanding
requests for cancellation. Embedders supply a different peer for each
independent connection. Modern request metadata takes precedence over legacy
peer state.

C<protocol_version> supplies the legacy HTTP protocol version.
C<on_notify> is an optional C<$callback->($req, $message)> receiving decoded
outgoing notifications. Without it, notifications are dropped.

=item $req = $server->json_rpc ($json, $reply->($json), %context)

Like C<rpc>, but C<$json> and the response are UTF-8 encoded JSON strings.
The notification callback still receives decoded objects. Parse errors are
returned as JSON-RPC errors.

=item $server->dispatch ($req)

Dispatches an already constructed Request. Normally called by C<rpc>.
Subclasses can override this method while retaining JSON-RPC handling.

=back

=head1 EVENTS

=over

=item on_request => $callback->($server, $req)

Called before each dispatch attempt, including permission retries. This
synchronous hook can inspect the request or refresh application state.
It does not replace dispatch; avoid side effects that must happen only once.

=item on_tools_list => $callback->($server, $req)

Replaces the default Toolset listing. C<$callback> completes C<$req>.

=item on_tools_call => $callback->($server, $req, $args)

Replaces the default Toolset lookup and invocation. C<$args> is also available
as C<< $req->{args} >>. C<$callback> completes C<$req>.

=item on_error => $callback->($server, $req, $error)

Reports an exception caught during synchronous dispatch. A tool exception
becomes a text tool-error result; other exceptions become internal JSON-RPC
errors. Exceptions after a reply are propagated, as are exceptions from
asynchronous application callbacks.

=back

=cut

package AnyEvent::MCP::Server;

use common::sense;
use AnyEvent::MCP ();
use AnyEvent::MCP::Server::Request ();
use JSON::XS ();
use Scalar::Util qw(weaken);

our @ISA = qw(AnyEvent::MCP::Base);

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      toolsets     => [],
      server_info  => { name => "AnyEvent::MCP", version => $AnyEvent::MCP::VERSION },
      capabilities => { tools => {} },
      versions     => [qw(2026-07-28 2025-11-25 2025-06-18 2025-03-26)],
      @_,
   );

   $self->{instructions} = AnyEvent::MCP::_clean_text $self->{instructions}
      if exists $self->{instructions};

   my $instructions = $self->{instructions};
   my $custom = exists $self->{custom_instructions}
      ? AnyEvent::MCP::_clean_text $self->{custom_instructions} : "";

   if ($self->{auto_instructions} && length $instructions) {
      require AnyEvent::MCP::Server::Toolset;

      my $name = "meta-instructions";
      !grep (exists $_->{tool}{$name}, @{$self->{toolsets}})
         or die "duplicate MCP tool '$name'\n";

      my $full = join "\n\n", grep length, $custom, $instructions;
      my $toolset = AnyEvent::MCP::Server::Toolset->new;
      $toolset->tool (meta_instructions =>
         "Server instructions. Call for full text if truncated.\n\n$full",
         { type => "object", properties => {} },
         sub { $_[0]->reply ({ content => [{ type => "text", text => $full }] }) },
      );
      $self->{toolsets} = [@{$self->{toolsets}}, $toolset];

      my $short = exists $self->{short_instructions}
         ? AnyEvent::MCP::_clean_text $self->{short_instructions} : "";
      $self->{instructions} = length $custom || length $short
         ? join ("\n\n", grep length, $custom, $short, "Full instructions: meta-instructions tool description.")
         : $instructions;

   } elsif (length $custom) {
      $self->{instructions} = join "\n\n", grep length, $custom, $instructions;
   }

   $self
}

sub _rpc_error {
   my ($self, $reply, $id, $code, $message, $data) = @_;

   my $error = { code => $code, message => $message };
   $error->{data} = $data if defined $data;

   $reply->({ jsonrpc => "2.0", id => $id, error => $error });
   undef
}

sub json_rpc {
   my ($self, $json, $reply, @context) = @_;

   my $send = sub { $reply->(defined $_[0] ? JSON::XS::encode_json $_[0] : undef) };
   my $message = eval { JSON::XS::decode_json $json };

   return $self->_rpc_error ($send, undef, -32700, "Parse error")
      if $@;

   $self->rpc ($message, $send, @context)
}

sub rpc {
   my ($self, $message, $reply, %context) = @_;

   return $self->_rpc_error ($reply, undef, -32600, "Invalid request")
      unless ref $message eq "HASH"
         && $message->{jsonrpc} eq "2.0"
         && defined $message->{method} && !ref $message->{method}
         && (!exists $message->{id} || defined $message->{id} && !ref $message->{id});

   my $id     = $message->{id};
   my $key    = $id; # Hash lookups must not stringify the wire ID.
   my $method = $message->{method};
   my $params = exists $message->{params} ? $message->{params} : {};
   my $peer   = $context{peer} || {};

   unless (exists $message->{id}) {
      if ($method eq "notifications/cancelled" && ref $params eq "HASH" && defined $params->{requestId}) {
         my $req = delete $peer->{requests}{$params->{requestId}};
         $req->cancel ($params->{reason}) if $req;
      }

      $reply->(undef);
      return
   }

   return $self->_rpc_error ($reply, $id, -32602, "Invalid params")
      unless ref $params eq "HASH"
         && (!exists $params->{_meta} || ref $params->{_meta} eq "HASH");

   my $meta = $params->{_meta} || {};
   my $version = $meta->{"io.modelcontextprotocol/protocolVersion"}
      || $context{protocol_version} || $peer->{protocol_version};

   if ($method eq "initialize") {
      $version = $params->{protocolVersion};

      return $self->_rpc_error ($reply, $id, -32602, "Invalid initialize params")
         unless defined $version && !ref $version
            && ref $params->{capabilities} eq "HASH"
            && ref $params->{clientInfo} eq "HASH";

      unless (grep $_ eq $version && $_ lt "2026", @{$self->{versions}}) {
         ($version) = grep $_ lt "2026", @{$self->{versions}};
         return $self->_rpc_error ($reply, $id, -32601, "Legacy initialization is not supported")
            unless defined $version;
      }
   } else {
      return $self->_rpc_error ($reply, $id, -32602, "Missing protocol version")
         unless defined $version && !ref $version;

      return $self->_rpc_error ($reply, $id, -32022, "Unsupported protocol version", {
         requested => $version,
         supported => $self->{versions},
      }) unless grep $_ eq $version, @{$self->{versions}};

      if ($version ge "2026") {
         return $self->_rpc_error ($reply, $id, -32602, "Missing per-request metadata")
            unless $meta->{"io.modelcontextprotocol/protocolVersion"} eq $version
               && ref $meta->{"io.modelcontextprotocol/clientCapabilities"} eq "HASH";
      }
   }

   return $self->_rpc_error ($reply, $id, -32600, "Request id already outstanding")
      if $peer->{requests}{$key};

   # the private multibroker protocol uses the normal MCP capability handshake.
   # keep the negotiated version on this stream's peer, not on the server.
   my $capabilities = $method eq "initialize"
      ? $params->{capabilities} : $meta->{"io.modelcontextprotocol/clientCapabilities"};
   if (ref $capabilities eq "HASH") {
      my $extensions = $capabilities->{extensions};
      if (ref $extensions eq "HASH") {
         my $extension = $extensions->{"anyevent-mcp/multibroker"};
         $peer->{aemcp_multibroker} = 1
            if ref $extension eq "HASH" && ($extension->{version} || 0) eq "1";
      }
   }

   my $req = AnyEvent::MCP::Server::Request->new (
      server           => $self,
      peer             => $peer,
      id               => $id,
      method           => $method,
      params           => $params,
      protocol_version => $version,
      on_reply         => sub {
         my ($req, $result) = @_;

         delete $peer->{requests}{$key};

         if ($req->{protocol_version} ge "2026") {
            $result = {
               resultType => "complete",
               %$result,
               _meta => {
                  "io.modelcontextprotocol/serverInfo" => $self->{server_info},
                  %{$result->{_meta} || {}},
               },
            };
         }

         $reply->({ jsonrpc => "2.0", id => $id, result => $result });
      },
   );

   if (my $notify = $context{on_notify}) {
      $req->{on_notify} = sub {
         my ($req, $method, $params) = @_;

         $notify->($req, { jsonrpc => "2.0", method => $method, params => $params });
      };
   }

   $peer->{requests}{$key} = $req;
   weaken $peer->{requests}{$key};

   if ($method eq "tools/call") {
      unless (defined $params->{name} && !ref $params->{name}
         && (!exists $params->{arguments} || ref $params->{arguments} eq "HASH")) {
         $self->_reject ($req, $reply, -32602, "Invalid tool call");
         return $req
      }

      $req->{tool} = $params->{name};
      $req->{args} = exists $params->{arguments} ? $params->{arguments} : {};
   }

   $req->{_reply} = $reply;

   $self->_dispatch ($req);

   $req
}

sub _dispatch {
   my ($self, $req) = @_;

   eval {
      $self->{permissions}->_resume ($req)
         if $self->{permissions} && $req->{method} eq "tools/call";
      $self->event (request => $req);
      $self->dispatch ($req) unless $req->{finished};
      1
   } or do {
      my $error = $@;
      die $error if $req->{finished};

      if (ref $error eq "AnyEvent::MCP::Server::Permissions::Required" && $self->{permissions}) {
         eval {
            $self->{permissions}->require ($req, $error->{request}, sub {
               my ($success, $grant) = @_;

               return if $req->{finished};
               return $req->error ($grant) unless $success;

               $self->{permissions}->_remember ($req, $error->{request}, $grant);
               $self->_dispatch ($req);
            });
            1
         } or do {
            my $failure = $@;
            die $failure if $req->{finished};
            $self->event (error => $req, $failure);
            $req->error ($failure);
         };
      } else {
         $self->event (error => $req, $error);

         if ($req->{method} eq "tools/call") {
            $req->error ($error);
         } else {
            $self->_reject ($req, $req->{_reply}, -32603, "Internal error");
         }
      }
   };
}

sub _reject {
   my ($self, $req, $reply, $code, $message) = @_;

   $req->{finished} = 1;
   my $key = $req->{id};
   delete $req->{peer}{requests}{$key};
   delete @$req{qw(on_reply on_notify on_cancel _reply)};

   $self->_rpc_error ($reply, $req->{id}, $code, $message)
}

sub dispatch {
   my ($self, $req) = @_;

   my $method = $req->{method};

   if ($method eq "initialize") {
      $req->{peer}{protocol_version} = $req->{protocol_version};
      $req->{peer}{client_info} = $req->{params}{clientInfo};
      $req->{peer}{client_capabilities} = $req->{params}{capabilities};

      my $result = {
         protocolVersion => $req->{protocol_version},
         serverInfo      => $self->{server_info},
         capabilities    => $self->{capabilities},
      };
      $result->{instructions} = $self->{instructions} if length $self->{instructions};

      $req->reply ($result);

   } elsif ($method eq "server/discover") {
      my $result = {
         supportedVersions => $self->{versions},
         capabilities      => $self->{capabilities},
      };
      $result->{instructions} = $self->{instructions} if length $self->{instructions};

      $req->reply ($result);

   } elsif ($method eq "ping") {
      $req->reply ({});

   } elsif ($method eq "tools/list") {
      if ($self->{on_tools_list}) {
         $self->event (tools_list => $req);
      } else {
         $req->reply ({ tools => [map @{$_->list}, @{$self->{toolsets}}] });
      }

   } elsif ($method eq "tools/call") {
      if ($self->{on_tools_call}) {
         $self->event (tools_call => $req, $req->{args});
      } else {
         my ($toolset) = grep exists $_->{tool}{$req->{tool}}, @{$self->{toolsets}};

         if ($toolset) {
            $toolset->call ($req);
         } else {
            $self->_reject ($req, $req->{_reply}, -32602, "Unknown tool '$req->{tool}'");
         }
      }

   } else {
      $self->_reject ($req, $req->{_reply}, -32601, "Method not found");
   }
}

1
