#! /usr/bin/perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Date::Tiny::Math;

# a Date::Tiny::Math is a Date::Tiny

my $date1 = Date::Tiny::Math->new(year => 2000, month => 1, day => 1);
isa_ok($date1, 'Date::Tiny::Math', 'Date::Tiny::Math');
isa_ok($date1, 'Date::Tiny', 'Date::Tiny::Math');
is("$date1", "2000-01-01",
   'stringification provided by Date::Tiny still works');

# but Date::Tiny doesn't know CJDN

my $cjdn2000 = 2451545;         # the CJDN of the 1st day of year 2000
is($date1->cjdn, $cjdn2000, 'CJDN of 2000-01-01');

my $date2 = Date::Tiny::Math->new(cjdn => $cjdn2000);
is($date1->cjdn, $date2->cjdn, 'new (cjdn)');

# and cannot add (but Date::Tiny::Math can)

my $date3 = 100 + $date1;
is("$date3", "2000-04-10", 'date +');
is($date3->cjdn, $cjdn2000 + 100, 'CJDN +');

$date3 += 10;
is("$date3", "2000-04-20", 'date +=');
is($date3->cjdn, $cjdn2000 + 110, 'CJDN +=');

++$date3;
is("$date3", "2000-04-21", 'date ++');
is($date3->cjdn, $cjdn2000 + 111, 'CJDN ++');

eval {
  my $bad = $date1 + $date2;
};
my $msg = 'Cannot add a Date::Tiny::Math to a Date::Tiny::Math';
is($@ =~ s/\n.*$//gr, $msg, $msg);

eval {
  my $bad = $date1 + 'uh-oh!';
};
$msg = 'Cannot add a non-numerical scalar to a Date::Tiny::Math';
is($@ =~ s/\n.*$//gr, $msg, $msg);

# or subtract

my $date4 = $date1 - 7;
is("$date4", "1999-12-25", 'date -');
is($date4->cjdn, $cjdn2000 - 7, 'CJDN -');

--$date4;
is("$date4", "1999-12-24", 'date --');
is($date4->cjdn, $cjdn2000 - 8, 'CJDN --');

is($date3 - $date4, 119, 'date3 - date4');
is($date4 - $date3, -119, 'date4 - date3');

$date4 -= 100;
is("$date4", "1999-09-15", 'date -=');
is($date4->cjdn, $cjdn2000 - 108, 'CJDN -=');

eval {
  my $bad = 7 - $date1;
};
$msg = 'Cannot subtract a Date::Tiny::Math from a non-Date::Tiny::Math';
is($@ =~ s/\n.*$//gr, $msg, $msg);

eval {
  my $bad = $date1 - 'uh-oh!';
};
$msg = 'Cannot subtract a non-numerical scalar from a Date::Tiny::Math';
is($@ =~ s/\n.*$//gr, $msg, $msg);

# or compare

ok($date1 == $date2, "$date1 == $date2");
ok($date3 > $date2, "$date3 > $date2");
ok($date2 < $date3, "$date2 < $date3");
ok($date4 < $date2, "$date4 < $date2");

eval {
  my $bad = ($date1 == 3);
};
$msg = 'Cannot compare a Date::Tiny::Math to a non-Date::Tiny::Math';
is($@ =~ s/\n.*$//gr, $msg, $msg);

# decimal (non-integer) day numbers are rounded down, and negative
# ones are OK, too.

# NOTE: Date::Tiny v1.07 does not stringify negative year numbers
# correctly, so we test the individual date components

my $date5 = Date::Tiny::Math->new(cjdn => 1.5);
is($date5->cjdn, 1, '1.5 → 1');
is($date5->year, -4713, 'CJDN 1 → year');
is($date5->month, 11, 'CJDN 1 → month');
is($date5->day, 25, 'CJDN 1 → day');

my $date6 = Date::Tiny::Math->new(cjdn => -1.5);
is($date6->cjdn, -2, '−1.5 → −2');
is($date6->year, -4713, 'CJDN −2 → year');
is($date6->month, 11, 'CJDN −2 → month');
is($date6->day, 22, 'CJDN −2 → day');

is($date5 - $date6, 3, '3 days between CJDN 1 and CJDN −2');

# Test the date conversion.  We compare the Date::Tiny::Math results
# with those of gmtime for a period of 400 years = 146097 days (the
# period after which month lengths in the Gregorian calendar repeat
# exactly).

# Get the epoch of gmtime; we're not sure that earlier instants of
# time are supported by gmtime() on all systems.
my ($sec, $min, $h, $mday, $mon, $year) = gmtime(0);
my $offset = $sec + 60*($min + 60*$h);
my $epoch = Date::Tiny::Math->new(year => $year + 1900,
                                  month => $mon + 1,
                                  day => $mday)->cjdn;

diag("Checking 146097 dates; please hold...");
my $ok = 1;
for my $cjdn (2451545..2451545+146097) {
  my $d = Date::Tiny::Math->new(cjdn => $cjdn);
  my $cjdn1 = $d->cjdn;
  my $d2 = Date::Tiny::Math->new(year => $d->year,
                                 month => $d->month,
                                 day => $d->day);
  my $cjdn2 = $d2->cjdn;

  if ($cjdn1 != $cjdn or $cjdn2 != $cjdn) {
    fail("CJDN → calendar date → CJDN fails for $cjdn");
    $ok = 0;
    last;
  }

  my $t = ($cjdn - $epoch)*86400 - $offset;
  my ($sec, $min, $h, $mday, $mon, $year) = gmtime($t);
  if ($d->year != $year + 1900
      or $d->month != $mon + 1
      or $d->day != $mday) {
    fail("CJDN → calendar date fails for $cjdn");
    $ok = 0;
    last;
  }
}
ok($ok, "CJDN ⇔ calendar date");

done_testing();
