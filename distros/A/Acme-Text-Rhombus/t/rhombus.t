#!/usr/bin/perl

use strict;
use warnings;

use Acme::Text::Rhombus qw(rhombus);
use Test::More tests => 1;

my $rhombus = rhombus(
    lines   =>      31,
    letter  =>     'c',
    case    => 'upper',
    fillup  =>     '+',
);

is($rhombus, do { local $/; <DATA> }, 'rhombus()');

__DATA__
+++++++++++++++C+++++++++++++++
++++++++++++++DDD++++++++++++++
+++++++++++++EEEEE+++++++++++++
++++++++++++FFFFFFF++++++++++++
+++++++++++GGGGGGGGG+++++++++++
++++++++++HHHHHHHHHHH++++++++++
+++++++++IIIIIIIIIIIII+++++++++
++++++++JJJJJJJJJJJJJJJ++++++++
+++++++KKKKKKKKKKKKKKKKK+++++++
++++++LLLLLLLLLLLLLLLLLLL++++++
+++++MMMMMMMMMMMMMMMMMMMMM+++++
++++NNNNNNNNNNNNNNNNNNNNNNN++++
+++OOOOOOOOOOOOOOOOOOOOOOOOO+++
++PPPPPPPPPPPPPPPPPPPPPPPPPPP++
+QQQQQQQQQQQQQQQQQQQQQQQQQQQQQ+
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
+SSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
++TTTTTTTTTTTTTTTTTTTTTTTTTTT++
+++UUUUUUUUUUUUUUUUUUUUUUUUU+++
++++VVVVVVVVVVVVVVVVVVVVVVV++++
+++++WWWWWWWWWWWWWWWWWWWWW+++++
++++++XXXXXXXXXXXXXXXXXXX++++++
+++++++YYYYYYYYYYYYYYYYY+++++++
++++++++ZZZZZZZZZZZZZZZ++++++++
+++++++++AAAAAAAAAAAAA+++++++++
++++++++++BBBBBBBBBBB++++++++++
+++++++++++CCCCCCCCC+++++++++++
++++++++++++DDDDDDD++++++++++++
+++++++++++++EEEEE+++++++++++++
++++++++++++++FFF++++++++++++++
+++++++++++++++G+++++++++++++++
