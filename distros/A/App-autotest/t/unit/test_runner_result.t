use Test::Spec;

use App::autotest::Test::Runner::Result;
use TAP::Parser::Aggregator;

use constant SOME_POSITIVE_INTEGER => 42;

describe 'a test runner result' => sub {
    it 'tells if there were failures' => sub {
        my $harness_result=TAP::Parser::Aggregator->new;
        $harness_result->stubs(failed => SOME_POSITIVE_INTEGER);

        my $result=App::autotest::Test::Runner::Result->new(
            harness_result => $harness_result);

        ok $result->has_failures;
    };
};

runtests unless caller;
