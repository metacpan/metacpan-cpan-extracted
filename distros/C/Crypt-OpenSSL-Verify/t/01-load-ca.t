use Test::More;
use Crypt::OpenSSL::Verify;

my $v = Crypt::OpenSSL::Verify->new('t/cacert.pem');
ok($v);

my $v = Crypt::OpenSSL::Verify->new(
    CAfile => 't/cacert.pem',
    CApath => '/etc/ssl/certs',
    noCAfile => 0,
    noStore => 0,
    );
ok($v);

done_testing;
