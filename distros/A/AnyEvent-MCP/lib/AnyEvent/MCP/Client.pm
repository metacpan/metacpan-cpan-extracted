=head1 NAME

AnyEvent::MCP::Client - asynchronous MCP client protocol

=head1 SYNOPSIS

   use AnyEvent::MCP::Client::HTTP;

   my $client = AnyEvent::MCP::Client::HTTP->new (
      url => $url, bearer => $token,
   );

   $client->call (echo => { text => "hello" }, sub {
      my ($success, $result) = @_;
      ...
   });

=head1 DESCRIPTION

This is the common protocol implementation used by
L<AnyEvent::MCP::Client::HTTP> and L<AnyEvent::MCP::Client::JSONL>. Choose a
transport, keep the client object alive, and run an AnyEvent event loop.
You can call a tool without connecting explicitly: the client connects and
discovers or initializes the server as needed. Concurrent requests share that
work instead of starting independent connections.

An interrupted connection does not mean the server did nothing. A tool might
have completed its side effects just before the connection failed. For that
reason, the client never replays a tool call automatically. Applications that
want retries must decide whether the operation is safe to repeat.

Modern clients use discovery and per-request metadata. Legacy clients use
initialization and ordinary request/response. Legacy server-initiated requests
are accepted on JSONL; legacy HTTP GET streams are not implemented.

For a runnable call, see L<AnyEvent::MCP::Client::HTTP/FIRST CALL> when
connecting to an HTTP endpoint or
L<AnyEvent::MCP::Client::JSONL/FIRST CALL> when launching a subprocess.
Both use C<call> from this module. In its callback, C<$success> reports
JSON-RPC/transport success; a tool can still return C<isError> true.
Keep the client alive while its callbacks are pending.

=head1 METHODS

=over

=item $client = AnyEvent::MCP::Client->new (%config)

Normally construct a transport subclass. Its constructor accepts these
common options as well as the transport-specific options:

=over

=item client_info => { name => $name, version => $version }

Advertised client identity. Defaults to C<AnyEvent::MCP> and this
distribution's version.

=item client_capabilities => { %capabilities }

Supported client interactions, defaulting to an empty hash. Advertising a
capability does not install a handler; supply C<on_request> when needed.

=item versions => [$version...]

Supported protocol revisions in preference order. Defaults to
C<2026-07-28>, C<2025-11-25>, C<2025-06-18> and C<2025-03-26>.
Here, modern means the 2026 discovery/input-challenge protocol; legacy
means the 2025 initialization protocol.

=item request_timeout => $seconds

Optional overall deadline for C<rpc> and C<call>, including connection
and user input. Omitted or zero means no overall deadline. This is separate
from HTTP's inactivity timeout.

=item max_rounds => $count

Maximum input-challenge rounds handled by C<call>, defaulting to 32.

=item name => $name

Optional local configuration name, independent of C<client_info>.
HTTP loads C<[client NAME]> defaults only when this is supplied;
JSONL does not load transport defaults.

=back

Event callbacks are also constructor options; see L</EVENTS>.

=item $client->connect ($done->($success, $result))

Discovers or initializes the server. On success C<$result> is undef.
Any JSON-RPC error from discovery falls back to legacy initialization.
Transport failures do not trigger fallback.
After connecting, C<protocol_version>, C<server_info>, C<server_capabilities>
and C<instructions> are available directly in the client hash.

=item $id = $client->rpc ($method, $params, $done->($success, $result))

Sends a request. C<$params> is a hash reference and is not modified.
C<$id> identifies the local operation for cancellation. Callbacks may run
before this method returns.

On success C<$result> is the entire decoded result, including C<isError>,
C<_meta> and C<resultType>. A result with C<resultType> set to
C<input_required> is returned unchanged. C<$success> reports whether the
JSON-RPC request succeeded, not whether the tool succeeded: a tool result
with C<isError> true still has C<$success> true.
On failure C<$result> is an error hash: JSON-RPC errors retain their fields,
while local errors have C<message> and C<transport> true. Local cancellation
also has C<cancelled> true. Each completion callback runs once.

