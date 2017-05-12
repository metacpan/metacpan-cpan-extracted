use Test::Spec;

use constant A_TEST_WITH_FAILURES    => 'data/t/failing.t';
use constant A_TEST_WITHOUT_FAILURES => 'data/t/succeeding.t';

use App::autotest;

describe 'autotest' => sub {
  describe 'tells that things just got better' => sub {
    it 'if we go from red to green' => sub {
      my $autotest = App::autotest->new;
      $autotest->run_tests(A_TEST_WITH_FAILURES);
      $autotest->expects('print')->with("Things just got better.\n");
      $autotest->run_tests(A_TEST_WITHOUT_FAILURES);

      ok 1; # expectation doesn't count as test
    };
  };
  describe 'will not tell that things just got better' => sub {
    it 'if we stay red' => sub {
      my $autotest = App::autotest->new;
      $autotest->run_tests(A_TEST_WITH_FAILURES);
      $autotest->expects('print')->never;
      $autotest->run_tests(A_TEST_WITH_FAILURES);
      ok 1; # expectation doesn't count as test
    };
    it 'if we go from green to green' => sub {
      my $autotest = App::autotest->new;
      $autotest->run_tests(A_TEST_WITHOUT_FAILURES);
      $autotest->expects('print')->never;
      $autotest->run_tests(A_TEST_WITHOUT_FAILURES);
      ok 1; # expectation doesn't count as test
    };
    it 'if we go from green to red' => sub {
      my $autotest = App::autotest->new;
      $autotest->run_tests(A_TEST_WITHOUT_FAILURES);
      $autotest->expects('print')->never;
      $autotest->run_tests(A_TEST_WITHOUT_FAILURES);
      ok 1; # expectation doesn't count as test
    };
  };
};
runtests unless caller;
