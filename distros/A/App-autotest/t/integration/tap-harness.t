use Test::Spec;

use TAP::Harness;

use constant A_FAILING_TEST => 'data/t/failing.t'; 

describe 'a TAP::Harness' => sub {
  it "returns a TAP::Parser::Aggregator when calling 'runtests'" => sub {
    my $result = a_silent_tap_harness()->runtests();
    isa_ok $result, 'TAP::Parser::Aggregator';
  };
};

describe 'a TAP::Parser::Aggregator' => sub {
  it "returns the number of failed tests when calling 'failed'" => sub {
    my $result = a_silent_tap_harness()->runtests(A_FAILING_TEST);
    is $result->failed, 1;
  };
};

sub a_silent_tap_harness { TAP::Harness->new({verbosity => -3}) }

runtests unless caller;