=item $id = $client->call ($name, $args, $done->($success, $result), %params)

Calls a tool and handles modern C<input_required> results via C<on_request>.
C<$args> is a hash reference of tool arguments. C<%params> supplies
additional protocol parameters, such as C<_meta>. Set
C<< $params{_meta}{"io.modelcontextprotocol/clientCapabilities"} >>
to override the constructor capabilities for this call, allowing
brokers to advertise the upstream capabilities without changing shared state.
The original method and arguments are retained; only server-requested answers
and opaque C<requestState> are added for continuation. No connection failure
causes a retry. Without C<on_request>, an interaction fails locally.

Permission challenges are input requests handled by C<on_request>. To ask
locally through the external permission helper:

   client_capabilities => { elicitation => { form => {} } },
   on_request => sub {
      AnyEvent::MCP::Permissions::Ask->elicitation ($_[1]);
   },

Load L<AnyEvent::MCP::Permissions::Ask> before using that callback. It handles
permission-tagged elicitation only; applications supporting other elicitation
requests dispatch those separately. The client does not silently approve
permissions. C<rpc> returns input challenges intact for broker forwarding.

=item $client->tools ($done->($success, $tools))

Collects all pages of tool definitions into an array reference. Names and
definitions are preserved. Repeated pagination cursors are rejected.

=item $client->notify ($method, $params, $done->($success, $result))

Sends a notification after connecting. C<$done> is optional. Success means
the transport accepted it, not that the server acted on it.

=item $client->cancel ($id, $reason)

Cancels a pending local operation, completes its callback with an error and
sends best-effort protocol cancellation for an outstanding wire request.
C<$reason> is optional. Late responses are ignored.

=item $client->close

Closes transport resources, cancels input handlers and fails pending callbacks.
New operations can reconnect. Previously sent calls are not repeated.

=back

=head1 EVENTS

=over

=item on_request => $callback->($client, $req)

Handles an input request asynchronously. C<$req> is a
L<AnyEvent::MCP::Client::Request> with C<method> and C<params>.
Declare the corresponding capabilities explicitly in C<client_capabilities>.
For a broker, C<rpc> can instead return the complete input challenge upstream.

=item on_notification => $callback->($client, $method, $params)

Receives server notifications, including progress and tool-list changes.

=item on_ready => $callback->($client)

Called once after a successful MCP discovery or initialization, including
reconnections. It does not fire for repeated C<connect> calls on an already
connected client.

=item on_close => $callback->($client, $error)

Called when an established connection closes unexpectedly, with a transport
error hash. C<pending> counts operations interrupted by the close, before
their callbacks were failed. An explicit C<close> without a reason does not
trigger this event.

=back

=cut

package AnyEvent::MCP::Client;

use common::sense;
use AnyEvent::MCP ();
use AnyEvent ();
use AnyEvent::MCP::Client::Request ();
use Scalar::Util qw(weaken);

our @ISA = qw(AnyEvent::MCP::Base);

sub new {
   my $class = shift;

   $class->SUPER::new (
      client_info         => { name => "AnyEvent::MCP", version => "$AnyEvent::MCP::VERSION" },
      client_capabilities => {},
      versions            => [qw(2026-07-28 2025-11-25 2025-06-18 2025-03-26)],
      @_,
   )
}

