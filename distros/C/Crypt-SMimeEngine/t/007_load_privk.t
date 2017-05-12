use ExtUtils::testlib;
use Test::More tests => 2;
use Crypt::SMimeEngine qw(&init &sign &verify &getFingerprint &getCertInfo &getErrStr &ossl_version &load_privk);

my $cert_dir = './t/certs';
my $cert = './t/certs/cert.pem';
my $key = './t/certs/key.pem';
my $other_cert = [];

my $mail_in = './t/mail/mail.txt';
my $mail_out= './t/mail/mail.txt.signed';

is( init($cert_dir, $cert, $key, $other_cert, 'openssl',undef), 0, 'init()' );
is( load_privk($key, $cert), 0, 'load_privk(key, cert)' );
