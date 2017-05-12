use strict;
use warnings;

use Test::More qw(no_plan);
use Data::Dumper;

BEGIN {
    use_ok('Array::APX', qw(:all));
}

die "using module Array::APX failed\n" unless $Array::APX::VERSION;

# Testing the exported functions:
my $x = iota(9);
isa_ok($x, 'Array::APX');
is_deeply([@$x], [0..8], 'iota');

$x = dress([1, 2, 3]);
isa_ok($x, 'Array::APX');
is_deeply([@$x], [1..3], 'dress');

# Testing unary operators:
$x = -iota(6);
is_deeply([@$x], [0, -1, -2, -3, -4, -5], '-APX');

$x = -dress([[1, 2], [3, 4]]);
is_deeply([@$x], [[-1, -2], [-3, -4]], '-APX in two dimensions');

$x = !dress([0, 1, 1, 0]);
is_deeply([@$x], [1, 0, 0, 1], '!APX');

$x = !dress([[0, 1], [1, 0]]);
is_deeply([@$x], [[1, 0], [0, 1]], '! in two dimensions');

# Testing basic binary operators:
$x = iota(3) + 1;
is_deeply([@$x], [1..3], 'APX + scalar');

$x = 1 + iota(3);
is_deeply([@$x], [1..3], 'scalar + APX');

$x = iota(3) + iota(3);
is_deeply([@$x], [0, 2, 4], 'APX + APX');

$x = dress([[1, 2], [3, 4]]) + dress([[5, 6], [7, 8]]);
is_deeply([@$x], [[6, 8], [10, 12]], 'APX + APX in two dimensions');

$x = (iota(3) + 1) * 2;
is_deeply([@$x], [2, 4, 6], 'APX * scalar');

$x = 2 * (iota(3) + 1);
is_deeply([@$x], [2, 4, 6], 'scalar * APX');

$x = (iota(3) + 1) * (iota(3) + 4);
is_deeply([@$x], [4, 10, 18], 'APX * APX');

$x = dress([[1, 2], [3, 4]]) * dress([[5, 6], [7, 8]]);
is_deeply([@$x], [[5, 12], [21, 32]], 'APX * APX in two dimensions');

$x = iota(3) - 1;
is_deeply([@$x], [-1..1], 'APX - scalar');

$x = 1 - iota(3);
is_deeply([@$x], [1, 0, -1], 'scalar - APX');

$x = iota(3) - dress([3, 2, 1]);
is_deeply([@$x], [-3, -1, 1], 'APX - APX');

$x = dress([[1, 2], [3, 4]]) - dress([[5, 6], [7, 8]]);
is_deeply([@$x], [[-4, -4], [-4, -4]], 'APX - APX in two dimensions');

$x = iota(3) / 2;
is_deeply([@$x], [0, .5, 1], 'APX / scalar');

$x = 2 / (iota(3) + 1);
is_deeply([@$x], [2, 1, 2 / 3], 'scalar / APX');

$x = iota(3) / dress([3, 2, 1]);
is_deeply([@$x], [0, .5, 2], 'APX / APX');

$x = dress([[1, 1], [4, 4]]) / dress([[2, 4], [2, 8]]);
is_deeply([@$x], [[.5, .25], [2, .5]], 'APX / APX in two dimensions');

$x = iota(6) % 3;
is_deeply([@$x], [0, 1, 2, 0, 1, 2], 'APX % scalar');

$x = 9 % (iota(6) + 2);
is_deeply([@$x], [1, 0, 1, 4, 3, 2], 'scalar % APX');

$x = iota(6) % dress([2, 2, 2, 3, 3, 3]);
is_deeply([@$x], [0, 1, 0, 0, 1, 2], 'APX % APX');

$x = dress([[5, 6], [7, 8]]) % dress([[2, 3], [4, 5]]);
is_deeply([@$x], [[1, 0], [3, 3]], 'APX % APX in two dimensions');

$x = iota(6) ** 3;
is_deeply([@$x], [0, 1, 8, 27, 64, 125], 'APX ** scalar');

