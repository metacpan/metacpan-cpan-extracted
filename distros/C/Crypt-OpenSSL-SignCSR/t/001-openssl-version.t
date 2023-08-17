use Test::More;
use Crypt::OpenSSL::Guess;
my ($major, $minor, $patch) = openssl_version();
print STDERR "\tOpenSSL Version $major$minor$patch";
ok ($major);

done_testing;
