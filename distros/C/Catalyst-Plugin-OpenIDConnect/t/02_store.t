#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Catalyst::Plugin::OpenIDConnect::Utils::Store;
use Catalyst::Plugin::OpenIDConnect::Role::Store;

# ---------------------------------------------------------------------------
# Role compliance
# ---------------------------------------------------------------------------

ok(
    Catalyst::Plugin::OpenIDConnect::Utils::Store->DOES(
        'Catalyst::Plugin::OpenIDConnect::Role::Store'
    ),
    'Utils::Store consumes Role::Store',
);

# ---------------------------------------------------------------------------
# Basic lifecycle
# ---------------------------------------------------------------------------

my $store = Catalyst::Plugin::OpenIDConnect::Utils::Store->new();
ok($store, 'Store created');

my $code = $store->create_authorization_code(
    'test-client',
    bless( { id => 'user-123' }, 'TestUser' ),
    'openid profile email',
    'http://localhost:3000/callback',
    'random-nonce-123',
);

ok($code, 'Authorization code created');
like($code, qr/^[a-zA-Z0-9]+$/, 'Code is alphanumeric');
is( length($code), 128, 'Code is 128 characters long' );

# ---------------------------------------------------------------------------
# Retrieval
# ---------------------------------------------------------------------------

my $code_data = $store->get_authorization_code($code);
ok($code_data, 'Authorization code retrieved');
is($code_data->{client_id},    'test-client',                    'Client ID matches');
is($code_data->{scope},        'openid profile email',           'Scope matches');
is($code_data->{redirect_uri}, 'http://localhost:3000/callback', 'Redirect URI matches');
is($code_data->{nonce},        'random-nonce-123',               'Nonce matches');
ok($code_data->{created_at},  'created_at is set');
ok($code_data->{expires_at},  'expires_at is set');
ok( $code_data->{expires_at} > time(), 'Code is not yet expired' );

# ---------------------------------------------------------------------------
# Missing code returns undef
# ---------------------------------------------------------------------------

is( $store->get_authorization_code('nonexistent-code'), undef,
    'get_authorization_code returns undef for unknown code' );

# ---------------------------------------------------------------------------
# Consumption (single-use enforcement)
# HIGH-4: consume_authorization_code must atomically return the data so the
# controller never needs a separate get_authorization_code call.
# ---------------------------------------------------------------------------

my $returned_data = $store->consume_authorization_code($code);
ok( $returned_data, 'consume_authorization_code returns the code data' );
is( $returned_data->{client_id},    'test-client',                    'returned client_id matches' );
is( $returned_data->{scope},        'openid profile email',           'returned scope matches' );
is( $returned_data->{redirect_uri}, 'http://localhost:3000/callback', 'returned redirect_uri matches' );
is( $returned_data->{nonce},        'random-nonce-123',               'returned nonce matches' );

is( $store->get_authorization_code($code), undef,
    'Code is consumed and no longer retrievable' );

# Second consume must return undef (single-use enforcement)
is( $store->consume_authorization_code($code), undef,
    'Second consume returns undef' );

# Double-consume must not die
lives_ok { $store->consume_authorization_code($code) }
    'Consuming an already-consumed code does not die';

# ---------------------------------------------------------------------------
# Expiry
# ---------------------------------------------------------------------------

{
    my $expired_store = Catalyst::Plugin::OpenIDConnect::Utils::Store->new();
    my $expired_code  = $expired_store->create_authorization_code(
        'client', bless( {}, 'U' ), 'openid', 'http://example.com/cb', undef,
    );

    # Back-date the expiry timestamp
    $expired_store->codes->{$expired_code}{expires_at} = time() - 1;

    is( $expired_store->get_authorization_code($expired_code), undef,
        'Expired code returns undef' );

    # The store should have cleaned up the key
    ok( !exists $expired_store->codes->{$expired_code},
        'Expired code removed from internal hash' );
}

# ---------------------------------------------------------------------------
# CSPRNG: codes must be unique
# ---------------------------------------------------------------------------

