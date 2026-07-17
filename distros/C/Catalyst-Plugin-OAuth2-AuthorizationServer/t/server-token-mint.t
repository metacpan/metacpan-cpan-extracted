use v5.36;
use Test::More;
use Test::Fatal;
use Crypt::JWT qw/decode_jwt/;

my $class = 'Catalyst::Plugin::OAuth2::AuthorizationServer::Server';
require_ok($class);

# a trivial stub store object (no methods exercised here)
package T::Store { use Moo;
    with 'Catalyst::Plugin::OAuth2::AuthorizationServer::Role::Store';
    sub create_client {} sub find_client {}
    sub save_authorization_request {} sub take_authorization_request {}
    sub create_auth_code {} sub consume_auth_code {}
    sub create_refresh_token {} sub rotate_refresh_token {}
    sub revoke_family {} sub revoke_refresh_tokens_for_subject {}
}
package main;

my $key = 'test-signing-key-0123456789abcdef';
my $eng = $class->new(
    store       => T::Store->new,
    signing_key => $key,
    issuer      => 'https://as.example',
    resource    => 'https://rs.example/mcp',
);

# BUILD validation
like(
    exception {
        $class->new( store => T::Store->new, signing_key => $key,
            issuer => 'i', resource => [] );
    },
    qr/resource/,
    'empty resource arrayref rejected'
);
like(
    exception {
        $class->new( store => T::Store->new, signing_key => $key,
            issuer => 'i', resource => 'r', access_ttl => 0 );
    },
    qr/access_ttl/,
    'non-positive access_ttl rejected'
);
like(
    exception {
        $class->new( store => T::Store->new, signing_key => $key,
            issuer => 'i', resource => 'r', refresh_ttl => -1 );
    },
    qr/refresh_ttl/,
    'negative refresh_ttl rejected'
);
like(
    exception {
        $class->new( store => T::Store->new, signing_key => $key,
            issuer => 'i', resource => 'r', code_ttl => 0 );
    },
    qr/code_ttl/,
    'non-positive code_ttl rejected'
);

# mint a token and verify the claims round-trip with the same key
my $before = time;
my $jwt = $eng->mint_access_token({
    sub   => 'user-42',
    scope => 'example:read',
});
ok( length $jwt, 'mint returns a token string' );

my $claims = decode_jwt( token => $jwt, key => $key );
is( $claims->{sub},   'user-42',                  'sub claim' );
is( $claims->{scope}, 'example:read',               'scope claim' );
is( $claims->{iss},   'https://as.example',       'iss from issuer' );
is( $claims->{aud},   'https://rs.example/mcp',   'aud from resource' );
ok( $claims->{exp} >= $before + 900 && $claims->{exp} <= time + 900 + 2,
    'exp ~ now + access_ttl' );

# an explicit aud overrides the configured-resource default
my $claims_aud = decode_jwt(
    token => $eng->mint_access_token( { sub => 'u' }, 'https://other/api' ),
    key   => $key );
is( $claims_aud->{aud}, 'https://other/api', 'explicit aud honoured' );

# random tokens are URL-safe and unique
my %seen;
for ( 1 .. 100 ) {
    my $t = $eng->_random_token(32);
    like( $t, qr/\A[A-Za-z0-9_-]+\z/, 'token is base64url' );
    ok( !$seen{$t}++, 'token unique' );
}

like(
    exception {
        $class->new( store => T::Store->new, signing_key => $key,
            issuer => 'i', resource => 'r', jwt_alg => 'RS256' );
    },
    qr/jwt_alg/,
    'non-HS jwt_alg rejected'
);

like(
    exception {
        $class->new( store => T::Store->new, signing_key => $key,
            issuer => 'i', resource => 'r', bogus_unknown_key => 1 );
    },
    qr/bogus_unknown_key|StrictConstructor|not.*(allowed|listed)/i,
    'unknown config key croaks (StrictConstructor)'
);

# RFC 7518 3.2: an HS key must be at least as long as the hash output, or the
# signature is brute-forceable. Mirrors the ResourceServer guard.
my %min_key_bytes = ( HS256 => 32, HS384 => 48, HS512 => 64 );
for my $alg ( sort keys %min_key_bytes ) {
    my $min = $min_key_bytes{$alg};
    like(
        exception {
            $class->new( store => T::Store->new,
                signing_key => 'x' x ( $min - 1 ),
                issuer => 'i', resource => 'r', jwt_alg => $alg );
        },
        qr/\Qsigning_key must be at least $min bytes for $alg\E/,
        "$alg signing_key of $min-1 bytes rejected"
    );
    is(
        exception {
            $class->new( store => T::Store->new, signing_key => 'x' x $min,
                issuer => 'i', resource => 'r', jwt_alg => $alg );
        },
        undef,
        "$alg signing_key of exactly $min bytes accepted"
    );
}

# an invalid jwt_alg is reported as such, not as an undef key minimum
like(
    exception {
        $class->new( store => T::Store->new, signing_key => 'x',
            issuer => 'i', resource => 'r', jwt_alg => 'none' );
    },
    qr/jwt_alg/,
    'alg allowlist runs before the key-length lookup'
);

# jti: present, unique per mint, and not overridable by the caller
{
    my $eng2 = $class->new(
        store => T::Store->new, signing_key => $key,
        issuer => 'https://as', resource => 'https://rs/mcp',
    );
    my $one = decode_jwt(
        token => $eng2->mint_access_token({ sub => 'u' }), key => $key );
    my $two = decode_jwt(
        token => $eng2->mint_access_token({ sub => 'u' }), key => $key );

    ok( length $one->{jti}, 'access token carries a jti' );
    isnt( $one->{jti}, $two->{jti}, 'jti is unique per mint' );

    my $forced = decode_jwt(
        token => $eng2->mint_access_token({ sub => 'u', jti => 'attacker' }),
        key   => $key );
    isnt( $forced->{jti}, 'attacker', 'a caller cannot pin the jti' );
}

done_testing;
