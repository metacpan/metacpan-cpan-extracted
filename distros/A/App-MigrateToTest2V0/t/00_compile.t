use strict;
use Test::More 0.98;

use_ok $_ for qw(
    App::MigrateToTest2V0
    App::MigrateToTest2V0::Rule
    App::MigrateToTest2V0::Rule::AvoidNameConflictWithTestDeep
    App::MigrateToTest2V0::Rule::ReplaceIsaOkHASHOrArrayToRefOk
    App::MigrateToTest2V0::Rule::ReplaceIsDeeplyToIs
    App::MigrateToTest2V0::Rule::ReplaceUseTestMoreToUseTest2V0
    App::MigrateToTest2V0::Rule::Translate2ndArgumentOfIsaOkWithArrayRef
    Test2::Plugin::Wrap2ndArgumentOfFailedCompareTestWithString
);

done_testing;

