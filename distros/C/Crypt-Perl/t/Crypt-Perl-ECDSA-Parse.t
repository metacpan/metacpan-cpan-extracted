package t::Crypt::Perl::ECDSA::Parse;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use Try::Tiny;

use FindBin;

use lib "$FindBin::Bin/lib";
use OpenSSL_Control ();

use Test::More;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use Crypt::Format ();
use Digest::SHA ();
use File::Slurp ();
use File::Temp ();

use parent qw( TestClass );

use lib "$FindBin::Bin/../lib";

use Crypt::Perl::ECDSA::Parse ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test_pkcs8_private : Tests(1) {
    my ($self) = @_;

    my $plain = File::Slurp::read_file("$FindBin::Bin/assets/prime256v1.key");
    my $pkcs8 = File::Slurp::read_file("$FindBin::Bin/assets/prime256v1.prkey");

    $_ = Crypt::Perl::ECDSA::Parse::private($_) for ($pkcs8, $plain);

    is_deeply(
        $pkcs8,
        $plain,
        'PKCS8 key parsed the same as a regular one',
    );

    return;
}

sub test_public : Tests(1) {
    my ($self) = @_;

    my $key_path = "$FindBin::Bin/assets/prime256v1.key.public";

    my $pem = File::Slurp::read_file($key_path);

    my $obj = Crypt::Perl::ECDSA::Parse::public($pem);

    isa_ok(
        $obj,
        'Crypt::Perl::ECDSA::PublicKey',
        'public() return',
    ) or diag explain $obj;

    return;
}

sub test_jwk_private : Tests(1) {

    my ($pr_jwk) = {
        kty => 'EC',
        crv => 'P-384',
        x => '7r2u_ZkCnSjowORDMgnqWvI1A9HQ6CH06LIAaftFO2iYYazSICi-HoH_M2tBn4fR',
        y => 'ouVhCnZ-g4E8aVqgJcqmIdiGZIN8qlqWG9K8wvFKWvUbSI561j_WXuKH3cBp0ewq',
        d => '5ITbOa5Bw3lhq5doenNkZ-JcJVT0e4sWQpdtfo-5et9-Bqx8qQv8T9T1wS-jCZB2',
    };

    my $pr_pem = <<END;
-----BEGIN EC PRIVATE KEY-----
MIGkAgEBBDDkhNs5rkHDeWGrl2h6c2Rn4lwlVPR7ixZCl21+j7l6334GrHypC/xP
1PXBL6MJkHagBwYFK4EEACKhZANiAATuva79mQKdKOjA5EMyCepa8jUD0dDoIfTo
sgBp+0U7aJhhrNIgKL4egf8za0Gfh9Gi5WEKdn6DgTxpWqAlyqYh2IZkg3yqWpYb
0rzC8Upa9RtIjnrWP9Ze4ofdwGnR7Co=
-----END EC PRIVATE KEY-----
END

    my $from_jwk = Crypt::Perl::ECDSA::Parse::jwk($pr_jwk);
    my $from_pem = Crypt::Perl::ECDSA::Parse::private($pr_pem);

    is_deeply( $from_jwk, $from_pem, 'from JWK is identical to from PEM' );
    return;
}

sub test_jwk_public : Tests(1) {

    my ($jwk) = {
        kty => 'EC',
        crv => 'P-384',
        x => '7r2u_ZkCnSjowORDMgnqWvI1A9HQ6CH06LIAaftFO2iYYazSICi-HoH_M2tBn4fR',
        y => 'ouVhCnZ-g4E8aVqgJcqmIdiGZIN8qlqWG9K8wvFKWvUbSI561j_WXuKH3cBp0ewq',
    };

    my $pb_pem = <<END;
-----BEGIN PUBLIC KEY-----
MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAE7r2u/ZkCnSjowORDMgnqWvI1A9HQ6CH0
6LIAaftFO2iYYazSICi+HoH/M2tBn4fRouVhCnZ+g4E8aVqgJcqmIdiGZIN8qlqW
G9K8wvFKWvUbSI561j/WXuKH3cBp0ewq
-----END PUBLIC KEY-----
END

    my $from_jwk = Crypt::Perl::ECDSA::Parse::jwk($jwk);
    my $from_pem = Crypt::Perl::ECDSA::Parse::public($pb_pem);

    is_deeply( $from_jwk, $from_pem, 'from JWK is identical to from PEM' );
    return;
}

1;
