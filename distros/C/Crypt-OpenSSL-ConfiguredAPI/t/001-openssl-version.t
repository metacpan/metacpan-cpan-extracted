use Test::More;
use Crypt::OpenSSL::Guess;
my ($major, $minor, $patch) = openssl_version();
print STDERR "\t\tOpenSSL Version $major$minor$patch\t\n";
ok ($major);

done_testing;
