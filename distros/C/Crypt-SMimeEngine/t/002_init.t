use ExtUtils::testlib;
use Test::More tests => 1;
use Crypt::SMimeEngine qw(&init &sign &verify &getFingerprint &getCertInfo &getErrStr &ossl_version);

my $cert_dir = './t/certs';
my $cert = './t/certs/cert.pem';
my $key = './t/certs/key.pem';
my $other_cert = [];


is( init($cert_dir, $cert, $key, $other_cert, 'openssl',undef), 0, 'init()' );