sub connect {
   my ($self, $done) = @_;

   return $done->(1, undef) if $self->{connected};
   if ($self->{connecting}) {
      push @{$self->{connecting}}, $done;
      return
   }

   $self->{connecting} = [$done];
   weaken $self;
   $self->_open (sub {
      my ($success, $error) = @_;

      return unless $self;
      return $self->_connected (0, $error) unless $success;

      my ($modern) = grep $_ ge "2026", @{$self->{versions}};
      return $self->_initialize unless $modern;

      $self->{protocol_version} = $modern;
      $self->_request ("server/discover", {}, sub {
         my ($success, $result) = @_;

         return unless $self;

         return $self->_initialize if !$success && !$result->{transport};
         return $self->_connected (0, $result) unless $success;

         return $self->_connected (0, { transport => 1, message => "Invalid discovery result" })
            unless ref $result->{supportedVersions} eq "ARRAY" && ref $result->{capabilities} eq "HASH";

         my %supported = map { $_ => 1 } @{$result->{supportedVersions}};
         my ($version) = grep $supported{$_}, @{$self->{versions}};
         return $self->_connected (0, { transport => 1, message => "No supported protocol version" })
            unless defined $version;
         return $self->_initialize if $version lt "2026";

         $self->{protocol_version} = $version;
         $self->{server_info} = $result->{_meta}{"io.modelcontextprotocol/serverInfo"};
         $self->{server_capabilities} = $result->{capabilities};
         $self->{instructions} = $result->{instructions};
         $self->_connected (1, undef);
      });
   });
}

sub _initialize {
   my ($self) = @_;

   my ($version) = grep $_ lt "2026", @{$self->{versions}};
   return $self->_connected (0, { transport => 1, message => "Server requires unsupported legacy initialization" })
      unless defined $version;

   $self->{protocol_version} = $version;
   weaken $self;
   $self->_request ("initialize", {
      protocolVersion => $version,
      clientInfo      => $self->{client_info},
      capabilities    => $self->{client_capabilities},
   }, sub {
      my ($success, $result) = @_;

      return unless $self;
      return $self->_connected (0, $result) unless $success;

      my $version = $result->{protocolVersion};
      return $self->_connected (0, { transport => 1, message => "Unsupported negotiated protocol version" })
         unless grep $_ eq $version && $_ lt "2026", @{$self->{versions}};

      $self->{protocol_version} = $version;
      $self->{server_info} = $result->{serverInfo};
      $self->{server_capabilities} = $result->{capabilities};
      $self->{instructions} = $result->{instructions};
      $self->_send ({ jsonrpc => "2.0", method => "notifications/initialized" },
         sub { $self->_connected (@_) if $self });
   });
}

sub _connected {
   my ($self, $success, $error) = @_;

   my $waiters = delete $self->{connecting} or return;
   if ($success) {
      $self->{connected} = 1;
      $self->event ("ready");
   } else {
      $self->_shutdown;
      delete @$self{qw(connected protocol_version server_info server_capabilities instructions)};
   }
   $_->($success, $error) for @$waiters;
}

sub _request {
   my ($self, $method, $params, $done, $operation) = @_;

   my $id = ++$self->{wire_id};
   my %params = %$params;

   if ($self->{protocol_version} ge "2026") {
      $params{_meta} = {
         %{$params{_meta} || {}},
         "io.modelcontextprotocol/protocolVersion"    => $self->{protocol_version},
         "io.modelcontextprotocol/clientInfo"         => $self->{client_info},
         "io.modelcontextprotocol/clientCapabilities" => exists $params{_meta}{"io.modelcontextprotocol/clientCapabilities"}
            ? $params{_meta}{"io.modelcontextprotocol/clientCapabilities"} : $self->{client_capabilities},
      };
   }

   $self->{pending}{$id} = $done;
   $operation->{wire_id} = $id if $operation;
   my $generation = $self->{generation};
   weaken $self;
   $self->_send ({ jsonrpc => "2.0", id => $id, method => $method, params => \%params }, sub {
      my ($success, $error) = @_;

      return if !$self || $self->{generation} != $generation || $success;
      my $done = delete $self->{pending}{$id} or return;
      $done->(0, $error);
   });
   $id
}

