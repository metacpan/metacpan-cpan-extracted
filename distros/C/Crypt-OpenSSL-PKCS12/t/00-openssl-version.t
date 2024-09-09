use strict;
use warnings;
use Test::More;

use Crypt::OpenSSL::Guess qw/openssl_version/;

my ($major, $minor, $patch) = openssl_version();

ok($major, "Found OpenSSL version");
diag("OpenSSL version: $major.$minor $patch\n");

done_testing;
