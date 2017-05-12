#!perl
use strict;
use warnings;

use Test::More tests => 2;

use Array::Splice qw ( unshift_aliases push_aliases );

my @a = (1,2,3);
my @b = (5,6,7);

unshift_aliases @a, @b; 	
ok( \$a[1] == \$b[1], 'Unshift');

push_aliases @a, @b; 	
ok( \$a[-2] == \$b[-2], 'Push');

 
