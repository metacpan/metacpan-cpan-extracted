# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 20-versions.t'

#########################

use Test;
use ExtUtils::testlib;
use Crypt::GCrypt;

#########################
BEGIN { plan tests => 3 }; # <--- number of tests;


my $g = Crypt::GCrypt::gcrypt_version();
my $x = Crypt::GCrypt::built_against_version();

warn sprintf("gcrypt version: %s\n built against: %s\n", $g, $x);

ok($g);
ok($x);

# since this is presumably being run at build time, we expect these
# versions to be the same.  Note that in a running environment, it
# might be possible for gcrypt to be a newer version than the version
# the package was built against. (i.e. the admin might have upgraded
# libgcrypt without rebuilding Crypt::GCrypt)

ok($g eq $x);
