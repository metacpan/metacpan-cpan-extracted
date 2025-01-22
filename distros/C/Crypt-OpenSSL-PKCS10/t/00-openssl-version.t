use strict;
use warnings;
use Test::More;

use Crypt::OpenSSL::Guess qw/openssl_version find_openssl_prefix find_openssl_exec/;

my ($major, $minor, $patch) = openssl_version();

$patch = defined $patch ? $patch : "";

ok($major, "Found OpenSSL version");
#diag("OpenSSL version: $major.$minor $patch\n");

my $prefix = find_openssl_prefix();
my $ssl_exec = find_openssl_exec($prefix);

my $ssl_version_string = `$ssl_exec version`;

diag(`$ssl_exec version`);

done_testing;
