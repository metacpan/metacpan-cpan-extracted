use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

# not using Test::Fatal to keep dependencies to a minimum.
eval 'require Acme::DieOnLoad';

ok($@, 'got an exception when trying to load the module');
like($@, qr/I told you so/, 'the exception has the correct content');

done_testing;
