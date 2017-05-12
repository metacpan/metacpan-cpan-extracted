#!perl
# Test of slaObs

use strict;
use Test::More tests => 10;

BEGIN {
  use_ok "Astro::SLA";
}

# First ask for telescope 1

my $i = 2;
my ($n, $name1, $w1, $p1, $h1);

slaObs($i, $n, $name1, $w1, $p1, $h1);
ok(1, "Successfully ran slaObs");
# previous bug lost $n if number was specified
ok(length($n) > 0, "Number > 0"); 


# Now ask for the parameters associated with the short telescope
# name associated with telescope 1
slaObs(-1, $n, my $name2, my $w2, my $p2, my $h2);

is($name1, $name2, "Check name");
is($w1, $w2, "Check W");
is($p1, $p2, "Check P");
is($h1, $h2, "Check height");

print "# $i $n $name2 $w2 $p2 $h2\n";

# Make sure we do not core dump if the second argument is undef
my $x;
slaObs(20,$x,my $a, my $b, my $c,my $d);
ok(1, "Ran slaObs with 2nd arg undef");

# Make sure we can specify a constant for the telescope name
slaObs(-1,'UKIRT',$a,$b,$c,$d);
ok(1, "Ran with constant tel name");

# Same with undefined first arg
slaObs(undef,'JCMT',$a,$b,$c,$d);
ok(1,"Ran with undef number");

