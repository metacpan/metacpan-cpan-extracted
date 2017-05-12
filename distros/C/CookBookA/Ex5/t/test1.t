#!perl -w

use strict;
use CookBookA::Ex5;

print "1..3\n";

my $a = CookBookA::Ex5->new;
my $x = 0;

$a->ramble( \$x );
print( (($x == 42)? "ok ": "not ok "), "1\n" );

$x = $a->drift;
print( (($x == 66)? "ok ": "not ok "), "2\n" );

$a->ramble( \$x );
print( (($x == 42)? "ok ": "not ok "), "3\n" );