$x = 3 ** iota(6);
is_deeply([@$x], [1, 3, 9, 27, 81, 243], 'scalar ** APX');

$x = iota(6) ** iota(6);
is_deeply([@$x], [1, 1, 4, 27, 256, 3125], 'APX ** APX');

$x = dress([[1, 2], [3, 4]]) ** dress([[2, 3], [4, 5]]);
is_deeply([@$x], [[1, 8], [81, 1024]], 'APX ** APX in two dimensions');

$x = iota(8) & 5;
is_deeply([@$x], [0, 1, 0, 1, 4, 5, 4, 5], 'APX & scalar');

$x = 5 & iota(8);
is_deeply([@$x], [0, 1, 0, 1, 4, 5, 4, 5], 'scalar & APX');

$x = iota(8) & dress([3, 5]);
is_deeply([@$x], [0, 1, 2, 1, 0, 5, 2, 5], 'APX & APX');

$x = dress([[1, 2], [3, 4]]) & dress([[2, 3], [4, 5]]);
is_deeply([@$x], [[0, 2], [0, 4]], 'APX & APX in two dimensions');

$x = iota(8) | 5;
is_deeply([@$x], [5, 5, 7, 7, 5, 5, 7, 7], 'APX | scalar');

$x = 5 | iota(8);
is_deeply([@$x], [5, 5, 7, 7, 5, 5, 7, 7], 'scalar | APX');

$x = iota(8) | dress([1, 1, 3, 3]);
is_deeply([@$x], [1, 1, 3, 3, 5, 5, 7, 7], 'APX | APX');

$x = dress([[1, 2], [3, 4]]) | dress([[2, 3], [4, 5]]);
is_deeply([@$x], [[3, 3], [7, 5]], 'APX | APX in two dimensions');

$x = iota(8) ^ 5;
is_deeply([@$x], [5, 4, 7, 6, 1, 0, 3, 2], 'APX ^ scalar');

$x = 5 ^ iota(8);
is_deeply([@$x], [5, 4, 7, 6, 1, 0, 3, 2], 'scalar ^ APX');

$x = iota(8) ^ dress([3, 5]);
is_deeply([@$x], [3, 4, 1, 6, 7, 0, 5, 2], 'APX ^ APX');

$x = dress([[1, 2], [3, 4]]) ^ dress([[2, 3], [4, 5]]);
is_deeply([@$x], [[3, 1], [7, 1]], 'APX ^ APX in two dimensions');

$x = iota(4) == 2;
is_deeply([@$x], [0, 0, 1, 0], 'APX == scalar');

$x = iota(10) < 5;
is_deeply([@$x], [1, 1, 1, 1, 1, 0, 0, 0, 0, 0], 'APX < scalar');

$x = 4 < iota(10);
is_deeply([@$x], [0, 0, 0, 0, 0, 1, 1, 1, 1, 1], 'scalar < APX');

$x = iota(10) <= 5;
is_deeply([@$x], [1, 1, 1, 1, 1, 1, 0, 0, 0, 0], 'APX <= scalar');

$x = 5 <= iota(10);
is_deeply([@$x], [0, 0, 0, 0, 0, 1, 1, 1, 1, 1], 'scalar <= APX');

$x = iota(10) > 4;
is_deeply([@$x], [0, 0, 0, 0, 0, 1, 1, 1, 1, 1], 'APX > scalar');

$x = 5 > iota(10);
is_deeply([@$x], [1, 1, 1, 1, 1, 0, 0, 0, 0, 0], 'scalar > APX');

$x = iota(10) >= 4;
is_deeply([@$x], [0, 0, 0, 0, 1, 1, 1, 1, 1, 1], 'APX >= scalar');

$x = 4 >= iota(10);
is_deeply([@$x], [1, 1, 1, 1, 1, 0, 0, 0, 0, 0], 'scalar >= APX');

$x = dress(['a', 'b']) eq 'a';
is_deeply([@$x], [1, 0], 'APX eq scalar');

$x = 2 == iota(4);
is_deeply([@$x], [0, 0, 1, 0], 'scalar == APX');

$x = iota(4) == dress([0, 2, 2, 2]);
is_deeply([@$x], [1, 0, 1, 0], 'APX == APX');

$x = dress([[1, 2], [3, 4]]) == dress([[2, 2], [3, 5]]);
is_deeply([@$x], [[0, 1], [1, 0]], 'APX == APX in two dimensions');

$x = iota(4) != 2;
is_deeply([@$x], [1, 1, 0, 1], 'APX != scalar');

$x = 2 != iota(4);
is_deeply([@$x], [1, 1, 0, 1], 'scalar != APX');

$x = iota(4) != dress([0, 2, 2, 2]);
is_deeply([@$x], [0, 1, 0, 1], 'APX != APX');

$x = dress([[1, 2], [3, 4]]) != dress([[2, 2], [3, 5]]);
is_deeply([@$x], [[1, 0], [0, 1]], 'APX == APX in two dimensions');

# Testing outer products etc.:
my $f = sub { $_[0] * $_[1] };
$x = (iota(3) + 1) |$f| (iota(3) + 1);
is_deeply([@$x], [[1, 2, 3], [2, 4, 6], [3, 6, 9]], 'outer product');

$f = sub { $_[0] + $_[1] };
is($f/ (iota(100) + 1), 5050, 'reduce');

$x = iota(3);
$x =~ s/\n$//;
is($x, '[    0    1    2 ]', 'stringify');

# Testing APX-methods:
$x = iota(3)->strip();
is_deeply($x, [0, 1, 2], 'strip');

$x = iota(9)->rho(dress([3, 3]));
is_deeply([@$x], [[0, 1, 2], [3, 4, 5], [6, 7, 8]], 'rho as reshape');

$x = $x->rho();
is_deeply([@$x], [3, 3], 'rho as shape');

$x = dress([0.5, 1.2, 2.7])->int();
is_deeply([@$x], [0, 1, 2], 'int');

$x = iota(27)->rho(dress([3, 3, 3]))->collapse();
is_deeply([@$x], [0 .. 26], 'collapse');

$x = dress([3, 1, 4, 5, 9, 2, 6])->grade();
is_deeply([@$x], [1, 5, 0, 2, 3, 6, 4], 'grade');

$x = dress([[1, 3], [4, 5]])->index(dress([[1, 2, 3], [4, 5, 6], [7, 8, 9]]));
is_deeply([@$x], [[[0, 0], [0, 2]], [[1, 0], [1, 1]]], 'index');

$x = iota(10)->remove(dress([1, 3, 5]));
is_deeply([@$x], [0, 2, 4, 6, 7, 8, 9], 'remove');

$x = iota(5)->reverse();
is_deeply([@$x], [4, 3, 2, 1, 0], 'reverse');

$x = dress([[1, 2, 3], [4, 5, 6], [7, 8, 9]])->rotate(dress([1, -1]));
is_deeply([@$x], [[8, 9, 7], [2, 3, 1], [5, 6, 4]], 'rotate');

$x = (iota(7) + 1)->scatter(dress([[0, ,0], [0, 1], [1, 0], [1, 1]]));
is_deeply([@$x], [[1, 2], [3, 4]], 'scatter');

$x = (iota(9) + 1)->rho(dress([3, 3]))->slice(dress([[1, 0], [2, 1]]));
is_deeply([@$x], [[4, 5], [7, 8]], 'slice');

$f = sub { $_[0] + $_[1] };
$x = $f x iota(10);
is_deeply([@$x], [0, 1, 3, 6, 10, 15, 21, 28, 36, 45], 'scan');

$x = (iota(9) + 1)->rho(dress([3, 3]))->subscript(dress([1]));
is_deeply([@$x], [[4, 5, 6]], 'subscript');

$x = (iota(9) + 1)->rho(dress([3, 3]))->transpose(1);
is_deeply([@$x], [[1, 4, 7], [2, 5, 8], [3, 6, 9]], 'transpose');
