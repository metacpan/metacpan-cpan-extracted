#!perl -w

use strict;

use Array::GroupBy qw(str_row_equal num_row_equal);

use Test::More tests => 22;

my $a1 = ['a', 'b', 'c'];
my $a2 = ['a', 'b', 'c'];
my $a3 = ['a', 'x', 'c'];

my $b1 = ['a', 'b'     ];

my $c1 = ['a', undef, 'c'];
my $c2 = ['a', undef, 'c'];

my $n1 = [ 1,   2,   3,   4   ];
my $n2 = [ qw(1.0 2.0 3.0 4.0) ];
my $n3 = [ 1.0, 2.0, 3.0, 4.01 ];

my $m1 = [ 1, 2, 3, 4, 5];

my $p1 = [ undef,   2,   undef,   4   ];
my $p2 = [ undef,   2,   undef,   4   ];

is ( str_row_equal($a1, $b1), 0, 'unequal length str arrays');
is ( num_row_equal($n1, $m1), 0, 'unequal length num arrays');

is ( str_row_equal($a1, $a2), 1, 'equal str arrays, all members defined');
is ( str_row_equal($a1, $a3), 0, 'non-equal str arrays, all members defined');

is ( num_row_equal($n1, $n2), 1, 'equivalent num arrays, all members defined');
is ( num_row_equal($n1, $n3), 0, 'non-equivalent num arrays, all members defined');

is ( str_row_equal($c1, $c2), 1, 'equal str arrays, a member undef & undef');
is ( str_row_equal($a1, $c2), 0, 'str array member undef & def');
is ( str_row_equal($c1, $a1), 0, 'str array member def & undef');

is ( num_row_equal($p1, $p2), 1, 'equal num arrays, a member undef & undef');
is ( num_row_equal($p1, $n2), 0, 'equal num arrays, a member def & undef');
is ( num_row_equal($n1, $p2), 0, 'equal num arrays, a member undef & def');

my $s = [0, 2]; #slice

is ( str_row_equal($a1, $a2, $s), 1, 'equal sliced str arrays, all members defined');
is ( str_row_equal($a1, $c1, $s), 1, 'sliced str array undef member excluded');

$s = [1, 3];
is ( num_row_equal($n1, $n2, $s), 1, 'equal sliced num arrays, all members defined');
is ( num_row_equal($n1, $p1, $s), 1, 'sliced num array undef member excluded');

$s = [0, 1];
is ( str_row_equal($a1, $c1, $s), 0, 'sliced str array undef member included');

is ( num_row_equal($n1, $p1, $s), 0, 'sliced num array undef member included');

$s = [0, 4];
is ( str_row_equal($a1, $a2, $s), 0, 'slice out of range');

$s = [];
is ( str_row_equal($a1, $a2, $s), 1, 'null slice');

# use str- routine on numbers
is ( str_row_equal($n1, $n2), 0, 'string comparison of unequal numeric data');
is ( str_row_equal($n1, $n1), 1, 'string comparison of equal numeric data');

# This produces error:
#   Argument "a" isn't numeric in numeric eq (==) at ...
# but it exits with *normal* exit, so throws_ok() doesn't see error ($@ is
# zero)

## use num-routine on (non-numeric) strings
## throws_ok( sub { num_row_equal($a1, $a2); },
##          qr/Argument "a" isn't numeric in numeric eq/,
##           'num-routine on (non-numeric) strings'
## );
