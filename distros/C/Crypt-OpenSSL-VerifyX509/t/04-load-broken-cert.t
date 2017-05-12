use Test::More;
use Crypt::OpenSSL::VerifyX509;
use Crypt::OpenSSL::X509;

my $v;
eval {
        $v = Crypt::OpenSSL::VerifyX509->new(__FILE__);
};
ok(!$v);

done_testing;
