#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use Test::Mock::Apache2;
    no strict 'subs';
    use Test::MockObject;
    # use Test2::V0;
    use Test::More;
    use vars qw( $DEBUG $HAVE_REF );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    our $HAVE_REF = eval{ require Crypt::PasswdMD5; Crypt::PasswdMD5->import('apache_md5_crypt'); 1 } || 0;
};

BEGIN
{
    # use_ok( 'Apache2::API' ) || BAIL_OUT( 'Unable to load Apache2::API' );
    use ok( 'Apache2::API' ) || BAIL_OUT( 'Unable to load Apache2::API' );
};

use strict;
use warnings;

# my $api = Apache2::API->new( debug => $DEBUG );
my $api = Apache2::API->new;

sub verify_apr1
{
    my( $passwd, $hash ) = @_;
    return(0) unless( defined( $passwd ) && defined( $hash ) );
    return(0) unless( $hash =~ m!\A\$apr1\$([./0-9A-Za-z]{1,8})\$([./0-9A-Za-z]{22})\z! );
    my( $salt, $body ) = ( $1, $2 );
    my $calc = apr1_md5( $passwd, $salt );
    return( $hash eq $calc );
}

sub _have_module
{
    my( $m ) = @_;
    local $@;
    return( eval( "require $m; 1" ) ? 1 : 0 );
}

sub _crypt_supports
{
    my( $setting_re, $setting_example ) = @_;
    local $@;
    my $out = eval{ crypt( 'x', $setting_example ); };
    return( !$@ && defined( $out ) && $out =~ $setting_re );
}

# quick helpers to craft settings
sub _bcrypt_setting
{
    my( $cost, $salt22 ) = @_;
    return( sprintf( '$2y$%02d$%s$', $cost, $salt22 ) );
}

sub _sha256_setting
{
    my( $rounds, $salt ) = @_;
    return defined( $rounds )
        ? sprintf( '$5$rounds=%d$%s$', $rounds, $salt )
        : sprintf( '$5$%s$', $salt )
}

sub _sha512_setting
{
    my( $rounds, $salt ) = @_;
    return defined( $rounds )
        ? sprintf( '$6$rounds=%d$%s$', $rounds, $salt )
        : sprintf( '$6$%s$', $salt )
}

# 22 chars in bcrypt alphabet
my $salt22 = '......................'; # 22 dots
my $salt16 = 'abcdefghijklmnop';       # 16 chars [A-Za-z0-9./]
my $bcrypt_cost = 5;                   # keep tests fast
my $sha_rounds  = 6000;                # a little over the default 5000

# Detect support/fallback availability
my $have_bcrypt_crypt = _crypt_supports( qr/^\$2[aby]\$/, _bcrypt_setting( $bcrypt_cost, $salt22 ) );
my $have_bcrypt_fallback = _have_module( 'Authen::Passphrase::BlowfishCrypt' )
                        || _have_module( 'Crypt::Bcrypt' )
                        || _have_module( 'Crypt::Eksblowfish::Bcrypt' );

my $have_sha256_crypt = _crypt_supports( qr/^\$5\$/, _sha256_setting( $sha_rounds, $salt16 ) );
my $have_sha512_crypt = _crypt_supports( qr/^\$6\$/, _sha512_setting( $sha_rounds, $salt16 ) );
my $have_sha_fallback = _have_module( 'Crypt::Passwd::XS' );

subtest 'format & alphabet' => sub
{
    # random salt
    my $ht = $api->htpasswd( 'secret', create => 1 );
    my $h = $ht->hash;
    like( $h, qr/\A\$apr1\$[.\/0-9A-Za-z]{1,8}\$[.\/0-9A-Za-z]{22}\z/, 'hash format looks right' );

    my( $salt, $body ) = $h =~ m/\A\$apr1\$([.\/0-9A-Za-z]{1,8})\$([.\/0-9A-Za-z]{22})\z/;
    ok( length( $salt ) >= 1 && length( $salt ) <= 8, 'salt length within [1..8]' );
    ok( length( $body ) == 22, 'encoded body is 22 chars' );

    my $alphabet = qr/[.\/0-9A-Za-z]/;
    ok( ( $salt =~ /\A$alphabet+\z/ ), 'salt chars in alphabet' );
    ok( ( $body =~ /\A$alphabet+\z/ ), 'body chars in alphabet' );
};

subtest 'determinism for fixed salt' => sub
{
    my $h1 = apr1_md5( 'secret', 'hfT7jp2q' );
    my $h2 = apr1_md5( 'secret', 'hfT7jp2q' );
    is( $h1, $h2, 'same password+salt => same hash' );
    like( $h1, qr/\A\$apr1\$hfT7jp2q\$[.\/0-9A-Za-z]{22}\z/, 'hash contains given salt' );
};

