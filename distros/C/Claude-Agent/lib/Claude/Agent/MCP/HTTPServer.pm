package Claude::Agent::MCP::HTTPServer;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Claude::Agent::MCP::HeaderUtils ();
use Marlin
    'url!'             => Str,
    'headers'          => sub { {} },
    'sensitive_headers' => sub { [] },  # Headers to redact from debug output
    'type'             => sub { 'http' };

sub BUILD {
    my ($self) = @_;
    die "URL must use http or https scheme"
        unless $self->url =~ m{^https?://}i;
    return;
}

=head1 NAME

Claude::Agent::MCP::HTTPServer - HTTP MCP server configuration

=head1 DESCRIPTION

Configuration for a remote MCP server using HTTP.

=head2 ATTRIBUTES

=over 4

=item * url - Server URL

=item * headers - HashRef of HTTP headers

B<Security note:> Headers containing sensitive data (authorization tokens, API
keys) are automatically redacted in debug output. Common sensitive headers like
C<Authorization>, C<X-API-Key>, etc. are detected automatically. You can also
explicitly mark additional headers as sensitive using C<sensitive_headers>.

=item * sensitive_headers - ArrayRef of header names to redact (optional)

Additional header names to treat as sensitive beyond the auto-detected ones.

=item * type - Always 'http'

=back

=head2 METHODS

=head3 is_sensitive_header

    if ($server->is_sensitive_header('Authorization')) { ... }

Check if a header name is considered sensitive (should be redacted in logs).

=cut

sub is_sensitive_header {
    my ($self, $header_name) = @_;
    return Claude::Agent::MCP::HeaderUtils::is_sensitive_header(
        $header_name, $self->sensitive_headers
    );
}

=head3 redacted_headers

    my $safe_headers = $server->redacted_headers();

Returns a copy of headers with sensitive values replaced by '[REDACTED]'.
Use this for debug output instead of accessing headers directly.

=cut

sub redacted_headers {
    my ($self) = @_;
    return Claude::Agent::MCP::HeaderUtils::redacted_headers(
        $self->headers, $self->sensitive_headers
    );
}

=head3 to_hash

    my $hash = $server->to_hash();

Convert the server configuration to a hash for JSON serialization.
Note: This returns actual header values for the CLI. Use C<redacted_headers>
for debug/logging purposes.

=cut

sub to_hash {
    my ($self) = @_;
    return {
        type    => 'http',
        url     => $self->url,
        headers => $self->headers,
    };
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
