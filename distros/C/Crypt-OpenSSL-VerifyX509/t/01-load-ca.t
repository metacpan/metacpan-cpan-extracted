use Test::More;
use Crypt::OpenSSL::VerifyX509;

my $v = Crypt::OpenSSL::VerifyX509->new('t/cacert.pem');
ok($v);

done_testing;
