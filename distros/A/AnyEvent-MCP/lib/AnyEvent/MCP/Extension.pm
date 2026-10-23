=head1 NAME

AnyEvent::MCP::Extension - authenticated non-HTTP connections on an MCP listener

=head1 DESCRIPTION

The HTTP listeners used by the bundled servers can also accept private
raw-TCP protocols on the same port. This helper authenticates the initial
JSON handshake and passes the already-buffered connection to its protocol
handler; it does B<not> implement HTTP or MCP dispatch.

C<mcp-multibroker> uses this mechanism for reverse-connecting MCP servers.
Vim editor and browser connections can also share an MCP HTTP listener,
but they use WebSocket upgrades rather than this raw JSON hello protocol.
Ordinary MCP clients should use
L<AnyEvent::MCP::Client::HTTP> or
L<AnyEvent::MCP::Client::JSONL>, not this extension protocol.

   my ($host, $port, $token, $alias) =
      AnyEvent::MCP::Extension::parse_url
         "http://127.0.0.1:31740/TOKEN/files";

The returned address is for a raw TCP extension connection, not an HTTP
request. See L<AnyEvent::MCP::Server::Connect> for the MCP user of it.

=head1 FUNCTIONS

=over

=item AnyEvent::MCP::Extension::accept $handle, [$token...], $callback->($handle, $hello), $reject->($handle)

Read one bounded newline-terminated JSON array beginning with a protocol name
and accepted token. Authenticate before calling the protocol-specific handler.
Invalid hellos close the connection. The callback takes ownership of the same
handle, including buffered bytes after the hello. Remaining array fields belong
to the selected protocol. An optional C<$reject> callback releases any
listener ownership on rejection; otherwise the handle is destroyed.

=item ($host, $port, $token, $alias) = AnyEvent::MCP::Extension::parse_url $url

Parse C<http://host[:port]/token/alias>, including bracketed IPv6 hosts.
An omitted port defaults to 80. The URL names a raw TCP extension endpoint
sharing an HTTP listener; no HTTP request is sent. Tokens use the ordinary
listener token syntax and aliases use ASCII letters, digits, underscores and hyphens.

=back

=cut

package AnyEvent::MCP::Extension;

use common::sense;
use JSON::XS ();

sub parse_url {
   my ($url) = @_;

   my ($host, $port, $token, $alias) =
      $url =~ m{\Ahttp://(\[[^\]]+\]|[^/:?#]+)(?::([0-9]+))?/([A-Za-z0-9_.~-]+)/([A-Za-z0-9_-]+)\z};
   defined $host && (!defined $port || $port > 0 && $port <= 65535)
      or die "Expected extension URL http://host[:port]/token/alias\n";
   $host =~ s/\A\[(.*)\]\z/$1/;

   ($host, defined $port ? 0 + $port : 80, $token, $alias)
}

sub accept {
   my ($handle, $tokens, $done, $reject) = @_;

   my $rbuf_max = $handle->{rbuf_max};
   $handle->rtimeout (15);
   $handle->{rbuf_max} = 4096;
   $handle->push_read (line => sub {
      my (undef, $line) = @_;

      my $ok = eval {
         my $hello = JSON::XS->new->utf8->max_depth (8)->decode ($line);
         ref $hello eq "ARRAY" && @$hello >= 2
            && defined $hello->[0] && !ref $hello->[0]
            && defined $hello->[1] && !ref $hello->[1]
            && (grep $_ eq $hello->[1], @$tokens)
            or die "Invalid extension hello\n";

         $handle->rtimeout (0);
         $handle->{rbuf_max} = $rbuf_max;
         $done->($handle, $hello);
         1
      };
      ($reject ? $reject->($handle) : $handle->destroy) unless $ok;
   });
}

1;
