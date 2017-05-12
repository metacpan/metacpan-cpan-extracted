use Test::More qw(no_plan);
use strict;

# This test only checkes whether it is possible to transcode
# the date from one calendar into another.
# Real data tests with reference time points are performed
# in reper.t script.

BEGIN {
    use_ok('Date::Converter');
}

my $converter = new Date::Converter('julian', 'gregorian');
my ($year, $month, $day) = $converter->convert(2009, 2, 23);
ok(2009 == $year && 3 == $month && 8 == $day, 'Julian to Gregorian');

