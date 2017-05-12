#!perl

use Test::Cmd;
use Test::Most;

my $deeply = \&eq_or_diff;

my $test_prog = './scalemogrifier';
my $tc        = Test::Cmd->new(
  interpreter => $^X,
  prog        => $test_prog,
  verbose     => 0,            # TODO is there a standard ENV to toggling?
  workdir     => '',
);

my @tests = (
  { args     => '',
    expected => q{c d e f g a b c'},
  },
  { args     => '--mode=minor --transpose=a',
    expected => q{a b c d e f g a'},
  },
  { args     => '--raw',
    expected => q{0 2 4 5 7 9 11 12},
  },
);

plan tests => @tests * 2;

for my $test (@tests) {
  $tc->run( args => $test->{args} );
  $deeply->(
    [ map { s/\s+$//r } $tc->stdout ],
    [ $test->{expected} ],
    "$test_prog $test->{args}"
  );
  is( $tc->stderr, "", "$test_prog $test->{args} emits no stderr" );
}
