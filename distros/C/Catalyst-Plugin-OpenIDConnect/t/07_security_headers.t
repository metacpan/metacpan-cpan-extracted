#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Catalyst::Plugin::OpenIDConnect::Controller::Root;

# ---------------------------------------------------------------------------
# Minimal mock objects — only the surface touched by begin() is implemented.
# ---------------------------------------------------------------------------

{
    package MockResponse;

    sub new { bless { headers => {} }, shift }

    sub header {
        my ( $self, $name, $value ) = @_;
        if ( defined $value ) {
            $self->{headers}{ lc $name } = $value;
        }
        return $self->{headers}{ lc $name };
    }

    sub headers { $_[0]->{headers} }
}

{
    package MockCatalyst;

    sub new {
        bless { response => MockResponse->new() }, shift;
    }

    sub response { $_[0]->{response} }
}

# ---------------------------------------------------------------------------
# Invoke begin() directly and inspect the resulting response headers.
# ---------------------------------------------------------------------------

my $controller = Catalyst::Plugin::OpenIDConnect::Controller::Root->new();
ok( $controller, 'Controller instantiated' );

my $mock_c = MockCatalyst->new();
$controller->begin($mock_c);

my $headers = $mock_c->response->headers;

# RFC 6749 §5.1 — must be present on all token (and by extension all OIDC) responses
is( $headers->{'cache-control'}, 'no-store',
    'begin sets Cache-Control: no-store' );

# HTTP/1.0 compatibility header required alongside Cache-Control
is( $headers->{'pragma'}, 'no-cache',
    'begin sets Pragma: no-cache' );

# Prevent MIME-type sniffing (MED-6)
is( $headers->{'x-content-type-options'}, 'nosniff',
    'begin sets X-Content-Type-Options: nosniff' );

# Clickjacking protection on the authorize endpoint (MED-6)
is( $headers->{'x-frame-options'}, 'DENY',
    'begin sets X-Frame-Options: DENY' );

# Modern CSP-based clickjacking protection (complements X-Frame-Options)
is( $headers->{'content-security-policy'}, "frame-ancestors 'none'",
    "begin sets Content-Security-Policy: frame-ancestors 'none'" );

# Confirm all five expected headers are present (no extras silently swallowing them)
is( scalar( grep { defined $headers->{$_} }
        qw( cache-control pragma x-content-type-options
            x-frame-options content-security-policy ) ),
    5, 'All five security headers are set by begin()' );

done_testing();
