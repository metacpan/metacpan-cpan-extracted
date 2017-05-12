use strict;
use warnings;

use Test::More tests => 8;

use Data::Remember Hybrid =>
    []           => 'Memory',
    [ 'x' ]      => 'Memory',
    [ 'y' ]      => 'Memory',
    [ 'x', 'z' ] => 'Memory',
    ;

remember foo => 1;
remember [ x => 'foo' ] => 2;
remember [ y => 'foo' ] => 3;
remember [ x => z => 'foo' ] => 4;

is(brain->brain_for()->recall([ 'foo' ]), 1);
is(brain->brain_for('foo')->recall([ 'foo' ]), 1);

is(brain->brain_for('x')->recall([ 'foo' ]), 2);
is(brain->brain_for([ 'x', 'foo' ])->recall([ 'foo' ]), 2);

is(brain->brain_for('y')->recall([ 'foo' ]), 3);
is(brain->brain_for([ 'y', 'foo' ])->recall([ 'foo' ]), 3);

is(brain->brain_for([ 'x', 'z' ])->recall([ 'foo' ]), 4);
is(brain->brain_for([ 'x', 'z', 'foo' ])->recall([ 'foo' ]), 4);
