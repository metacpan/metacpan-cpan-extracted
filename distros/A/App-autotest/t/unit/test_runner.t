use Test::Spec;
use File::Basename qw(dirname);

use App::autotest::Test::Runner;

describe 'a test runner' => sub {
    it 'returns a result after running the tests' => sub {
        my $test_runner = a_test_runner();
        my $result      = $test_runner->run();
        isa_ok( $result, 'App::autotest::Test::Runner::Result' );
    };

    it 'tells if there were failures' => sub {
        my $result = a_test_runner_result_indicating_failures();
        my $runner = a_test_runner(result => $result);

        ok $runner->had_failures;
    };
};

sub a_test_runner { App::autotest::Test::Runner->new(@_) }

sub a_test_runner_result_indicating_failures {
    my $result = App::autotest::Test::Runner::Result->new;
    $result->stubs( has_failures => 1 );
    return $result;
}

runtests unless caller;
