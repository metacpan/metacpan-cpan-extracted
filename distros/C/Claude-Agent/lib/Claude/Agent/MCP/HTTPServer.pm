package Claude::Agent::MCP::HTTPServer;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::MCP::HeaderUtils ();

BEGIN {
    Object::Proto::define('Claude::Agent::MCP::HTTPServer',
        'url:Str:required',
        'headers:HashRef:default({})',
        'sensitive_headers:ArrayRef:default([])',
        'type:Str:readonly:default(http)',
    );
}

sub BUILD {
    my ($self) = @_;
    die "URL must use http or https scheme"
        unless $self->url =~ m{^https?://}i;
    return;
}

sub is_sensitive_header {
    my ($self, $header_name) = @_;
    return Claude::Agent::MCP::HeaderUtils::is_sensitive_header(
        $header_name, $self->sensitive_headers
    );
}

sub redacted_headers {
    my ($self) = @_;
    return Claude::Agent::MCP::HeaderUtils::redacted_headers(
        $self->headers, $self->sensitive_headers
    );
}

sub to_hash {
    my ($self) = @_;
    return {
        type    => 'http',
        url     => $self->url,
        headers => $self->headers,
    };
}

1;

__END__

=head1 NAME

Claude::Agent::MCP::HTTPServer - A remote MCP server reached over streamable HTTP

=head1 SYNOPSIS

    use Claude::Agent::MCP::HTTPServer;

    my $server = Claude::Agent::MCP::HTTPServer->new(
        url     => 'https://api.example.com/mcp',
        headers => { Authorization => "Bearer $token" },
    );

=head1 DESCRIPTION

Configuration for an MCP server the CLI connects to over streamable HTTP.
The URL must use the http or https scheme.

Header values that look sensitive (C<Authorization>, C<X-API-Key> and the
like, plus anything named in C<sensitive_headers>) are redacted in debug
output; see L<Claude::Agent::MCP::HeaderUtils>.

=head1 ATTRIBUTES

=head2 url

The server's URL. Required.

=head2 headers

HashRef of request headers.

=head2 sensitive_headers

ArrayRef of header names to redact in debug output, beyond the ones
recognised automatically.

=head2 type

Always C<http>. Read only.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 is_sensitive_header

    if ($server->is_sensitive_header('Authorization')) { ... }

True when the header would be redacted.

=head2 redacted_headers

    my $safe = $server->redacted_headers;

The headers with sensitive values replaced, for logging.

=head2 to_hash

    my $hash = $server->to_hash;

C<{ type, url, headers }>, the C<--mcp-config> entry.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