{
    my $s = Catalyst::Plugin::OpenIDConnect::Utils::Store->new();
    my %seen;
    for ( 1 .. 20 ) {
        my $c = $s->create_authorization_code(
            'c', bless( {}, 'U' ), 'openid', 'http://example.com/', undef );
        ok( !$seen{$c}, "Code $_ is unique" );
        $seen{$c}++;
    }
}

# ---------------------------------------------------------------------------
# PKCE: code_challenge stored and returned by consume
# ---------------------------------------------------------------------------

{
    my $ps = Catalyst::Plugin::OpenIDConnect::Utils::Store->new();
    my $pc = $ps->create_authorization_code(
        'pkce-client',
        bless( { id => 'u1' }, 'TestUser' ),
        'openid',
        'http://localhost:3000/callback',
        undef,
        { code_challenge => 'abc123challenge', code_challenge_method => 'S256' },
    );
    my $pd = $ps->consume_authorization_code($pc);
    ok( $pd, 'PKCE code created and consumed' );
    is( $pd->{code_challenge},        'abc123challenge', 'code_challenge stored and returned' );
    is( $pd->{code_challenge_method}, 'S256',            'code_challenge_method stored and returned' );
}

# Without PKCE the fields are absent
{
    my $ns = Catalyst::Plugin::OpenIDConnect::Utils::Store->new();
    my $nc = $ns->create_authorization_code(
        'no-pkce-client', bless( {}, 'TestUser' ), 'openid',
        'http://example.com/cb', undef,
    );
    my $nd = $ns->consume_authorization_code($nc);
    ok( !$nd->{code_challenge}, 'No code_challenge when PKCE not used' );
}

# ---------------------------------------------------------------------------
# Refresh token JTI lifecycle (MED-1)
# ---------------------------------------------------------------------------

{
    my $rs = Catalyst::Plugin::OpenIDConnect::Utils::Store->new();

    # Store a JTI
    $rs->store_refresh_token( 'jti-001', 'user-sub-1', 'client-a', 3600 );

    # First consume returns the metadata
    my $rt_data = $rs->consume_refresh_token('jti-001');
    ok( $rt_data, 'consume_refresh_token returns data on first call' );
    is( $rt_data->{sub},       'user-sub-1', 'sub preserved in refresh token store' );
    is( $rt_data->{client_id}, 'client-a',   'client_id preserved in refresh token store' );

    # Second consume returns undef (single-use enforcement)
    is( $rs->consume_refresh_token('jti-001'), undef,
        'Second consume_refresh_token returns undef (single-use enforcement)' );

    # Unknown JTI returns undef
    is( $rs->consume_refresh_token('no-such-jti'), undef,
        'consume_refresh_token returns undef for unknown jti' );
}

# Expired refresh token must be rejected
{
    my $rs = Catalyst::Plugin::OpenIDConnect::Utils::Store->new();
    $rs->store_refresh_token( 'jti-exp', 'user-sub-2', 'client-b', 1 );
    # Force-expire the entry
    $rs->_refresh_tokens->{'jti-exp'}{exp} = time() - 1;
    is( $rs->consume_refresh_token('jti-exp'), undef,
        'Expired refresh token JTI returns undef' );
}

# revoke_refresh_tokens_for_user removes all tokens for that subject
{
    my $rs = Catalyst::Plugin::OpenIDConnect::Utils::Store->new();
    $rs->store_refresh_token( 'jti-r1', 'user-sub-3', 'client-c', 3600 );
    $rs->store_refresh_token( 'jti-r2', 'user-sub-3', 'client-d', 3600 );
    $rs->store_refresh_token( 'jti-r3', 'user-sub-4', 'client-c', 3600 );

    $rs->revoke_refresh_tokens_for_user('user-sub-3');

    is( $rs->consume_refresh_token('jti-r1'), undef,
        'revoke_refresh_tokens_for_user removes first token for user' );
    is( $rs->consume_refresh_token('jti-r2'), undef,
        'revoke_refresh_tokens_for_user removes second token for user' );
    ok( $rs->consume_refresh_token('jti-r3'),
        'revoke_refresh_tokens_for_user does not remove tokens for other user' );
}

done_testing();
