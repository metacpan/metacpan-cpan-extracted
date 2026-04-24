use strict;
use Test::More;

use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;

Crypt::OpenSSL::Random::random_seed("OpenSSL needs at least 32 bytes.");
Crypt::OpenSSL::RSA->import_random_seed();

my $HAS_BIGNUM = $INC{'Crypt/OpenSSL/Bignum.pm'} ? 1 : 0;

$HAS_BIGNUM
    ? plan( tests => 9 )
    : plan( skip_all => "Crypt::OpenSSL::Bignum required for check_param tests" );

my $rsa = Crypt::OpenSSL::RSA->generate_key(2048);
my ( $n, $e, $d, $p, $q ) = $rsa->get_key_parameters();

# 1. check=>1 with valid full params — should succeed
{
    my $key = eval {
        Crypt::OpenSSL::RSA->new_key_from_parameters(
            $n, $e, $d, $p, $q, check => 1
        );
    };
    ok( !$@, "check=>1 with valid params does not croak" )
        or diag("Error: $@");
    ok( $key && $key->is_private(), "check=>1 returns valid private key" );
}

# 2. check=>1 with public-only key — should succeed (check skipped)
{
    my $key = eval {
        Crypt::OpenSSL::RSA->new_key_from_parameters(
            $n, $e, undef, undef, undef, check => 1
        );
    };
    ok( !$@, "check=>1 with public-only key does not croak" )
        or diag("Error: $@");
    ok( $key && !$key->is_private(), "check=>1 returns public key without validation" );
}

# 3. check=>1 with bad d — should croak
{
    my $bad_d = Crypt::OpenSSL::Bignum->new_from_word(12345);
    eval {
        Crypt::OpenSSL::RSA->new_key_from_parameters(
            $n, $e, $bad_d, $p, $q, check => 1
        );
    };
    ok( $@, "check=>1 with bad d croaks" );
    like( $@, qr/(?:check failed|OpenSSL error)/i,
        "error message mentions check failure or OpenSSL error" );
}

# 4. Without check option — no extra validation at Perl level
{
    my $key = eval {
        Crypt::OpenSSL::RSA->new_key_from_parameters( $n, $e, $d, $p, $q );
    };
    ok( !$@, "without check option, valid params succeed as before" );
}

# 5. check_key() returns exactly 1, not just truthy
# OpenSSL's RSA_check_key/EVP_PKEY_private_check can return -1 on error,
# which is truthy in Perl.  The XS code must normalize to 0/1.
{
    cmp_ok( $rsa->check_key(), '==', 1,
        "check_key returns exactly 1 for valid key (not raw OpenSSL int)" );
    ok( ref(\($rsa->check_key())) ne 'GLOB',
        "check_key returns a plain scalar" );
}
