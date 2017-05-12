use Test::Spec;

use App::autotest::Test::Runner::Result::History;

describe 'a test runner result history' => sub {
  it 'shifts current to last result when perpetuating' => sub {
    my $result = a_result();
    my $history = a_history( current_result => $result );

    $history->perpetuate( a_result() );

    is $history->last_result, $result;
  };

  it 'stores new result as current when perpetuating' => sub {
    my $history = a_history( current_result => a_result() );

    my $new_result = a_result();
    $history->perpetuate($new_result);

    is $history->current_result, $new_result;
  };

  it 'tells if things just got better' => sub {
    my $a_result_with_failures=a_result();
    $a_result_with_failures->stubs(has_failures => 1);

    my $a_result_without_failures=a_result();
    $a_result_without_failures->stubs(has_failures => 0);

    my $history = a_history(
      last_result    => $a_result_with_failures,
      current_result => $a_result_without_failures
    );
    ok $history->things_just_got_better;
  };

  it 'does not claim thing got better if we have no last result' => sub {
    my $a_result_without_failures=a_result();
    $a_result_without_failures->stubs(has_failures => 0);

    my $history = a_history(
      current_result => $a_result_without_failures
    );

    ok not $history->things_just_got_better;
  };
};

sub a_history { App::autotest::Test::Runner::Result::History->new(@_) }

sub a_result { App::autotest::Test::Runner::Result->new }

runtests unless caller;