subtest 'verify positive/negative' => sub
{
    my $h = apr1_md5( 'opensesame', 'AB12.Cd/' );
    ok( verify_apr1( 'opensesame', $h ), 'verify succeeds on correct password' );
    ok( !verify_apr1( 'wrong',     $h ), 'verify fails on wrong password' );

    ok( !verify_apr1( 'opensesame', '$apr1$bad*salt$xxxxxxxxxxxxxxxxxxxxxx' ), 'rejects invalid salt chars' );
    ok( !verify_apr1( 'opensesame', '$apr1$short$too_short' ),                 'rejects invalid body length' );
};

subtest 'random salt uniqueness' => sub
{
    my %seen;
    my $collisions = 0;
    for( 1..50 )
    {
        # random salt
        my $h = apr1_md5( 'samepass' );
        my( $s ) = $h =~ /\A\$apr1\$([.\/0-9A-Za-z]{1,8})\$/;
        $collisions++ if( $seen{ $s }++ );
    }
    ok( $collisions == 0, 'no salt collisions in 50 samples (probabilistic)' );
};

subtest 'cross-check with Crypt::PasswdMD5 (if available)' => sub
{
    my @cases = (
        [ 'secret',    'hfT7jp2q' ],
        [ 'password',  'abcd1234' ],
        [ 'pässwörd',  'S1.Salt/' ],  # UTF-8 input
        [ '',          'emptyslt' ],  # empty password
    );

    SKIP:
    {
        skip( 'Crypt::PasswdMD5 not installed', scalar( @cases ) ) unless( $HAVE_REF );
        for my $c ( @cases )
        {
            my( $pw, $salt ) = @$c;
            my $mine = apr1_md5( $pw, $salt );
            my $ref  = Crypt::PasswdMD5::apache_md5_crypt( $pw, $salt );
            is( $mine, $ref, "matches reference for pw=[${pw}] salt=[$salt]" );
            ok( verify_apr1( $pw, $mine ), 'verify_apr1 accepts our own output' );
        }
    };
};

subtest 'bcrypt make + matches' => sub
{
    my $have_any = $have_bcrypt_crypt || $have_bcrypt_fallback;
    SKIP:
    {
        unless( $have_any )
        {
            skip( 'No bcrypt support via crypt() and no fallback modules installed', 1 );
        }

        my $pw = "correct horse battery staple";
        my $ht = $api->htpasswd( $pw, create => 1, algo => 'bcrypt', bcrypt_cost => $bcrypt_cost );
        ok( $ht, 'constructed bcrypt object' );

        my $hash = $ht->hash;
        like( $hash, qr/^\$2[aby]\$\d{2}\$[A-Za-z0-9.\/]{22}[A-Za-z0-9.\/]{31}\z/, 'bcrypt hash format' );

        ok( $ht->matches( $pw ), 'matches() true for bcrypt' );

        # Re-wrap existing hash and verify again
        my $ht2 = $api->htpasswd( $hash );
        ok( $ht2->matches( $pw ), 're-wrapped bcrypt hash verifies' );
    };
};

subtest 'sha256 ($5$) make + matches' => sub
{
    my $have_any = $have_sha256_crypt || $have_sha_fallback;
    SKIP:
    {
        unless( $have_any )
        {
            skip( 'No SHA-256 crypt support and no Crypt::Passwd::XS', 1 );
        }

        my $pw = "f0utr1qu&3t";
        my $ht = $api->htpasswd( $pw, create => 1, algo => 'sha256', sha_rounds => $sha_rounds );
        ok( $ht, 'constructed sha256 object' );

        my $hash = $ht->hash;
        like( $hash, qr/^\$5\$(?:rounds=\d+\$)?[A-Za-z0-9.\/]{1,16}\$[A-Za-z0-9.\/]+\z/, 'sha256 hash format' );

        ok( $ht->matches( $pw ), 'matches() true for sha256' );

        my $ht2 = $api->htpasswd( $hash );
        ok( $ht2->matches( $pw ), 're-wrapped sha256 hash verifies' );
    };
};

subtest 'sha512 ($6$) make + matches' => sub
{
    my $have_any = $have_sha512_crypt || $have_sha_fallback;
    SKIP:
    {
        unless( $have_any )
        {
            skip( 'No SHA-512 crypt support and no Crypt::Passwd::XS', 1 );
        }

        my $pw = "pässwörd with ütf8"; # UTF-8 input
        my $ht = $api->htpasswd( $pw, create => 1, algo => 'sha512', sha_rounds => $sha_rounds );
        ok( $ht, 'constructed sha512 object' );

        my $hash = $ht->hash;
        like( $hash, qr/^\$6\$(?:rounds=\d+\$)?[A-Za-z0-9.\/]{1,16}\$[A-Za-z0-9.\/]+\z/, 'sha512 hash format' );

        ok( $ht->matches( $pw ), 'matches() true for sha512' );

        my $ht2 = $api->htpasswd( $hash );
        ok( $ht2->matches( $pw ), 're-wrapped sha512 hash verifies' );
    };
};

done_testing();

__END__

