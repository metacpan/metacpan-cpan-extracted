use ExtUtils::testlib;
use Test::More tests => 1;
use Crypt::SMimeEngine qw(&init &sign &verify &getFingerprint &getCertInfo &getErrStr &ossl_version);

my $cert = './t/certs/cert.pem';

is( ref(getCertInfo($cert)), 'HASH', 'getCertInfo(certificate)' );
