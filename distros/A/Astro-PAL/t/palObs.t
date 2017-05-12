#!perl
# Test of palObs

use strict;
use Test::More tests => 12;

BEGIN {
  use_ok "Astro::PAL";
}

# First ask for telescope by number

my $i = 2;
my ($ident, $name1, $w1, $p1, $h1) = Astro::PAL::palObs( $i );
ok(1, "Successfully ran palObs");
# previous bug lost $n if number was specified but now we return ident
ok(length($ident) > 0, "Number > 0");


# Now ask for the parameters associated with the short telescope
# name associated with telescope 1
my ($ident2, $name2, $w2, $p2, $h2) = Astro::PAL::palObs($ident);

is($name1, $name2, "Check name");
is($w1, $w2, "Check W");
is($p1, $p2, "Check P");
is($h1, $h2, "Check height");

print "# $i $ident $name2 $w2 $p2 $h2\n";

# Make sure we do not core dump if the second argument is undef
my $x;
my @result = Astro::PAL::palObs(20,$x);
ok(1, "Ran palObs with 2nd arg undef");

# Make sure we can specify a constant for the telescope name
@result = Astro::PAL::palObs('UKIRT');
is($result[0], "UKIRT", "and got UKIRT");

# Same again
@result = Astro::PAL::palObs('JCMT');
is($result[0], "JCMT", "and got JCMT");

# Try a couple of failures
@result = Astro::PAL::palObs( 500 );
is(scalar(@result),0, "Test too high number");
@result = Astro::PAL::palObs( 0 );
is(scalar(@result),0, "Test too small number");
