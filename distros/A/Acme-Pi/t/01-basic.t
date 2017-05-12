use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Acme::Pi;
use version;

ok(version::is_lax(Acme::Pi->VERSION), "is_lax: $Acme::Pi::VERSION");

done_testing;
