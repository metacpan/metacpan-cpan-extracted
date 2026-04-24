use strict;
use Test::More;

use Crypt::OpenSSL::RSA;

$INC{'Crypt/OpenSSL/Bignum.pm'}
  ? plan( tests    => 64 )
  : plan( skip_all => "Crypt::OpenSSL::Bignum required for bignum tests" );

my @PARAM_NAMES = qw(n e d p q dmp1 dmq1 iqmp);

sub check_datum {
    my ( $p_expected, $p_actual, $name ) = @_;
    if ( defined($p_expected) ) {
        ok( $p_actual && $p_expected->equals($p_actual), $name );
    }
    else {
        is( $p_actual, undef, $name );
    }
}

sub check_key_parameters    # runs 8 tests
{
    my ( $p_rsa, $label, $n, $e, $d, $p, $q, $dmp1, $dmq1, $iqmp ) = @_;
    my ( $rn, $re, $rd, $rp, $rq, $rdmp1, $rdmq1, $riqmp ) = $p_rsa->get_key_parameters();

    my @expected = ( $n, $e, $d, $p, $q, $dmp1, $dmq1, $iqmp );
    my @actual   = ( $rn, $re, $rd, $rp, $rq, $rdmp1, $rdmq1, $riqmp );

    for my $i ( 0 .. 7 ) {
        check_datum( $expected[$i], $actual[$i],
            "$label: $PARAM_NAMES[$i] matches expected" );
    }
}

{
    my $ctx  = Crypt::OpenSSL::Bignum::CTX->new();
    my $one  = Crypt::OpenSSL::Bignum->one();
    my $p    = Crypt::OpenSSL::Bignum->new_from_word(65521);
    my $q    = Crypt::OpenSSL::Bignum->new_from_word(65537);
    my $e    = Crypt::OpenSSL::Bignum->new_from_word(11);
    my $d    = $e->mod_inverse( $p->sub($one)->mul( $q->sub($one), $ctx ), $ctx );
    my $n    = $p->mul( $q, $ctx );
    my $dmp1 = $d->mod( $p->sub($one), $ctx );
    my $dmq1 = $d->mod( $q->sub($one), $ctx );
    my $iqmp = $q->mod_inverse( $p, $ctx );

    my $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters( $n, $e, $d, $p, $q );
    ok( $rsa, "new_key_from_parameters(n,e,d,p,q) returns an object" );

    $rsa->use_no_padding();

    my $plaintext  = pack( 'C*', 100, 100, 100, 12 );
    my $ciphertext = Crypt::OpenSSL::Bignum->new_from_bin($plaintext)->mod_exp( $e, $n, $ctx )->to_bin();
    check_key_parameters( $rsa, "full key", $n, $e, $d, $p, $q, $dmp1, $dmq1, $iqmp );

    is( $rsa->encrypt($plaintext), $ciphertext, "encrypt produces expected ciphertext" );
    is( $rsa->decrypt($ciphertext), $plaintext, "decrypt recovers original plaintext" );

    my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key( $rsa->get_public_key_string() );

    $rsa_pub->use_no_padding();
    is( $rsa->private_encrypt($ciphertext), $plaintext, "private_encrypt produces expected plaintext" );
    is( $rsa_pub->public_decrypt($plaintext), $ciphertext, "public_decrypt produces expected ciphertext" );

    my @pub_parameters = $rsa_pub->get_key_parameters();
    is( scalar(@pub_parameters), 8, "public key returns 8 parameters" );

    check_key_parameters( $rsa_pub, "public key", $n, $e );

    $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters( $n, $e, $d, $p );
    check_key_parameters( $rsa, "from (n,e,d,p)", $n, $e, $d, $p, $q, $dmp1, $dmq1, $iqmp );

    $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters( $n, $e, $d, undef, $q );
    check_key_parameters( $rsa, "from (n,e,d,undef,q)", $n, $e, $d, $p, $q, $dmp1, $dmq1, $iqmp );

    $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters( $n, $e );
    check_key_parameters( $rsa, "from (n,e)", $n, $e );

    $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters( $n, $e, $d );
    check_key_parameters( $rsa, "from (n,e,d)", $n, $e, $d );

    $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters( $n, $e, undef, $p );
    check_key_parameters( $rsa, "from (n,e,undef,p)", $n, $e, $d, $p, $q, $dmp1, $dmq1, $iqmp );

    eval {
        Crypt::OpenSSL::RSA->new_key_from_parameters(
            $n->sub( Crypt::OpenSSL::Bignum->one() ),
            $e, $d, undef, $q
        );
    };
    like( $@, qr/OpenSSL error: (?:p not prime|d e not congruent to 1)/, "bad n with q triggers key validation error" );

    #try again, to make sure the error queue was properly flushed
    eval {
        Crypt::OpenSSL::RSA->new_key_from_parameters(
            $n->sub( Crypt::OpenSSL::Bignum->one() ),
            $e, $d, undef, $q
        );
    };
    like( $@, qr/OpenSSL error: (?:p not prime|d e not congruent to 1)/, "error queue flushed: repeat triggers same error" );
}
