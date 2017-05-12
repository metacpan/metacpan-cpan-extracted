#!perl

use Test::Cmd;
use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

my $test_prog = './harmonic-fit';
my $tc        = Test::Cmd->new(
  interpreter => $^X,
  prog        => $test_prog,
  verbose     => 0,            # TODO is there a standard ENV to toggling?
  workdir     => '',
);

my @tests = (
  { args => 'c g',
    expected =>
      [ "84\tc", "27\tg", "8\tf", "8\tais", "1\tcis", "1\tdis", "1\tgis" ],
  },
);

plan tests => @tests * 2;

for my $test (@tests) {
  $tc->run( args => $test->{args} );
  $deeply->(
    [ map { s/\s+$//r } split "\n", $tc->stdout ],
    $test->{expected}, "$test_prog $test->{args}"
  );
  is( $tc->stderr, "", "$test_prog $test->{args} emits no stderr" );
}
