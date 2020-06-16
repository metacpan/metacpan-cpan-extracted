use Test::More;
use Crypt::OpenSSL::Verify;
use Crypt::OpenSSL::X509;

my $v = Crypt::OpenSSL::Verify->new('t/cacert.pem');
isa_ok($v, 'Crypt::OpenSSL::Verify');

my $ret;
eval {
    my $not_cert = 'foo!';
    $ret = $v->verify($not_cert);
};
ok($@ =~ /x509 is not of type Crypt::OpenSSL::X509/);
ok(!$ret);

$v = Crypt::OpenSSL::Verify->new(
    't/cacert.pem',
    {
        CApath   => '/etc/ssl/certs',
        noCAfile => 0,
    }
);
isa_ok($v, 'Crypt::OpenSSL::Verify');

$ret = undef;

eval {
    my $not_cert = 'foo!';
    $ret = $v->verify($not_cert);
};
ok($@ =~ /x509 is not of type Crypt::OpenSSL::X509/);
ok(!$ret);

done_testing;
