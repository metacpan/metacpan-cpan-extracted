use Test::More;

use Algorithm::Networksort;
use strict;
use warnings;

my $inputs = 4;
my $alg = 'hibbard';
my @fmts = ("(%d,%d), ");
my @fstrs = ("(0,1), (2,3), (0,2), (1,3), (1,2), ");

plan tests => (scalar @fmts + 1);

my $nw = Algorithm::Networksort->new(inputs => $inputs, algorithm => $alg);

my $str = $nw->formatted();

is($str, "[[0,1], [2,3], [0,2], [1,3], [1,2]]", "Default format $alg $inputs");

for my $k (0 .. $#fmts)
{
	my $f = $fmts[$k];
	my $fs = $fstrs[$k];

	$nw->formats([$f]);
	$str = $nw->formatted();
	is($str, $fs, "Format '$f': $alg $inputs");
}

exit(0);
