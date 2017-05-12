# Before `make install' is performed this script should be runnable wi
# `make test'. After `make install' it should work as `perl 1.t'

print "1..1\n";

my $i = 1;

use Date::Indian;
use strict;

# Does it change a proper list? (It should not)
# Does it drop duplicates from list? ( It should)

my $ymd = "2003-8-27";
my $tz  = "5:30";
my $locn = "78:18 17:13";

my $date = Date::Indian -> new(ymd => $ymd, tz => $tz, locn => $locn);
print "not " unless $date;
printf "ok %d\n", $i++;

