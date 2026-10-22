=head1 NAME

AnyEvent::MCP::Server::HTTP - an optional MCP HTTP listener and socket handler

=head1 DESCRIPTION

A subclass of L<AnyEvent::MCP::Server> that handles HTTP POST requests.
It can open its own listener, or you can give it sockets accepted elsewhere.
If your application already parses HTTP, you can pass decoded requests to
L<AnyEvent::MCP::Server> instead of running another HTTP implementation.

Requests sharing one connection are dispatched in sequence, preserving their
HTTP response order; requests on other connections are independent. This
implementation returns JSON and drops notifications. It does not support
SSE or subscriptions.

Request bodies need C<Content-Length>: chunked transfer encoding is not
supported. The server does not assign protocol sessions. Legacy clients
use the 2025 request/response subset.

C<Mcp-Param-*> headers from C<x-mcp-header> tool schema annotations are not
currently validated against the body. The built-in protocol headers
C<Mcp-Protocol-Version>, C<Mcp-Method> and, where applicable, C<Mcp-Name>
must agree with modern request metadata and parameters; a mismatch is
rejected. Custom schema-derived headers do not receive this check.

=head1 FIRST USE

For an application that already registers tools in
L<AnyEvent::MCP::Server::Toolset>, start an HTTP listener:

   use AnyEvent;
   use AnyEvent::MCP::Server::HTTP;

   my $server = AnyEvent::MCP::Server::HTTP->new (
      toolsets => [$tools], tokens => [$secret],
      host => "127.0.0.1", port => 31740,
   );
   $server->listen;
   print $server->url, "\n";
   AE::cv->recv;

C<$tools> is a Toolset and C<$secret> is a previously generated private
URL-safe token. Do not use a sample or hardcoded token in a real service.
This object handles sockets and HTTP; L<AnyEvent::MCP::Server> dispatches
requests, while the Toolset runs tool callbacks. For a standalone program
with automatic configuration and startup, prefer
L<AnyEvent::MCP::Server::Simple>.

=head1 AUTHENTICATION

Unlike L<AnyEvent::MCP::Server::Simple/mcp_start>, this low-level object
does not load global configuration or derive credentials. Supply C<tokens>
explicitly, for example:

   my $server = AnyEvent::MCP::Server::HTTP->new (
      host   => "127.0.0.1",
      port   => 31740,
      path   => "/mcp/",
      tokens => ["a-long-random-secret", "another-long-random-secret"],
   );
   $server->listen;

Each token authorizes the same requests. For either token, a client may
POST to C</TOKEN/mcp/> without an Authorization header, or POST to
C</mcp/> with C<Authorization: Bearer TOKEN>. URL credentials are path
components, B<not> HTTP cookies. C<url> advertises the first token;
C<url (0)> returns the clean endpoint.

The accepted tokens are static, URL-safe strings. HTTP Basic and OAuth
access-token validation are not implemented here. There is no automatic
fallback to the master-secret-derived token: that belongs to C<mcp_start>
or L<AnyEvent::MCP::Config/http_settings>.

Authentication defaults to C<tokens>, and construction B<fails> unless a
nonempty array of valid tokens is provided. To deliberately delegate
authentication to a trusted embedding layer (for example, a reverse proxy
that rejects unauthorized requests before they reach MCP), specify
C<auth =E<gt> "none"> instead, B<without> C<tokens>. This is an explicit
opt-out, not a permissive default. The embedding layer then owns the
entire authentication boundary.
The C<origins> setting filters browser origins; it is not authentication.
URLs can leak through logs and histories, and HTTP alone does not encrypt
tokens. Use TLS when credentials cross an untrusted network. A local address
is a sensible default, but not a credential.

=head1 METHODS

=over

=item $server = AnyEvent::MCP::Server::HTTP->new (%config)

Construction does not start a listener. In addition to Server options,
the following configuration options are supported:

=over

=item host => $host

The listening address, defaulting to C<127.0.0.1>.

=item port => $port

The listening port, defaulting to zero for an automatically assigned port.

=item path => $path

The MCP endpoint path, defaulting to C</mcp/>. Bearer authentication uses
C<$path> directly; URL tokens prefix it with C</TOKEN>.

=item connection_close => $boolean

When true, disables persistent connections, sends C<Connection: close> and
closes the socket after draining each response. Defaults to false.
This is useful when an existing listener routes sockets by their first
request and cannot route subsequent requests independently.

=item max_size => $bytes

Limits incoming headers and request bodies, defaulting to 1 MiB.

=item origins => [$origin...]

