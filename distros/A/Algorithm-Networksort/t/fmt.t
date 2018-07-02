use Test::More;

use Algorithm::Networksort;
use strict;
use warnings;

plan tests => 4;

my $nw = nwsrt(inputs => 4, algorithm => 'hibbard');

my $str = "$nw";

is($str, "[[0,1], [2,3],\n[0,2], [1,3],\n[1,2]]", "Stringify " . $nw->title());

$str = $nw->formatted();
is($str, "[[0,1], [2,3], [0,2], [1,3], [1,2]]", "Default format " . $nw->title());

#
# Now some non-default formats.
#
$nw->formats(["(%d,%d), "]);
$str = $nw->formatted();
is($str, "(0,1), (2,3), (0,2), (1,3), (1,2), ",
	"1st format: " . $nw->title());

$nw->index_base(['a' .. 'd']);
$nw->formats(["cswp(%s,%s); "]);
$str = $nw->formatted();
is($str, "cswp(a,b); cswp(c,d); cswp(a,c); cswp(b,d); cswp(b,c); ",
	"2nd format: " . $nw->title());

exit(0);