sub _operation {
   my ($self, $method, $params, $done, $interactions) = @_;

   my $id = ++$self->{operation_id};
   my $op = $self->{operations}{$id} = {
      method       => $method,
      params       => $params,
      done         => $done,
      interactions => $interactions,
   };

   weaken $self;
   if ($self->{request_timeout}) {
      $op->{timer} = AnyEvent->timer (after => $self->{request_timeout}, cb => sub {
         $self->cancel ($id, "Request timed out") if $self;
      });
   }

   $self->connect (sub {
      my ($success, $error) = @_;

      return unless $self && $self->{operations}{$id};
      return $self->_finish ($id, 0, $error) unless $success;
      $self->_continue ($id, $params);
   });
   $id
}

sub rpc {
   my ($self, $method, $params, $done) = @_;

   $self->_operation ($method, $params, $done, 0)
}

sub call {
   my ($self, $name, $args, $done, %params) = @_;

   $self->_operation ("tools/call", { %params, name => $name, arguments => $args }, $done, 1)
}

sub _continue {
   my ($self, $id, $params) = @_;

   my $op = $self->{operations}{$id} or return;

   weaken $self;
   $self->_request ($op->{method}, $params, sub {
      my ($success, $result) = @_;

      return unless $self && $self->{operations}{$id};
      delete $op->{wire_id};

      if ($success && $op->{interactions} && $result->{resultType} eq "input_required") {
         return $self->_input ($id, $result)
      }
      $self->_finish ($id, $success, $result);
   }, $op);
}

sub _input {
   my ($self, $id, $result) = @_;

   my $op = $self->{operations}{$id} or return;
   my $input = $result->{inputRequests};

   return $self->_finish ($id, 0, { transport => 1, message => "Input required without a client handler" })
      unless $self->{on_request} && ref $input eq "HASH" && keys %$input;
   return $self->_finish ($id, 0, { transport => 1, message => "Too many input rounds" })
      if ++$op->{rounds} > ($self->{max_rounds} || 32);

   weaken $self;
   my %responses;
   my $remaining = keys %$input;
   $op->{input} = [];
   for my $key (sort keys %$input) {
      last unless $self->{operations}{$id};
      my $request = $input->{$key};
      unless (ref $request eq "HASH"
              && defined $request->{method}
              && ref ($request->{params} || {}) eq "HASH") {
         return $self->_finish ($id, 0, { transport => 1, message => "Invalid input request" })
      }

      my $req = AnyEvent::MCP::Client::Request->new (
         client           => $self,
         id               => $key,
         method           => $request->{method},
         params           => $request->{params} || {},
         protocol_version => $self->{protocol_version},
         operation        => $id,
         on_reply         => sub {
            my ($success, $response) = @_;

            return unless $self->{operations}{$id};
            return $self->_finish ($id, 0, $response) unless $success;
            $responses{$key} = $response;
            return if --$remaining;

            delete $op->{input};
            my %params = (%{$op->{params}}, inputResponses => \%responses);
            $params{requestState} = $result->{requestState} if exists $result->{requestState};
            $self->_continue ($id, \%params);
         },
      );
      push @{$op->{input}}, $req;
      $self->event (request => $req);
   }
}

sub _finish {
   my ($self, $id, $success, $result) = @_;

   my $op = delete $self->{operations}{$id} or return;
   delete $self->{pending}{$op->{wire_id}} if exists $op->{wire_id};
   $_->cancel for @{$op->{input} || []};
   delete $op->{timer};
   $op->{done}->($success, $result);
}

sub cancel {
   my ($self, $id, $reason) = @_;

   my $op = $self->{operations}{$id} or return;
   my $wire = $op->{wire_id};
   $reason = "Request cancelled" unless defined $reason;

   $self->_finish ($id, 0, { transport => 1, cancelled => 1, message => $reason });
   if (defined $wire && $self->{connected}) {
      $self->_send ({
         jsonrpc => "2.0", method => "notifications/cancelled",
         params  => { requestId => $wire, reason => $reason },
      }, sub {});
      $self->_abort ($wire);
   }
}

