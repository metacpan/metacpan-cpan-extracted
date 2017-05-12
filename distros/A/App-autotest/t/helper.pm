use App::autotest;
use TAP::Harness;
use TAP::Parser::Aggregator;

use Test::Differences;
use Cwd;

use constant TEST_PROGRAMS_DIRECTORY => 't/t';
use constant A_TEST_PROGRAM          => 't/t/1.t';
use constant ANOTHER_TEST_PROGRAM    => 't/t/2.t';
use constant SOME_TEST_PROGRAMS => [ A_TEST_PROGRAM, ANOTHER_TEST_PROGRAM ];

use constant AN_AFTER_CHANGE_OR_NEW_HOOK_THAT_EXISTS_IMMEDIATELY => sub { 1 };

sub an_autotest { return App::autotest->new }

sub an_autotest_that_just_checks_once_for_changed_or_new_files {
    my $autotest = an_autotest();
    $autotest->after_change_or_new_hook(
        AN_AFTER_CHANGE_OR_NEW_HOOK_THAT_EXISTS_IMMEDIATELY);
    return $autotest;
}

sub a_harness { return TAP::Harness->new }

sub a_harness_not_running_the_tests {
  my $harness=a_harness();
  $harness->expects('runtests');
  return $harness;
}

sub a_tap_parser_aggregator { TAP::Parser::Aggregator->new };

1;