Allowed Origin header values. Defaults to C<["*"]>, permitting browser requests
from any origin. An empty array rejects requests with an Origin header, while
requests without one are accepted. Allowed origins receive CORS response headers,
and nonempty origin lists enable OPTIONS preflight for POST. Preflight does not
require authentication; the subsequent POST still does.

=item handle => { %handle }

AnyEvent::Handle constructor options, such as C<tls>, C<tls_ctx>, C<timeout>
or C<on_starttls>. The socket and the read/error/EOF handlers belong to this
class.

=item tokens => [$token, ...]

Ordered tokens accepted either as C</TOKEN> before the configured
C<path> or in an C<Authorization: Bearer TOKEN> header. The first token
is used in advertised URLs. Token strings must be URL-safe and nonempty.

=item auth => "tokens" | "none"

Select authentication mode. C<tokens> is the default and requires at least
one token; C<none> explicitly disables HTTP authentication and cannot be
combined with tokens. Other values are rejected. Browser origins are
not a replacement for authentication.

=item name => $name

Identifies the service. Use L<AnyEvent::MCP::Config/http_settings>
to resolve named listener configuration before constructing this transport.

=item url_host => $hostname

Overrides the advertised hostname, for example when listening on a wildcard
address. Otherwise a wildcard uses the nodename from C<uname>.

=item url_scheme => $scheme

Overrides the advertised scheme; otherwise TLS handle options select
C<https>, and plain handles select C<http>.

=back

Every configured token authenticates in either the URL or the Authorization
header. Without tokens, the constructor requires C<auth =E<gt> "none">.

=item $url = $server->url ($with_token)

Returns the advertised URL with the actual listening port. C<$with_token>
defaults to true, including the first configured token. Pass false for
the clean URL to use with an Authorization bearer token.

The port must be known. Wildcard hostname resolution and reverse-proxy
routing remain the caller's responsibility.

=item $server->listen ($host, $port, %handle)

Starts a listener, replacing any previous listener. Omitted arguments use
the configured host and port. The actual bound port is stored in
C<< $server->{port} >>, including when requesting an ephemeral port.

C<%handle> overrides the configured C<handle> options for connections
accepted by this listener.

=item $handle = $server->accept ($socket, %handle)

Starts handling an already accepted socket. The server takes ownership of
C<$socket>. No listener is needed.

C<%handle> overrides the configured C<handle> options for this connection.

=item $server->close

Stops listening, closes accepted sockets and cancels outstanding requests.
The same object can subsequently listen or accept again.

=back

=head1 EVENTS

=over

=item on_extension => $callback->($server, $handle, $hello)

