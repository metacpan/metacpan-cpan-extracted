#!perl

use Test::Cmd;
use Test::Most tests => 6;

my $deeply = \&eq_or_diff;

my $test_prog = './varionator';
my $tc        = Test::Cmd->new(
  interpreter => $^X,
  prog        => $test_prog,
  verbose     => 0,            # TODO is there a standard ENV to toggling?
  workdir     => '',
);

$tc->run( args => 'I V' );
$deeply->( [ map { s/\s+$//r } $tc->stdout ], ['I V'], "$test_prog I V" );
is( $tc->stderr, "", "$test_prog I V emits no stderr" );

$tc->run( args => 'I "(II IV)"' );
$deeply->(
  [ map { s/\s+$//r } $tc->stdout ],
  [ 'I II', 'I IV' ],
  "$test_prog I '(II IV)'"
);
is( $tc->stderr, "", "$test_prog I '(II IV)' emits no stderr" );

$tc->run( args => 'c "(d f a)" "(g e b)" c' );
$deeply->(
  [ map { s/\s+$//r } $tc->stdout ],
  [ 'c d g c', 'c d e c', 'c d b c', 'c f g c', 'c f e c', 'c f b c',
    'c a g c', 'c a e c', 'c a b c',
  ]
);
is( $tc->stderr, "", "$test_prog I '(d f a)' '(g e b)' c emits no stderr" );
