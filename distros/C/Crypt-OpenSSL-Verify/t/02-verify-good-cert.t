use Test::More;
use Crypt::OpenSSL::Verify;
use Crypt::OpenSSL::X509;
use File::Slurp qw(read_file);

my $v = Crypt::OpenSSL::Verify->new('t/cacert.pem');
ok($v);

my $text = read_file('t/cert.pem');
like($text, qr/E1dSkFDk4Jix1M19WqRGMla8/);

my $cert = Crypt::OpenSSL::X509->new_from_string($text);
ok($cert);

my $ret = $v->verify($cert);
ok($ret);

$v = Crypt::OpenSSL::Verify->new(
    CAfile => 't/cacert.pem',
    CApath => '/etc/ssl/certs',
    noCAfile => 0,
    noStore => 0,
    );
ok($v);

$ret = $v->verify($cert);
ok($ret);

done_testing;
