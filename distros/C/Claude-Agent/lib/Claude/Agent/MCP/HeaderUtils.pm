package Claude::Agent::MCP::HeaderUtils;

use 5.020;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(is_sensitive_header redacted_headers);

=head1 NAME

Claude::Agent::MCP::HeaderUtils - Header sensitivity utilities for MCP servers

=head1 SYNOPSIS

    use Claude::Agent::MCP::HeaderUtils qw(is_sensitive_header redacted_headers);

    if (is_sensitive_header('Authorization', \@custom_sensitive)) {
        warn "Don't log this header!";
    }

    my $safe = redacted_headers($headers, \@custom_sensitive);

=head1 DESCRIPTION

Shared utilities for detecting and redacting sensitive HTTP headers.
Used by SSEServer and HTTPServer to avoid code duplication.

=cut

# Headers that are automatically treated as sensitive
my @AUTO_SENSITIVE = qw(
    authorization
    x-api-key
    x-auth-token
    x-access-token
    bearer
    api-key
    apikey
    secret
    token
    password
    credential
);

=head1 FUNCTIONS

=head2 is_sensitive_header

    if (is_sensitive_header($header_name, $custom_sensitive_arrayref)) { ... }

Check if a header name is considered sensitive (should be redacted in logs).
Common patterns like 'authorization', 'token', 'secret' are auto-detected.

=cut

sub is_sensitive_header {
    my ($header_name, $custom_sensitive) = @_;
    return 0 unless defined $header_name;

    my $lc_name = lc($header_name);

    # Check auto-sensitive patterns
    for my $pattern (@AUTO_SENSITIVE) {
        return 1 if index($lc_name, $pattern) >= 0;
    }

    # Check explicitly marked sensitive headers
    if ($custom_sensitive && ref($custom_sensitive) eq 'ARRAY') {
        for my $sensitive (@$custom_sensitive) {
            return 1 if lc($sensitive) eq $lc_name;
        }
    }

    return 0;
}

=head2 redacted_headers

    my $safe_headers = redacted_headers($headers, $custom_sensitive_arrayref);

Returns a copy of headers with sensitive values replaced by '[REDACTED]'.
Use this for debug output instead of accessing headers directly.

=cut

sub redacted_headers {
    my ($headers, $custom_sensitive) = @_;
    my %redacted;

    for my $key (keys %$headers) {
        if (is_sensitive_header($key, $custom_sensitive)) {
            $redacted{$key} = '[REDACTED]';
        } else {
            $redacted{$key} = $headers->{$key};
        }
    }

    return \%redacted;
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