Accept raw extension connections on the HTTP listener. A first byte of C<[>
selects a bounded, newline-terminated JSON hello whose first two fields are
the protocol name and an accepted listener token. Authenticate before invoking
this callback, which validates the protocol-specific fields and takes ownership
of the handle, preserving buffered input. Throw an exception to reject it.
HTTP connections continue through the normal parser. This dispatch examines
decrypted bytes when TLS is configured, but the built-in reverse connector
currently supports only plain C<http://> endpoints.

=item on_http_request => $callback->($server, $request, $reply)

Called for every complete, syntactically valid HTTP request before MCP routing
or authentication. C<$request> is a hash containing the parsed HTTP fields
(including C<method>, C<uri>, and C<http_version>) and a C<body> field holding
the raw request body. Return false to use the normal MCP handling, or true to
handle the request yourself.

C<$reply-E<gt>($status, $reason, \%headers, $body)> sends a response, either
immediately or asynchronously after the callback returns. C<%headers> is
optional; C<Content-Type> defaults to C<application/json>, and the server
generates C<Content-Length> and manages persistent connections. The body is
an octet string. Reply at most once, and return true when taking ownership
of the request, even if the response will be sent later. The next request on
the same connection is not read until that response is sent.

The hook runs B<before> MCP authentication and CORS checks. Application
endpoints must perform their own authentication and browser request checks.
It does not replace or bypass the normal authentication of unhandled MCP
requests. Malformed or oversized requests are rejected before the hook.

=item on_connection_error => $callback->($server, $handle, $message)

Called for socket errors before closing the connection.

=item on_close => $callback->($server)

Called once after C<close> stops the listener and closes all connections.
Calling C<listen> or C<accept> again starts a new lifetime.

=back

=cut

package AnyEvent::MCP::Server::HTTP;

use common::sense;
use parent "AnyEvent::MCP::Server";
use AnyEvent::Handle ();
use AnyEvent::Socket ();
use JSON::XS ();
use Scalar::Util qw(weaken);
use POSIX ();

sub new {
   my ($class, %kv) = @_;

   !grep (exists $kv{$_}, qw(cookie bearer users))
      or die "Legacy HTTP authentication options are unsupported; use tokens\n";

   $kv{auth} //= "tokens";
   if ($kv{auth} eq "tokens") {
      ref $kv{tokens} eq "ARRAY" && @{$kv{tokens}}
         or die "HTTP server requires nonempty tokens\n";
      /\A[A-Za-z0-9_.~-]+\z/ or die "Invalid HTTP server token\n"
         for @{$kv{tokens}};
   } elsif ($kv{auth} eq "none") {
      !exists $kv{tokens}
         or die "Unauthenticated HTTP server must not configure tokens\n";
   } else {
      die "Unsupported HTTP authentication type '$kv{auth}'\n";
   }

   $class->SUPER::new (host => "127.0.0.1", port => 0, path => "/mcp/", origins => ["*"], %kv)
}

sub listen {
   my ($self, $host, $port, %handle) = @_;

   delete $self->{_closed};
   $host = $self->{host} unless defined $host;
   $port = $self->{port} unless defined $port;

   $self->{listen_host} = $host;
   $self->{listen_handle} = { %{$self->{handle} || {}}, %handle };

   delete $self->{listener};
   weaken $self;

   $self->{listener} = AnyEvent::Socket::tcp_server $host, $port, sub {
      $self->accept ($_[0], %handle) if $self;
   }, sub {
      $self->{port} = $_[2] if $self;
      ()
   };
}

sub _token_path {
   my ($self, $token) = @_;

   "/$token$self->{path}"
}

sub url {
   my ($self, $with_token) = @_;

   $with_token = 1 unless defined $with_token;

   my $host = $self->{url_host}
      || (defined $self->{listen_host} ? $self->{listen_host} : $self->{host});
   $host = (POSIX::uname)[1] if !length $host || $host eq "0.0.0.0" || $host eq "::";
   $host =~ s/\A\[(.*)\]\z/$1/; # allow already bracketed IPv6 URL hosts

   my $port = $self->{port} or die "HTTP port is not known\n";
   my $scheme = $self->{url_scheme}
      || (($self->{listen_handle} || $self->{handle} || {})->{tls} ? "https" : "http");
   my $path = $with_token && $self->{tokens} && @{$self->{tokens}}
      ? $self->_token_path ($self->{tokens}[0]) : $self->{path};

   "$scheme://" . AnyEvent::Socket::format_hostport ($host, $port) . $path
}

sub accept {
   my ($self, $socket, %handle) = @_;

   delete $self->{_closed};
   weaken $self;

   my $handle = AnyEvent::Handle->new (
      rbuf_max => $self->{max_size} || 1024 * 1024,
      %{$self->{handle}},
      %handle,
      fh       => $socket,
      on_read  => undef,
      on_error => sub {
         $self->event (connection_error => $_[0], $_[2]) if $self;
         $self->_close ($_[0]) if $self;
      },
      on_eof => sub { $self->_close ($_[0]) if $self },
   );

   $handle->{mcp_peer} = {};
   $self->{connections}{$handle} = $handle;
   if ($self->{on_extension}) {
      $handle->rtimeout (15);
      $handle->push_read (chunk => 1, sub {
         my ($handle, $first) = @_;
         return unless $self;
         $handle->{rbuf} = $first . $handle->{rbuf};

         if ($first eq "[") {
            require AnyEvent::MCP::Extension;
            AnyEvent::MCP::Extension::accept ($handle, $self->{tokens} || [], sub {
               my ($handle, $hello) = @_;
               return $handle->destroy unless $self;
               delete $self->{connections}{$handle};
               $self->{on_extension}->($self, $handle, $hello);
            }, sub { $self->_close ($_[0]) if $self });
         } else {
            $handle->rtimeout (0);
            $self->_read ($handle);
         }
      });
   } else {
      $self->_read ($handle);
   }

   $handle
}

# parse a request line and HTTP fields, using the same comma-combining
# approach as AnyEvent::HTTP::_parse_hdr. The caller already bounds headers.
sub _parse_request_headers {
   local $_ = $_[0] . "\r\n";
   /\A([!#$%&'*+.^_\x60|~0-9A-Za-z-]+) [ ]+
      ([^\x00-\x20]+) [ ]+ HTTP\/0*([0-9.]+)\r\n/gcix
      or return;
   my ($method, $uri, $version) = ($1, $2, $3);
   return unless $version =~ /\A1\.[0-9]+\z/;
   my %hdr;

   $hdr{lc $1} .= ",$2"
      while /\G
            ([!\#$%&'*+.^_\x60|~0-9A-Za-z-]+):
            [\t ]*
            ([^\x00-\x08\x0a-\x1f\x7f]*)
            \r\n
         /gcx;

   /\G\z/gc or return;

   # discard the prefix used for comma-combining repeated field values.
   substr $_, 0, 1, "" for values %hdr;
   s/[\t ]+\z// for values %hdr;

   # request-line fields override any colliding HTTP header names.
   +{ %hdr, method => $method, uri => $uri, http_version => $version }
}

sub _read {
   my ($self, $handle) = @_;

   weaken $self;

   $handle->push_read (line => "\r\n\r\n", sub {
      my ($handle, $header) = @_;

      return unless $self;

      my $hdr = _parse_request_headers ($header);
      $handle->{mcp_close} = $self->{connection_close}
         || !$hdr || $hdr->{http_version} =~ m{\A1\.0+\z}
         || $hdr->{connection} =~ /\bclose\b/i;

      return $self->_respond ($handle, 400, "Bad Request", "") unless $hdr;

      $hdr->{"content-length"} = 0 unless defined $hdr->{"content-length"};
      return $self->_respond ($handle, 400, "Bad Request", "")
         if exists $hdr->{"transfer-encoding"}
            || $hdr->{"content-length"} !~ /\A[0-9]+\z/;

      return $self->_respond ($handle, 413, "Content Too Large", "")
         if $hdr->{"content-length"} > ($self->{max_size} || 1024 * 1024);

      if ($hdr->{expect}) {
         return $self->_respond ($handle, 417, "Expectation Failed", "")
            unless lc $hdr->{expect} eq "100-continue";

         $handle->push_write ("HTTP/1.1 100 Continue\r\n\r\n");
      }

      $handle->push_read (chunk => $hdr->{"content-length"}, sub {
         my ($handle, $body) = @_;

         $self->_request ($handle, $hdr, $body) if $self;
      });
   });
}

sub _request {
   my ($self, $handle, $hdr, $body) = @_;

   delete $handle->{mcp_origin};

   if (my $hook = $self->{on_http_request}) {
      weaken $self;
      my $replied;
      my $reply = sub {
         return if $replied++ || !$self || $handle->{mcp_closed};
         my ($status, $reason, $headers, $content) = @_;
         $self->_respond ($handle, $status, $reason, $content, $headers);
      };

      return if $hook->($self, { %$hdr, body => $body }, $reply);
   }

   my $token_path = $self->{tokens}
      && grep $hdr->{uri} eq $self->_token_path ($_), @{$self->{tokens}};

   return $self->_respond ($handle, 404, "Not Found", "")
      unless $hdr->{uri} eq $self->{path} || $token_path;

   if (exists $hdr->{origin}) {
      my $wildcard = grep $_ eq "*", @{$self->{origins}};

      return $self->_respond ($handle, 403, "Forbidden", "")
         unless $wildcard || grep $_ eq $hdr->{origin}, @{$self->{origins}};

      $handle->{mcp_origin} = $wildcard ? "*" : $hdr->{origin};
   }

   if ($hdr->{method} eq "OPTIONS" && @{$self->{origins}}) {
      return $self->_respond ($handle, 405, "Method Not Allowed", "")
         if exists $hdr->{"access-control-request-method"}
            && $hdr->{"access-control-request-method"} ne "POST";

      return $self->_respond ($handle, 204, "No Content", "");
   }

   return $self->_respond ($handle, 405, "Method Not Allowed", "")
      unless $hdr->{method} eq "POST";

   if ($self->{tokens}) {
      my $authenticated = $token_path;
      my $authorization = $hdr->{authorization};

      if ($authorization =~ /\ABearer ([^\s]+)\z/i) {
         my $token = $1;
         $authenticated ||= grep $_ eq $token, @{$self->{tokens}};
      }

      return $self->_respond ($handle, 401, "Unauthorized", "")
         unless $authenticated;
   }

   return $self->_respond ($handle, 415, "Unsupported Media Type", "")
      unless $hdr->{"content-type"} =~ m{\Aapplication/json(?:\s*;|\z)}i;

   my $message = eval { JSON::XS::decode_json $body };

   if ($@) {
      return $self->_rpc_error (sub {
         $self->_respond ($handle, 400, "Bad Request", JSON::XS::encode_json $_[0]);
      }, undef, -32700, "Parse error");
   }

   my $params = ref $message eq "HASH" && ref $message->{params} eq "HASH" ? $message->{params} : {};
   my $meta   = ref $params->{_meta} eq "HASH" ? $params->{_meta} : {};
   my $modern = exists $meta->{"io.modelcontextprotocol/protocolVersion"}
      || $hdr->{"mcp-protocol-version"} ge "2026";

   if ($modern && ref $message eq "HASH" && exists $message->{id}) {
      my %expected = (
         "mcp-protocol-version" => $meta->{"io.modelcontextprotocol/protocolVersion"},
         "mcp-method"           => $message->{method},
      );

      $expected{"mcp-name"} = exists $params->{name} ? $params->{name} : $params->{uri}
         if $message->{method} =~ /\A(?:tools\/call|prompts\/get|resources\/read)\z/;

      for my $name (keys %expected) {
         my $value = $hdr->{$name};

         if ($name eq "mcp-name" && $value =~ /\A=\?base64\?([A-Za-z0-9+\/=]*)\?=\z/) {
            $value = eval { AnyEvent::MCP::utf8dec (MIME::Base64::decode_base64 ($1)) };
         }

         unless (defined $value && defined $expected{$name} && $value eq $expected{$name}) {
            return $self->_rpc_error (sub {
               $self->_respond ($handle, 400, "Bad Request", JSON::XS::encode_json $_[0]);
            }, $message->{id}, -32020, "Header mismatch: $name");
         }
      }
   }

   weaken $self;

   $self->rpc ($message, sub {
      my ($response) = @_;

      return unless $self && !$handle->{mcp_closed};

      my ($status, $reason) = defined $response ? (200, "OK") : (202, "Accepted");

      if ($modern && defined $response && $response->{error}) {
         ($status, $reason) = $response->{error}{code} == -32601
            ? (404, "Not Found") : (400, "Bad Request");
      }

      $self->_respond ($handle, $status, $reason, defined $response ? JSON::XS::encode_json $response : "");
   },
      peer             => $handle->{mcp_peer},
      protocol_version => $hdr->{"mcp-protocol-version"} || "2025-03-26",
   );
}

sub _respond {
   my ($self, $handle, $status, $reason, $body, $headers) = @_;

   return if $handle->{mcp_closed};

   $body = "" unless defined $body;
   my $content_type = "application/json";
   my $extra = "";

   if ($headers) {
      ref $headers eq "HASH" or die "HTTP response headers must be a hash\n";
      while (my ($name, $value) = each %$headers) {
         $name =~ /\A[!#\$%&'*+.^_`|~0-9A-Za-z-]+\z/
            && defined $value && !ref $value && $value !~ /[\r\n\0]/
            or die "Invalid HTTP response header\n";
         $name !~ /\A(?:content-length|connection|transfer-encoding)\z/i
            or die "HTTP response framing headers are managed by the server\n";
         if (lc $name eq "content-type") {
            $content_type = $value;
         } else {
            $extra .= "$name: $value\r\n";
         }
      }
   }

   my $close = $handle->{mcp_close} || $status != 200 && $status != 202;

   $handle->push_write (
      "HTTP/1.1 $status $reason\r\n"
      . "Content-Type: $content_type\r\n"
      . "Content-Length: " . (length $body) . "\r\n"
      . $extra
      . (defined $handle->{mcp_origin} ? "Access-Control-Allow-Origin: $handle->{mcp_origin}\r\n"
         . ($handle->{mcp_origin} ne "*" ? "Vary: Origin\r\n" : "") : "")
      . ($status == 204 ? "Access-Control-Allow-Methods: POST, OPTIONS\r\n"
         . "Access-Control-Allow-Headers: content-type,authorization,mcp-protocol-version,mcp-method,mcp-name\r\n"
         . "Access-Control-Max-Age: 86400\r\n" : "")
      . ($status == 405 ? "Allow: POST" . (@{$self->{origins}} ? ", OPTIONS" : "") . "\r\n" : "")
      . ($status == 401 && $self->{tokens} ? "WWW-Authenticate: Bearer\r\n" : "")
      . ($close ? "Connection: close\r\n" : "")
      . "\r\n$body"
   );

   if ($close) {
      weaken $self;
      $handle->on_drain (sub { $self->_close ($_[0]) if $self });
   } else {
      $self->_read ($handle);
   }
}

sub _close {
   my ($self, $handle) = @_;

   return if $handle->{mcp_closed};
   $handle->{mcp_closed} = 1;

   my $requests = delete $handle->{mcp_peer}{requests} || {};
   $_->cancel ("Connection closed") for grep defined, values %$requests;

   delete $self->{connections}{$handle};
   $handle->destroy;
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
