use ExtUtils::testlib;
use Test::More tests => 1;
use Crypt::SMimeEngine qw(&init &sign &verify &getFingerprint &getCertInfo &getErrStr &ossl_version);

my $cert = './t/certs/cert.pem';

my $schema = 'sha1';
my $fp_cert_sha1 = 'BB:21:EA:32:E9:0C:37:F5:AC:7E:B1:B3:11:EF:55:24:59:85:CF:7A';

is( getFingerprint($cert, $schema), $fp_cert_sha1, 'getFingerprint(certificate, hash_schema)' );
