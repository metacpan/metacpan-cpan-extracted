use Test::More;
use Crypt::OpenSSL::VerifyX509;
use Crypt::OpenSSL::X509;

my $v = Crypt::OpenSSL::VerifyX509->new('t/cacert.pem');
isa_ok($v, 'Crypt::OpenSSL::VerifyX509');

my $ret;
eval {
        my $not_cert = 'foo!';
        $ret = $v->verify($not_cert);
};
ok($@ =~ /Crypt::OpenSSL::VerifyX509::verify/);
ok(!$ret);

done_testing;
