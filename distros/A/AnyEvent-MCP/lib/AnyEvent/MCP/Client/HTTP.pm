=head1 NAME

AnyEvent::MCP::Client::HTTP - MCP over AnyEvent::HTTP

=head1 SYNOPSIS

   use AnyEvent::MCP::Client::HTTP;

   my $client = AnyEvent::MCP::Client::HTTP->new (
      name => "example", url => $url, bearer => $token,
      timeout => 30,
   );

=head1 DESCRIPTION

Use this transport to talk to an MCP server through HTTP. The caller supplies
the endpoint and, if needed, credentials; the common Client layer handles
discovery and tool calls. Unlike a browser, this client does not follow
redirects or silently retry requests. A redirected request could disclose
credentials to another host, and retrying a tool call could perform an
operation twice.

=head1 FIRST CALL

For a bundled MCP server already listening on HTTP, use the full URL
it prints with C<--print-url>:

   use AnyEvent;
   use AnyEvent::MCP::Client::HTTP;

   my $client = AnyEvent::MCP::Client::HTTP->new (
      url => "http://127.0.0.1:31740/TOKEN/",
   );
   my $cv = AE::cv;
   $client->call (workdirs => {}, sub { $cv->send (@_) });
   my ($success, $result) = $cv->recv;
   $success or die "$result->{message}\n";
   !$result->{isError} or die "$result->{content}[0]{text}\n";

Replace the example URL with the actual credential-bearing URL. The
common L<AnyEvent::MCP::Client> layer negotiates MCP and handles
callbacks. A successful JSON-RPC exchange can still return a tool error
as C<isError>; always inspect both.

=head1 METHODS

=over

=item $client = AnyEvent::MCP::Client::HTTP->new (%config)

Accepts the common L<AnyEvent::MCP::Client> options and these transport
options. Options are flat, rather than nested in an HTTP configuration hash.

=over

=item url => $url

Complete endpoint URL, optionally including a URL-path token. Required
unless supplied by the named client configuration.

=item bearer => $token

Supplies C<Authorization: Bearer TOKEN>. Without it, the URL alone is
used; a bearer token is not inferred from a URL. The server must accept
the selected credential. With the bundled servers, the URL-path token
and bearer header present the same static credential.

=item name => $name

Loads C<url>, C<bearer> and C<timeout> defaults from C<[client NAME]>.
Explicit constructor arguments override them, including explicitly undefined
credentials. Without a name no global configuration is accessed.

=item timeout => $seconds

HTTP inactivity timeout, defaulting to 300 seconds. Use the common
C<request_timeout> option for an overall tool-call deadline.

=item headers => { %headers }

Additional HTTP headers. Protocol headers and an explicitly configured
bearer header are supplied by this module.

=item max_size => $bytes

Bounds a JSON response or an individual buffered SSE event, defaulting to
16 MiB. SSE notifications are delivered incrementally rather than after
the HTTP response ends.

=back

C<proxy>, C<tls_ctx>, C<handle_params>, C<sessionid>, C<on_prepare>,
C<on_connect> and C<tcp_connect> are passed to L<AnyEvent::HTTP>.
No HTTP cookies or Basic authentication are supplied by this module.
Redirects and automatic HTTP retries are disabled.

Legacy session IDs are retained from initialization. An expired session fails
outstanding requests; a later operation can initialize again. Legacy GET
streams and the old separate SSE endpoint transport are not implemented.

=back

=cut

package AnyEvent::MCP::Client::HTTP;

use common::sense;
use parent "AnyEvent::MCP::Client";
use AnyEvent::HTTP ();
use JSON::XS ();
use MIME::Base64 ();
use Scalar::Util qw(weaken);

sub new {
   my ($class, %kv) = @_;

   if (defined $kv{name}) {
      require AnyEvent::MCP::Config;
      my $settings = AnyEvent::MCP::Config->global->{section}{"client $kv{name}"} || {};
      %kv = (
         (map { exists $settings->{$_} ? ($_ => $settings->{$_}) : () }
            qw(url bearer timeout)),
         %kv,
      );
   }

   defined $kv{url}
      or die "HTTP client requires a URL\n";
   !exists $kv{username} && !exists $kv{password}
      or die "HTTP Basic authentication is unsupported\n";
   die "Invalid bearer token\n" if defined $kv{bearer} && $kv{bearer} !~ /\A[^\s]+\z/;

   $class->SUPER::new (timeout => 300, %kv)
}

