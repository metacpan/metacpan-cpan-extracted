use Test::Most;
use if $ENV{RELEASE_TESTING}, 'Test::Warnings';

use_ok('Const::Exporter');

done_testing;
