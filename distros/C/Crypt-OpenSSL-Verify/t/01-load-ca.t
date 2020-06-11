use Test::More;
use Crypt::OpenSSL::Verify;

my $v = Crypt::OpenSSL::Verify->new('t/cacert.pem');
isa_ok($v, 'Crypt::OpenSSL::Verify');

$v = Crypt::OpenSSL::Verify->new(
    't/cacert.pem',
    {
        CApath   => '/etc/ssl/certs',
        noCAfile => 0,
    }
);
isa_ok($v, 'Crypt::OpenSSL::Verify');

done_testing;
