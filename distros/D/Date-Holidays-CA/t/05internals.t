use strict;
use warnings;
use Test::More tests => 15;
use Test::Exception;
use DateTime;

BEGIN { use_ok('Date::Holidays::CA', qw(:all)) };
# test internal "toolkit" functions here.

#    year  mon  n   correct date
my @_nth_monday_test_dates = (
    [2006,  1,  1,   2],         # month starts on a sunday
    [2006,  5,  5,  29],         # month starts on a monday
    [2006,  8,  4,  28],         # month starts on a tuesday
    [2006,  3,  3,  20],         # month starts on a wednesday
    [2006,  6,  2,  12],         # month starts on a thursday
    [2006,  9,  1,   4],         # month starts on a friday
    [2006,  4,  2,  10],         # month starts on a saturday
);

my @_nearest_monday_test_dates = (
    [2007,  1, 14,  15],         # sunday
    [2007,  1, 15,  15],         # monday
    [2007,  1, 16,  15],         # tuesday
    [2007,  1, 17,  15],         # wednesday
    [2007,  1, 18,  15],         # thursday
    [2007,  1, 19,  22],         # friday
    [2007,  1, 20,  22],         # saturday
);

_NTH_MONDAY: {
    foreach my $row (@_nth_monday_test_dates) {
        my $year         = $row->[0];
        my $month        = $row->[1];
        my $n            = $row->[2];
        my $correct_date = $row->[3];
    
        cmp_ok(
            Date::Holidays::CA::_nth_monday($year, $month, $n),
            '==', 
            $correct_date,  
            "$year $month $correct_date is Monday #$n of the month",
        );    
    }
} # _NTH_MONDAY:

_NEAREST_MONDAY: {
    foreach my $row (@_nearest_monday_test_dates) {
        my $year         = $row->[0];
        my $month        = $row->[1];
        my $day          = $row->[2];
        my $correct_date = $row->[3];
    
        cmp_ok(
            Date::Holidays::CA::_nearest_monday($year, $month, $day),
            '==', 
            $correct_date,  
            "Nearest Monday to $year $month $day is $correct_date",
        );    
    }
} # _NEAREST_MONDAY:
