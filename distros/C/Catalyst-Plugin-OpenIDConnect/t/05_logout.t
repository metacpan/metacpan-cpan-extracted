#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Catalyst::Plugin::OpenIDConnect::Utils::JWT;
use Catalyst::Plugin::OpenIDConnect::Controller::Root;
use Crypt::OpenSSL::RSA;

# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

my $rsa = Crypt::OpenSSL::RSA->generate_key(1024);
my $private_key = $rsa;
my $public_key  = Crypt::OpenSSL::RSA->new_public_key( $rsa->get_public_key_string() );

my $jwt = Catalyst::Plugin::OpenIDConnect::Utils::JWT->new(
    private_key => $private_key,
    public_key  => $public_key,
    key_id      => 'test-key',
    issuer      => 'https://auth.example.com',
);

# ---------------------------------------------------------------------------
# JWT::decode_id_token_hint — valid (non-expired) token
# ---------------------------------------------------------------------------

my $id_token = $jwt->create_id_token(
    sub => 'user-123',
    aud => 'test-client',
    exp => time() + 3600,
);

my $claims = $jwt->decode_id_token_hint($id_token);
ok( $claims,                    'decode_id_token_hint: returns claims for a valid token' );
is( $claims->{sub}, 'user-123', 'decode_id_token_hint: sub claim extracted' );
is( $claims->{aud}, 'test-client', 'decode_id_token_hint: aud claim extracted' );

# ---------------------------------------------------------------------------
# JWT::decode_id_token_hint — expired token must still be accepted
# Hint tokens used at logout are intentionally often expired.
# ---------------------------------------------------------------------------

my $expired_token = $jwt->create_id_token(
    sub => 'user-456',
    aud => 'test-client',
    exp => time() - 3600,    # expired 1 hour ago
);

my $expired_claims = $jwt->decode_id_token_hint($expired_token);
ok( $expired_claims,                    'decode_id_token_hint: returns claims for an expired token' );
is( $expired_claims->{aud}, 'test-client', 'decode_id_token_hint: aud extracted from expired token' );

# Confirm that verify_token *would* reject the same token (sanity check)
throws_ok {
    $jwt->verify_token($expired_token);
} qr/Token verification failed/, 'verify_token correctly rejects the expired token';

# ---------------------------------------------------------------------------
# JWT::decode_id_token_hint — tampered token must be rejected
# ---------------------------------------------------------------------------

# Corrupt the signature segment
my $tampered_token = $id_token;
$tampered_token =~ s/([^.]+)$/'A' x length($1)/e;

is( $jwt->decode_id_token_hint($tampered_token), undef,
    'decode_id_token_hint: returns undef for a tampered token' );

# ---------------------------------------------------------------------------
# JWT::decode_id_token_hint — token from a different key must be rejected
# ---------------------------------------------------------------------------

my $other_rsa = Crypt::OpenSSL::RSA->generate_key(1024);
my $other_jwt = Catalyst::Plugin::OpenIDConnect::Utils::JWT->new(
    private_key => $other_rsa,
    public_key  => Crypt::OpenSSL::RSA->new_public_key( $other_rsa->get_public_key_string() ),
    key_id      => 'other-key',
    issuer      => 'https://auth.example.com',
);

my $foreign_token = $other_jwt->create_id_token(
    sub => 'user-789',
    aud => 'test-client',
    exp => time() + 3600,
);

is( $jwt->decode_id_token_hint($foreign_token), undef,
    'decode_id_token_hint: returns undef for token signed with a different key' );

# ---------------------------------------------------------------------------
# JWT::decode_id_token_hint — structurally invalid JWT must be rejected
# ---------------------------------------------------------------------------

is( $jwt->decode_id_token_hint('not-a-jwt'),         undef, 'decode_id_token_hint: rejects single-segment string' );
is( $jwt->decode_id_token_hint('only.two'),          undef, 'decode_id_token_hint: rejects two-segment string' );
is( $jwt->decode_id_token_hint('too.many.dots.here'), undef, 'decode_id_token_hint: rejects four-segment string' );

# ---------------------------------------------------------------------------
# Controller::Root::_normalize_uri_list
# Shared helper used for both redirect_uris and post_logout_redirect_uris.
# ---------------------------------------------------------------------------

# Helper is a plain package sub, callable without a controller instance.
my $normalize = \&Catalyst::Plugin::OpenIDConnect::Controller::Root::_normalize_uri_list;

# --- Arrayref input (e.g. from YAML / JSON / Perl hash config) ---
my @uris = $normalize->( [
    'https://app.example.com/logout',
    'https://app.example.com/goodbye',
] );
is( scalar @uris, 2, '_normalize_uri_list: returns two URIs from arrayref' );
ok( ( grep { $_ eq 'https://app.example.com/logout' } @uris ),
    '_normalize_uri_list: first URI present from arrayref' );

# --- Whitespace-delimited string input (e.g. from Config::General) ---
my @str_uris = $normalize->(
    'https://app.example.com/logout https://app.example.com/goodbye'
);
is( scalar @str_uris, 2, '_normalize_uri_list: returns two URIs from string' );
ok( ( grep { $_ eq 'https://app.example.com/goodbye' } @str_uris ),
    '_normalize_uri_list: second URI present from string' );

# --- Single string (common case) ---
my @single = $normalize->( 'https://app.example.com/callback' );
is( scalar @single, 1, '_normalize_uri_list: single string returns one URI' );
is( $single[0], 'https://app.example.com/callback',
    '_normalize_uri_list: single string value correct' );

# --- undef / missing field ---
my @empty_undef = $normalize->( undef );
is( scalar @empty_undef, 0, '_normalize_uri_list: undef returns empty list' );

# --- Unlisted URI must not appear ---
ok( !( grep { $_ eq 'https://evil.example.com/steal' } @uris ),
    '_normalize_uri_list: unlisted URI is not returned' );

# ---------------------------------------------------------------------------
# SECURITY: exact-match semantics (no prefix / host-only matching)
# Both redirect_uris and post_logout_redirect_uris must use exact matching.
# ---------------------------------------------------------------------------

my @exact_uris = $normalize->( ['https://app.example.com/logout'] );

# A URL that is a prefix of a registered one must not match
ok( !( grep { $_ eq 'https://app.example.com/' } @exact_uris ),
    '_normalize_uri_list: prefix of registered URI not present' );

# A URL with an added path segment must not match
ok( !( grep { $_ eq 'https://app.example.com/logout/extra' } @exact_uris ),
    '_normalize_uri_list: registered URI with extra segment not present' );

done_testing();
