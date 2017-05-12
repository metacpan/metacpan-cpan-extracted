use Test::More;
use Crypt::OpenSSL::VerifyX509;
use Crypt::OpenSSL::X509;

my $v = Crypt::OpenSSL::VerifyX509->new('t/cacert.pem');
ok($v);

my $ret;
eval {
        my $not_cert = 'foo!';
        $ret = $v->verify($not_cert);
};
ok($@ =~ /x509 is not of type Crypt::OpenSSL::X509/);
ok(!$ret);

done_testing;
