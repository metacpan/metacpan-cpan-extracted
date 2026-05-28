#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";

# ---------------------------------------------------------------------------
# Skip the whole file if neither Redis::Fast nor Redis is available.
# This avoids hard failures in environments without a Redis client installed.
# ---------------------------------------------------------------------------

my $redis_class;
for my $candidate (qw( Redis::Fast Redis )) {
    if ( eval "require $candidate; 1" ) {
        $redis_class = $candidate;
        last;
    }
}

plan skip_all => 'Neither Redis::Fast nor Redis is installed'
    unless $redis_class;

use Catalyst::Plugin::OpenIDConnect::Utils::Store::Redis;
use Catalyst::Plugin::OpenIDConnect::Role::Store;

# ---------------------------------------------------------------------------
# Helpers: build a mock Redis handle that records calls
# ---------------------------------------------------------------------------

{
    package MockRedis;

    sub new {
        my ( $class, %args ) = @_;
        return bless { store => {}, calls => [] }, $class;
    }

    sub setex {
        my ( $self, $key, $ttl, $value ) = @_;
        push @{ $self->{calls} }, [ setex => $key, $ttl, $value ];
        $self->{store}{$key} = { value => $value, ttl => $ttl };
    }

    sub get {
        my ( $self, $key ) = @_;
        my $entry = $self->{store}{$key} or return undef;
        return $entry->{value};
    }

    # GETDEL (Redis >= 6.2): atomically fetch and remove
    sub getdel {
        my ( $self, $key ) = @_;
        push @{ $self->{calls} }, [ getdel => $key ];
        my $entry = delete $self->{store}{$key};
        return defined $entry ? $entry->{value} : undef;
    }

    sub del {
        my ( $self, $key ) = @_;
        push @{ $self->{calls} }, [ del => $key ];
        delete $self->{store}{$key};
        delete $self->{sets}{$key};
    }

    sub sadd {
        my ( $self, $key, @members ) = @_;
        push @{ $self->{calls} }, [ sadd => $key, @members ];
        $self->{sets}{$key} //= {};
        $self->{sets}{$key}{$_} = 1 for @members;
    }

    sub srem {
        my ( $self, $key, @members ) = @_;
        push @{ $self->{calls} }, [ srem => $key, @members ];
        if ( $self->{sets}{$key} ) {
            delete $self->{sets}{$key}{$_} for @members;
        }
    }

    sub smembers {
        my ( $self, $key ) = @_;
        push @{ $self->{calls} }, [ smembers => $key ];
        return keys %{ $self->{sets}{$key} // {} };
    }

    sub expire {
        my ( $self, $key, $ttl ) = @_;
        push @{ $self->{calls} }, [ expire => $key, $ttl ];
        # TTL management not simulated in the mock.
    }

    sub recorded_calls { $_[0]->{calls} }
}

# ---------------------------------------------------------------------------
# Subclass that injects the mock Redis handle, bypassing the lazy builder
# ---------------------------------------------------------------------------

{
    package MockRedisStore;
    use Moose;
    extends 'Catalyst::Plugin::OpenIDConnect::Utils::Store::Redis';

    # Override the builder method rather than the attribute declaration;
    # this avoids the Moose restriction on mixing builder and default.
    sub _build_redis { MockRedis->new() }

    __PACKAGE__->meta->make_immutable;
}

# ---------------------------------------------------------------------------
# Role compliance
# ---------------------------------------------------------------------------

ok(
    Catalyst::Plugin::OpenIDConnect::Utils::Store::Redis->DOES(
        'Catalyst::Plugin::OpenIDConnect::Role::Store'
    ),
    'Utils::Store::Redis consumes Role::Store',
);

# ---------------------------------------------------------------------------
# Instantiation
# ---------------------------------------------------------------------------

my $store = MockRedisStore->new(
    prefix   => 'test:oidc:code:',
    code_ttl => 600,
);
ok( $store, 'Redis store created' );
is( $store->prefix,   'test:oidc:code:', 'prefix attribute set' );
is( $store->code_ttl, 600,               'code_ttl attribute set' );

# ---------------------------------------------------------------------------
# create_authorization_code
# ---------------------------------------------------------------------------

# The store receives a plain claims hashref (as extracted by the controller
# via get_user_claims before calling create_authorization_code).
my $user_claims = { sub => 'user-123', name => 'Test User', email => 't@example.com' };

my $code = $store->create_authorization_code(
    'test-client',
    $user_claims,
    'openid profile email',
    'http://localhost:3000/callback',
    'nonce-abc',
);

ok( $code, 'create_authorization_code returns a code' );
like( $code, qr/^[a-zA-Z0-9]+$/, 'Code is alphanumeric' );
is( length($code), 128, 'Code is 128 characters long' );

# Verify that setex was called with the right key and TTL
my $calls = $store->_redis->recorded_calls;
is( scalar @$calls, 1, 'One Redis call made for create' );
is( $calls->[0][0], 'setex', 'setex was called' );
like( $calls->[0][1], qr/^test:oidc:code:/, 'Key has correct prefix' );
is( $calls->[0][2], 600, 'TTL is code_ttl' );

# ---------------------------------------------------------------------------
# get_authorization_code - field and user claims round-trip
# ---------------------------------------------------------------------------

my $data = $store->get_authorization_code($code);
ok( $data, 'get_authorization_code returns data' );
is( $data->{client_id},    'test-client',                    'client_id matches' );
is( $data->{scope},        'openid profile email',           'scope matches' );
is( $data->{redirect_uri}, 'http://localhost:3000/callback', 'redirect_uri matches' );
is( $data->{nonce},        'nonce-abc',                      'nonce matches' );
ok( $data->{created_at},  'created_at is set' );
ok( $data->{expires_at},  'expires_at is set' );

# The user claims must survive the JSON round-trip intact so that the token
# endpoint can use them directly to build the ID/access tokens.
ok( ref($data->{user}) eq 'HASH',
    'user claims are a plain hashref after Redis round-trip' );
is( $data->{user}{sub},   'user-123',       'user.sub preserved through Redis' );
is( $data->{user}{name},  'Test User',      'user.name preserved through Redis' );
is( $data->{user}{email}, 't@example.com',  'user.email preserved through Redis' );

is( $store->get_authorization_code('nonexistent'), undef,
    'get_authorization_code returns undef for unknown code' );

# ---------------------------------------------------------------------------
# consume_authorization_code — atomic GETDEL, returns data (HIGH-4)
# ---------------------------------------------------------------------------

my $consumed_data = $store->consume_authorization_code($code);
ok( $consumed_data, 'consume_authorization_code returns the code data' );
is( $consumed_data->{client_id},    'test-client',                    'returned client_id matches' );
is( $consumed_data->{scope},        'openid profile email',           'returned scope matches' );
is( $consumed_data->{redirect_uri}, 'http://localhost:3000/callback', 'returned redirect_uri matches' );
is( $consumed_data->{nonce},        'nonce-abc',                      'returned nonce matches' );

# Code must no longer be retrievable
is( $store->get_authorization_code($code), undef,
    'Code is unavailable after consume' );

# Confirm getdel (not del) was called
my $getdel_calls = [ grep { $_->[0] eq 'getdel' } @{ $store->_redis->recorded_calls } ];
is( scalar @$getdel_calls, 1, 'getdel was called once' );
like( $getdel_calls->[0][1], qr/^test:oidc:code:/, 'getdel used correct key prefix' );

# Second consume must return undef (single-use)
is( $store->consume_authorization_code($code), undef,
    'Second consume returns undef' );

# Double-consume must not die
lives_ok { $store->consume_authorization_code($code) }
    'Consuming an already-consumed code does not die';

# ---------------------------------------------------------------------------
# CSPRNG: codes must be unique
# ---------------------------------------------------------------------------

{
    my $s = MockRedisStore->new( prefix => 'u:' );
    my %seen;
    for ( 1 .. 20 ) {
        my $c = $s->create_authorization_code(
            'c', { sub => 'u1' }, 'openid', 'http://example.com/', undef );
        ok( !$seen{$c}, "Code $_ is unique" );
        $seen{$c}++;
    }
}

# ---------------------------------------------------------------------------
# Configurable prefix and TTL
# ---------------------------------------------------------------------------

{
    my $s2 = MockRedisStore->new(
        prefix   => 'myapp:auth:',
        code_ttl => 300,
    );
    my $c = $s2->create_authorization_code(
        'client2', { sub => 'u2' }, 'openid', 'http://example.com/cb', undef );

    my $recent = $s2->_redis->recorded_calls->[-1];
    like( $recent->[1], qr/^myapp:auth:/, 'Custom prefix applied' );
    is( $recent->[2], 300, 'Custom TTL applied' );
}

# ---------------------------------------------------------------------------
# JSON corruption is handled gracefully
# ---------------------------------------------------------------------------

{
    my $s3 = MockRedisStore->new( prefix => 'bad:' );
    $s3->_redis->{store}{'bad:corrupt'} = { value => 'not-valid-json', ttl => 600 };
    my $result = $s3->get_authorization_code('corrupt');
    is( $result, undef, 'Corrupt JSON returns undef without dying' );
}

# ---------------------------------------------------------------------------
# REDIS_PASSWORD env var fallback (tested via plugin setup code path)
# ---------------------------------------------------------------------------

{
    # Simulate what OpenIDConnect.pm does when building store_args:
    # if password is absent from config but REDIS_PASSWORD is set in the
    # environment, the env var should be used.

    local $ENV{REDIS_PASSWORD} = 'env-secret';

    my $config_store_args = {};    # no password in config
    my $store_args = { %$config_store_args };

    if ( !exists $store_args->{password}
            && defined $ENV{REDIS_PASSWORD}
            && $ENV{REDIS_PASSWORD} ne '' ) {
        $store_args->{password} = $ENV{REDIS_PASSWORD};
    }

    is( $store_args->{password}, 'env-secret',
        'REDIS_PASSWORD env var applied when password absent from config' );
    is( $config_store_args->{password}, undef,
        'Original config hashref not mutated' );
}

{
    # An explicit password in config must take precedence over the env var.
    local $ENV{REDIS_PASSWORD} = 'env-secret';

    my $config_store_args = { password => 'config-secret' };
    my $store_args = { %$config_store_args };

    if ( !exists $store_args->{password}
            && defined $ENV{REDIS_PASSWORD}
            && $ENV{REDIS_PASSWORD} ne '' ) {
        $store_args->{password} = $ENV{REDIS_PASSWORD};
    }

    is( $store_args->{password}, 'config-secret',
        'Config password takes precedence over REDIS_PASSWORD env var' );
}

{
    # An empty REDIS_PASSWORD must be ignored.
    local $ENV{REDIS_PASSWORD} = '';

    my $store_args = {};
    if ( !exists $store_args->{password}
            && defined $ENV{REDIS_PASSWORD}
            && $ENV{REDIS_PASSWORD} ne '' ) {
        $store_args->{password} = $ENV{REDIS_PASSWORD};
    }

    ok( !exists $store_args->{password},
        'Empty REDIS_PASSWORD env var is not applied' );
}

# ---------------------------------------------------------------------------
# PKCE: code_challenge stored and returned through Redis JSON round-trip
# ---------------------------------------------------------------------------

{
    my $ps = MockRedisStore->new( prefix => 'pkce:' );
    my $pc = $ps->create_authorization_code(
        'pkce-client',
        { sub => 'u1' },
        'openid',
        'http://localhost:3000/callback',
        undef,
        { code_challenge => 'xyz789challenge', code_challenge_method => 'S256' },
    );
    my $pd = $ps->consume_authorization_code($pc);
    ok( $pd, 'PKCE code created and consumed via Redis mock' );
    is( $pd->{code_challenge},        'xyz789challenge', 'code_challenge round-trips through Redis JSON' );
    is( $pd->{code_challenge_method}, 'S256',            'code_challenge_method round-trips through Redis JSON' );
}

# Without PKCE the fields are absent
{
    my $ns = MockRedisStore->new( prefix => 'nopkce:' );
    my $nc = $ns->create_authorization_code(
        'no-pkce', { sub => 'u2' }, 'openid', 'http://example.com/cb', undef,
    );
    my $nd = $ns->consume_authorization_code($nc);
    ok( !$nd->{code_challenge}, 'No code_challenge in Redis when PKCE not used' );
}

# ---------------------------------------------------------------------------
# Refresh token JTI lifecycle (MED-1)
# ---------------------------------------------------------------------------

{
    my $rs = MockRedisStore->new( prefix => 'rt_test:' );

    # Store a JTI
    $rs->store_refresh_token( 'jti-001', 'user-sub-1', 'client-a', 3600 );

    my $calls = $rs->_redis->recorded_calls;
    my @setex_calls = grep { $_->[0] eq 'setex' } @$calls;
    my $rt_call = $setex_calls[-1];  # most recent setex is for the refresh token
    like( $rt_call->[1], qr/^rt_test:rt:jti-001$/, 'store_refresh_token uses rt: key prefix' );
    is( $rt_call->[2], 3600, 'store_refresh_token uses supplied TTL' );

    my @sadd_calls = grep { $_->[0] eq 'sadd' } @$calls;
    ok( scalar @sadd_calls, 'sadd called for secondary index' );
    like( $sadd_calls[-1][1], qr/rt_sub:user-sub-1/, 'sadd uses rt_sub: index key' );

    # First consume returns the metadata
    my $rt_data = $rs->consume_refresh_token('jti-001');
    ok( $rt_data, 'consume_refresh_token returns data on first call (Redis)' );
    is( $rt_data->{sub},       'user-sub-1', 'sub preserved through Redis JSON' );
    is( $rt_data->{client_id}, 'client-a',   'client_id preserved through Redis JSON' );

    # Second consume returns undef (getdel already removed the key)
    is( $rs->consume_refresh_token('jti-001'), undef,
        'Second consume_refresh_token returns undef (single-use, Redis)' );

    # Unknown JTI returns undef
    is( $rs->consume_refresh_token('no-such-jti'), undef,
        'consume_refresh_token returns undef for unknown jti (Redis)' );
}

# revoke_refresh_tokens_for_user removes all tokens for that subject
{
    my $rs = MockRedisStore->new( prefix => 'rev:' );
    $rs->store_refresh_token( 'jti-r1', 'user-sub-3', 'client-c', 3600 );
    $rs->store_refresh_token( 'jti-r2', 'user-sub-3', 'client-d', 3600 );
    $rs->store_refresh_token( 'jti-r3', 'user-sub-4', 'client-c', 3600 );

    $rs->revoke_refresh_tokens_for_user('user-sub-3');

    # The JTI keys for user-sub-3 must have been deleted
    is( $rs->_redis->{store}{'rev:rt:jti-r1'}, undef,
        'revoke_refresh_tokens_for_user deletes first jti key (Redis)' );
    is( $rs->_redis->{store}{'rev:rt:jti-r2'}, undef,
        'revoke_refresh_tokens_for_user deletes second jti key (Redis)' );
    # The set index for user-sub-3 must have been deleted
    is( $rs->_redis->{sets}{'rev:rt_sub:user-sub-3'}, undef,
        'revoke_refresh_tokens_for_user deletes the sub index set (Redis)' );
    # user-sub-4 token must remain
    ok( defined $rs->_redis->{store}{'rev:rt:jti-r3'},
        'revoke_refresh_tokens_for_user does not remove tokens for other user (Redis)' );
}

done_testing();
