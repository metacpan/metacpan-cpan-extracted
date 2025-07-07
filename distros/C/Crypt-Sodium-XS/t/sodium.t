use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS ":all";

ok(sodium_version_string(), "sodium_version_string() returns true");
ok(SODIUM_VERSION_STRING, "constant SODIUM_VERSION_STRING is true");
ok(SODIUM_LIBRARY_VERSION_MAJOR, "constant SODIUM_LIBRARY_VERSION_MAJOR is true");
ok(SODIUM_LIBRARY_VERSION_MINOR, "constant SODIUM_LIBRARY_VERSION_MINOR is true");

done_testing();
