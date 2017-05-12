use ExtUtils::testlib;
use Test::More tests => 1;
use Crypt::SMimeEngine qw(&init &sign &verify &getFingerprint &getCertInfo &getErrStr &ossl_version &digest);

my $file = './t/files/testfile.bin';

my $schema = 'sha1';
my $fp_file_sha1 = 'c1a97e80ddf106ed23109ca8c2aed91928f75d72';

is( digest($file, $schema), $fp_file_sha1, 'digest(file, digest_schema)' );

