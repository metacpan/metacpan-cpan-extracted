use v5.36;
use Test::More;

# Unit tests for the two pure helpers in the Catalyst seam: the RFC 9728
# metadata-URL derivation and the RFC 7230 quoted-string escaper. Both are
# plain functions (no invocant), so they are callable without an app.
require_ok('Catalyst::Plugin::OAuth2::ResourceServer');

my $derive = \&Catalyst::Plugin::OAuth2::ResourceServer::_oauth_rs_metadata_url;
my $quote  = \&Catalyst::Plugin::OAuth2::ResourceServer::_oauth_rs_quote_hval;

# --- RFC 9728 3.1 derivation: https resources ---
is(
    $derive->('https://api.example.com/v1'),
    'https://api.example.com/.well-known/oauth-protected-resource/v1',
    'https with path: well-known segment inserted before the path'
);
is(
    $derive->('https://api.example.com'),
    'https://api.example.com/.well-known/oauth-protected-resource',
    'https host-only: bare well-known path'
);
is(
    $derive->('https://api.example.com/'),
    'https://api.example.com/.well-known/oauth-protected-resource',
    'https trailing slash: no doubled slash'
);
is(
    $derive->('http://localhost:5000/mcp'),
    'http://localhost:5000/.well-known/oauth-protected-resource/mcp',
    'http (dev) resource is derivable too, port preserved'
);

# --- non-http(s) resources are NOT derivable: undef, never a garbage URL ---
is( $derive->('urn:example:resource'), undef, 'urn resource -> undef (no garbage URL)' );
is( $derive->('did:example:123'),      undef, 'other non-hierarchical scheme -> undef' );
is( $derive->('not a uri'),            undef, 'unparseable resource -> undef' );
is( $derive->(''),                     undef, 'empty resource -> undef' );
is( $derive->(undef),                  undef, 'undef resource -> undef' );

# The URN case must never emit the historic malformed value.
unlike(
    $derive->('urn:example:resource') // '',
    qr/oauth-protected-resource/,
    'urn derivation does not produce a well-known URL at all'
);

# --- RFC 7230 quoted-string escaping ---
is( $quote->('plain'), 'plain', 'plain value untouched' );
is( $quote->('has "quotes"'), 'has \\"quotes\\"', 'double quotes are backslash-escaped' );
is( $quote->('back\\slash'), 'back\\\\slash', 'backslashes are backslash-escaped' );
is( $quote->('both "x" and \\y'), 'both \\"x\\" and \\\\y', 'both escaped in one pass' );
is( $quote->('a\\"b'), 'a\\\\\\"b', 'escaping is not applied twice to its own output' );
is( $quote->(undef), '', 'undef becomes the empty string' );

done_testing;