sub _send {
   my ($self, $message, $done) = @_;

   my $key = exists $message->{id} && !exists $message->{result} && !exists $message->{error}
      ? $message->{id} : "send:" . ++$self->{send_id};
   my $generation = $self->{generation};
   my %headers = (
      %{$self->{headers} || {}},
      "content-type" => "application/json",
      accept         => "application/json, text/event-stream",
   );

   $headers{authorization} = "Bearer $self->{bearer}" if defined $self->{bearer};
   $headers{"mcp-protocol-version"} = $self->{protocol_version} if defined $self->{protocol_version};
   $headers{"mcp-session-id"} = $self->{session}
      if $self->{protocol_version} lt "2026" && defined $self->{session};

   if ($self->{protocol_version} ge "2026" && exists $message->{method} && exists $message->{id}) {
      $headers{"mcp-method"} = $message->{method};
      if ($message->{method} =~ /\A(?:tools\/call|prompts\/get|resources\/read)\z/) {
         my $name = exists $message->{params}{name} ? $message->{params}{name} : $message->{params}{uri};
         $headers{"mcp-name"} = $name =~ /[^\x20-\x7e]/
            ? "=?base64?" . MIME::Base64::encode_base64 (AnyEvent::MCP::utf8enc ($name), "") . "?="
            : $name;
      }
   }

   my ($buffer, $sse, $received, $failure) = ("", 0, 0);
   my $limit = $self->{max_size} || 16 * 1024 * 1024;
   weaken $self;

   my $deliver = sub {
      my ($response) = @_;

      if (ref $response eq "HASH" && !exists $response->{method}) {
         die "HTTP response id mismatch\n"
            unless exists $message->{id} && defined $response->{id}
               && "$response->{id}" eq "$message->{id}";
         $received = 1;
      }
      $self->_receive ($response);
   };

   my $guard;
   my $ok = eval {
      $guard = AnyEvent::HTTP::http_request POST => $self->{url},
         (map { exists $self->{$_} ? ($_ => $self->{$_}) : () }
            qw(timeout proxy tls_ctx handle_params sessionid on_prepare on_connect tcp_connect)),
         headers    => \%headers,
         body       => JSON::XS::encode_json ($message),
         recurse    => 0,
         persistent => 0,
         on_header  => sub {
            my ($hdr) = @_;

            return 0 unless $self && $self->{generation} == $generation;
            $sse = $hdr->{"content-type"} =~ m{\Atext/event-stream(?:\s*;|\z)}i;
            if ($message->{method} eq "initialize" && $hdr->{Status} >= 200 && $hdr->{Status} < 300
               && defined $hdr->{"mcp-session-id"}) {
               $self->{session} = $hdr->{"mcp-session-id"};
            }
            1
         },
         on_body => sub {
            my ($chunk, $hdr) = @_;

            return 0 unless $self && $self->{generation} == $generation;
            $buffer .= $chunk;

            my $ok = eval {
               if ($sse) {
                  while ($buffer =~ s/\A(.*?)(?:\r\n\r\n|\n\n|\r\r)//s) {
                     my $event = $1;
                     die "SSE event exceeds size limit\n" if length $event > $limit;
                     my @data = $event =~ /^data:[ \t]?(.*?)(?:\r?$)/mg;
                     $deliver->(JSON::XS::decode_json join "\n", @data) if @data;
                  }
               }
               die "HTTP response exceeds size limit\n" if length $buffer > $limit;
               1
            };
            $failure = $@ unless $ok;
            $ok
         },
         sub {
            my (undef, $hdr) = @_;

            return unless $self && $self->{generation} == $generation;
            delete $self->{http_requests}{$key};

            if ($hdr->{Status} == 404 && defined $self->{session} && !$received) {
               return $self->close ("MCP session expired")
            }

            my $ok = eval {
               die $failure if $failure;
               if (!$sse && length $buffer) {
                  my $response = eval { JSON::XS::decode_json $buffer };
                  if (ref $response eq "HASH" && ($hdr->{Status} >= 200 && $hdr->{Status} < 300
                     || ref $response->{error} eq "HASH")) {
                     $deliver->($response);
                  } else {
                     die "HTTP $hdr->{Status} $hdr->{Reason}\n"
                  }
               }

               die "HTTP $hdr->{Status} $hdr->{Reason}\n"
                  unless $hdr->{Status} >= 200 && $hdr->{Status} < 300;
               die "HTTP response has no matching JSON-RPC reply\n"
                  if exists $message->{id} && exists $message->{method} && !$received;
               1
            };
            $done->($ok ? (1, undef) : (0, { transport => 1, message => "$@" }));
         };
      1
   };
   if ($ok) {
      $self->{http_requests}{$key} = $guard if $self && $guard;
   } else {
      $done->(0, { transport => 1, message => "$@" });
   }
}

sub _abort {
   my ($self, $id) = @_;

   delete $self->{http_requests}{$id};
}

sub _shutdown {
   my ($self) = @_;

   delete @$self{qw(http_requests session)};
}

1