sub tools {
   my ($self, $done) = @_;

   my (@tools, %seen);
   weaken $self;
   my $page;
   $page = sub {
      my ($cursor) = @_;

      $self->rpc ("tools/list", defined $cursor ? { cursor => $cursor } : {}, sub {
         my ($success, $result) = @_;

         unless ($success && ref $result->{tools} eq "ARRAY") {
            undef $page;
            return $done->(0, $success ? { transport => 1, message => "Invalid tools/list result" } : $result)
         }

         push @tools, @{$result->{tools}};
         if (defined $result->{nextCursor} && length $result->{nextCursor}) {
            if ($seen{$result->{nextCursor}}++) {
               undef $page;
               return $done->(0, { transport => 1, message => "Repeated tools/list cursor" })
            }
            return $page->($result->{nextCursor})
         }

         undef $page;
         $done->(1, \@tools);
      });
   };
   $page->();
}

sub notify {
   my ($self, $method, $params, $done) = @_;

   $done ||= sub {};
   weaken $self;

   $self->connect (sub {
      my ($success, $error) = @_;

      return unless $self;
      return $done->(0, $error) unless $success;
      $self->_send ({ jsonrpc => "2.0", method => $method, params => $params }, $done);
   });
}

sub _receive {
   my ($self, $message) = @_;

   die "Invalid JSON-RPC message\n"
      unless ref $message eq "HASH" && $message->{jsonrpc} eq "2.0";

   if (exists $message->{method}) {
      die "Invalid server method\n" if ref $message->{method};
      if (!exists $message->{id}) {
         $self->event (notification => $message->{method}, $message->{params} || {});
         return
      }

      die "Server-initiated request on modern connection\n" if $self->{protocol_version} ge "2026";
      weaken $self;
      my $req = AnyEvent::MCP::Client::Request->new (
         client   => $self,
         id       => $message->{id},
         method   => $message->{method},
         params   => $message->{params} || {},
         on_reply => sub {
            my ($success, $result) = @_;

            return unless $self;
            delete $self->{incoming}{$message->{id}};
            $self->_send ({
               jsonrpc => "2.0", id => $message->{id},
               ($success ? "result" : "error") => $result,
            }, sub {});
         },
      );
      $self->{incoming}{$req->{id}} = $req;
      if ($req->{method} eq "ping") {
         $req->reply ({});
      } elsif ($self->{on_request}) {
         $self->event (request => $req);
      } else {
         $req->error (-32601, "Method not supported");
      }
      return
   }

   my $field = exists $message->{result} ? "result" : "error";

   defined $message->{id} && !ref $message->{id}
      && (exists $message->{result}) != (exists $message->{error})
      && ref $message->{$field} eq "HASH"
      or die "Invalid JSON-RPC response\n";

   my $done = delete $self->{pending}{$message->{id}} or return;
   $done->(exists $message->{result}, $message->{$field});
}

sub _open {
   $_[1]->(1, undef)
}

sub _abort {
}

sub close {
   my ($self, $message) = @_;

   my $was_connected = $self->{connected};
   # The close event runs after outstanding operations have been failed.
   my $outstanding = scalar keys %{$self->{operations} || {}};
   ++$self->{generation};
   $self->_shutdown;
   delete @$self{qw(connected protocol_version server_info server_capabilities instructions)};

   my $error = { transport => 1, pending => $outstanding,
      message => defined $message ? $message : "Client closed" };
   my $connecting = delete $self->{connecting} || [];
   my $pending = delete $self->{pending} || {};
   my $incoming = delete $self->{incoming} || {};
   $_->cancel for values %$incoming;
   $self->_finish ($_, 0, $error) for keys %{$self->{operations} || {}};
   $_->(0, $error) for values %$pending;
   $_->(0, $error) for @$connecting;
   $self->event (close => $error) if $was_connected && defined $message;
}

sub DESTROY {
   $_[0]->close
}

1
