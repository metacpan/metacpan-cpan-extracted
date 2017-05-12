use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Scalar::Util ();
use Acme::Version::Hex;

cmp_ok($Acme::Version::Hex::VERSION, '>', 0.0009, '$VERSION is similar to 0.001');

ok(Scalar::Util::looks_like_number($Acme::Version::Hex::VERSION), '$VERSION looks like a number');

ok(Scalar::Util::looks_like_number(Acme::Version::Hex->VERSION), 'VERSION() looks like a number');

done_testing;
