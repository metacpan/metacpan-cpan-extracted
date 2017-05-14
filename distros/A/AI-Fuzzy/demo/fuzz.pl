#!/usr/bin/perl
use lib qw(blib/arch blib/lib ../blib/arch ../blib/lib);
use strict;
use warnings;
use AI::Fuzzy;

my $f = new AI::Fuzzy::Axis;
my $l = new AI::Fuzzy::Label("toddler",      1, 1.5, 3.5);

#print "$l\n";

$f->addlabel("baby",        -1,   1, 2.5);
$f->addlabel($l);
$f->addlabel("little kid",   2,   7,  12);
$f->addlabel("kid",          6,  10,  14);
$f->addlabel("teenager",    12,  16,  20);
$f->addlabel("young adult", 18,  27,  35);
$f->addlabel("adult",       25,  50,  75);
$f->addlabel("senior",      60,  80, 110);
$f->addlabel("relic",      100, 150, 200);

 for (my $x = 0; $x<50; $x+=4) {
     print "$x years old => " . $f->labelvalue($x) . "\n";
 }

$a = new AI::Fuzzy::Set( x1 => .3, x2 => .5, x3 => .8, x4 => 0, x5 => 1);
$b = new AI::Fuzzy::Set( x5 => .3, x6 => .5, x7 => .8, x8 => 0, x9 => 1);
print "a is: " . $a->as_string . "\n";
print "b is: " . $b->as_string . "\n";

print "a is equal to b" if ($a->equal($b));

my $c = $a->complement();
print "complement of a is: " . $c->as_string . "\n";

$c = $a->union($b);
print "a union b is: " . $c->as_string . "\n";

$c = $a->intersection($b);
print "a intersection b is: " . $c->as_string . "\n";

