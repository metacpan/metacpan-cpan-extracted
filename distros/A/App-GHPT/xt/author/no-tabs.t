use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/gh-pt.pl',
    'lib/App/GHPT.pm',
    'lib/App/GHPT/Types.pm',
    'lib/App/GHPT/WorkSubmitter.pm',
    'lib/App/GHPT/WorkSubmitter/AskPullRequestQuestions.pm',
    'lib/App/GHPT/WorkSubmitter/ChangedFiles.pm',
    'lib/App/GHPT/WorkSubmitter/ChangedFilesFactory.pm',
    'lib/App/GHPT/WorkSubmitter/Question/ExampleFileNameCheck.pod',
    'lib/App/GHPT/WorkSubmitter/Role/FileInspector.pm',
    'lib/App/GHPT/WorkSubmitter/Role/Question.pm',
    'lib/App/GHPT/Wrapper/OurMoose.pm',
    'lib/App/GHPT/Wrapper/OurMoose/Role.pm',
    'lib/App/GHPT/Wrapper/OurMooseX/Role/Parameterized.pm',
    'lib/App/GHPT/Wrapper/OurMooseX/Role/Parameterized/Meta/Trait/Parameterizable/Strict.pm',
    'lib/App/GHPT/Wrapper/Ourperl.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/lib/App/GHPT/Wrapper/OurTest/Class/Moose.pm',
    't/lib/Helper/MockPTAPI.pm',
    't/lib/Helper/QuestionNamespace1/Question.pm',
    't/lib/Helper/QuestionNamespace2/Question.pm',
    't/lib/Helper/WorkSubmitter.pm',
    't/lib/TestFor/App/GHPT/WorkSubmitter.pm',
    't/lib/TestFor/App/GHPT/WorkSubmitter/AskPullRequestQuestions.pm',
    't/lib/TestFor/App/GHPT/WorkSubmitter/ChangedFiles.pm',
    't/lib/TestRole/WithGitRepo.pm',
    't/run-test-class-moose.t',
    't/test-data/not-committed-todelete',
    't/test-data/not-committed-tomodify',
    't/test-data/todelete1',
    't/test-data/todelete2',
    't/test-data/tomodify1',
    't/test-data/tomodify2'
);

notabs_ok($_) foreach @files;
done_testing;
