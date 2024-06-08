#!/usr/bin/env perl

use Test::More;
use HTTP::Status    qw(HTTP_OK);

use lib 'lib', 't';

use Couch::DB::Util qw(:all);

use Test;
use DateTime ();

#$dump_answers = 1;
#$dump_values  = 1;
#$trace = 1;

### flat

is_deeply [ flat ],       [ ], 'empty';
is_deeply [ flat undef ], [ ], 'undef';
is_deeply [ flat 1 ],     [ 1 ], 'one';
is_deeply [ flat undef, 1 ], [ 1 ], '...';
is_deeply [ flat 1, undef ], [ 1 ], '...';
is_deeply [ flat undef, 1, undef ], [ 1 ], '...';

is_deeply [ flat 1, 2 ],      [ 1, 2 ], 'two';
is_deeply [ flat [ ] ],       [ ], 'empty array';
is_deeply [ flat [ undef ] ], [ ], 'array undef';

is_deeply [ flat [ 1 ] ],        [ 1 ], 'array one ';
is_deeply [ flat [ 1, undef ] ], [ 1 ], '... ';
is_deeply [ flat [ undef, 1 ] ], [ 1 ], '... ';

is_deeply [ flat 1, [ 2, 3, 4], 5 ], [1..5], 'combined';

### pile

is_deeply pile(), [ ], 'pile empty';
is_deeply pile(undef), [ ], 'pile undef';
is_deeply pile(1,2,3), [ 1, 2, 3 ], 'pile 3';
is_deeply pile([0, 1],2,3), [ 0, 1, 2, 3 ], 'pile 0';
is_deeply pile(1,2,[3, 4]), [ 1, 2, 3, 4 ], 'pile 4';

### apply_tree

is_deeply apply_tree(undef, sub { $_[0] }),  undef, '... undef';
is_deeply apply_tree(42,    sub { - $_[0] }),  -42, '... single';
is_deeply apply_tree({},    sub {     742 }),   {}, '... single';

is_deeply apply_tree
  ( { a =>  1, b =>  2, c => [ { d =>  3, e =>  4 },  5,  6 ], f => [ ], g => { } }, sub { $_[0] + 10 } ),
    { a => 11, b => 12, c => [ { d => 13, e => 14 }, 15, 16 ], f => [ ], g => { } }, "... complex tree";


### simplified

my $dt = DateTime->now;
my $dts = "DATETIME($dt)";

is_deeply simplified(scalar    => 42), <<'__SCALAR', 'simplified scalar';
$scalar = 42;
__SCALAR

is_deeply simplified(dt_scalar => $dt), <<__DT, 'single element';
\$dt_scalar = '$dts';
__DT

is_deeply simplified(dt_array  => [1, $dt, 3]), <<__ARRAY, 'in array';
\$dt_array = [
  1,
  '$dts',
  3
];
__ARRAY

is_deeply simplified(dt_hash   => {a => 1, b => $dt, c => 3}), <<__HASH, 'in hash';
\$dt_hash = {
  a => 1,
  b => '$dts',
  c => 3
};
__HASH

done_testing;
