use Test::Spec;

use App::autotest;
use App::autotest::Test::Runner;

describe 'an autotest' => sub {
  describe 'calling run_tests' => sub {
    it 'uses the test runner' => sub {
      my $test_runner = a_test_runner();
      $test_runner->expects('run');

      my $autotest = an_autotest( test_runner => $test_runner );

      is $autotest->test_runner, $test_runner;
      $autotest->run_tests;
    };

    it 'perpetuates history using the test result' => sub {
      my $result = a_test_result();

      my $test_runner = a_test_runner();
      $test_runner->stubs( run => $result );

      my $history = a_history();
      $history->expects('perpetuate')->with($result);

      my $autotest = an_autotest(
        test_runner => $test_runner,
        history     => $history
      );

      $autotest->run_tests;
    };

    it 'asks the history if things just got better' => sub {
      my $history = a_history();
      $history->expects('things_just_got_better');

      my $autotest = an_autotest( history => $history );

      $autotest->run_tests;
    };
  };
};

sub a_history { App::autotest::Test::Runner::Result::History->new(@_) }

sub a_test_result { App::autotest::Test::Runner::Result->new(@_) }

sub a_test_runner { App::autotest::Test::Runner->new(@_) }

sub an_autotest { App::autotest->new(@_) }

runtests unless caller;
