#!/usr/bin/perl -w

use strict;

use CLI qw(INTEGER FLOAT STRING SSTRING TIME DEGREE BOOLEAN);
use CLI::Array;
use CLI::MixedArray;

my $a = new CLI::MixedArray('Test', [INTEGER, SSTRING, FLOAT],
			    [10, 'Hello', 3.14]);

print '$a[0]= ', $a->value(0), "\n";
print '$a[1]= ', $a->value(1), "\n";
print '$a[2]= ', $a->value(2), "\n";
$a->value(1, 'Fred');
print '$a[1]= ', $a->value(1), "\n";

my @b;

tie @b, 'CLI::MixedArray', 'Test', [INTEGER, SSTRING, FLOAT],
  [10, 'Hi', 3.14];

print '$b[2]= ', $b[2], "\n";
$b[2] = 2.71;
print '$b[2]= ', $b[2], "\n";

print "parse \$a\n";
$a->parse("3 Mary -34.4");
print "parse \$a\n";
$a->parse();

my $c = new CLI::Array('Test2', INTEGER, [-1, 3, 22]);

my @vals = $c->value();
print "\$c= @vals \n";
$c->value(2, 89);
print $c->value(2), "\n";

$c->value(5, 100);
print $c->value(5), "\n";

$c->parse("1 2 3 4 5 x");
@vals = $c->value();
print "@vals \n";


my @d;
tie @d, 'CLI::Array', 'Test 3', FLOAT, [-1.2, 3.4, 5.6], {min => -10.0,
							  max => 20.0};

print "@d\n";

print shift @d, "\n";
print pop @d, "\n";
print pop @d, "\n";
push @d, 12.2, 35.5;
unshift @d, -3.14, 23.3, 10.0;

print "@d\n";


