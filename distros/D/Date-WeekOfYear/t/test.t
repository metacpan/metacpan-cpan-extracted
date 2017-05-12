# test.t
#
# Test old mode and new ISO mode
#
use strict;
use warnings;

use Test::More;

use Date::WeekOfYear ':all';
use Time::Local;

my @tests = (
    # Date,            YYYY-MM-DD,   ISO Wk YYYY-WkNo-Day, Comment
    ['Tue 29 Dec 1970', '1970-12-29', '1970-W53', '',],
    ['Wed 30 Dec 1970', '1970-12-30', '1970-W53', '',],
    ['Sat  1 Jan 1972', '1972-01-01', '1971-W52', '',],
    ['Sun  2 Jan 1972', '1972-01-02', '1971-W52', '',],
    ['Wed 29 Dec 1976', '1976-12-29', '1976-W53', '',],
    ['Sun  1 Jan 1978', '1978-01-01', '1977-W52', '',],
    ['Tue 29 Dec 1981', '1981-12-29', '1981-W53', '',],
    ['Wed 30 Dec 1981', '1981-12-30', '1981-W53', '',],
    ['Sat  1 Jan 1983', '1983-01-01', '1982-W52', '',],
    ['Sun  2 Jan 1983', '1983-01-02', '1982-W52', '',],
    ['Sun  1 Jan 1984', '1984-01-01', '1983-W52', '',],
    ['Wed 30 Dec 1987', '1987-12-30', '1987-W53', '',],
    ['Tue 29 Dec 1987', '1987-12-29', '1987-W53', '',],
    ['Sun  1 Jan 1989', '1989-01-01', '1988-W52', '',],
    ['Tue 29 Dec 1992', '1992-12-29', '1992-W53', '',],
    ['Wed 30 Dec 1992', '1992-12-30', '1992-W53', '',],
    ['Sun  2 Jan 1994', '1994-01-02', '1993-W52', '',],
    ['Sat  1 Jan 1994', '1994-01-01', '1993-W52', '',],
    ['Sun  1 Jan 1995', '1995-01-01', '1994-W52', '',],
    ['Tue 29 Dec 1998', '1998-12-29', '1998-W53', '',],
    ['Wed 30 Dec 1998', '1998-12-30', '1998-W53', '',],
    ['Sun  2 Jan 2000', '2000-01-02', '1999-W52', '',],
    ['Sat  1 Jan 2000', '2000-01-01', '1999-W52', '',],
    ['Wed 29 Dec 2004', '2004-12-29', '2004-W53', '',],
    ['Sat 31 Dec 2005', '2005-12-31', '2005-W52', '',],
    ['Sat  1 Jan 2005', '2005-01-01', '2004-W53', '',],
    ['Sun  2 Jan 2005', '2005-01-02', '2004-W53', '',],
    ['Sun  1 Jan 2006', '2006-01-01', '2005-W52', '',],
    ['Mon  1 Jan 2007', '2007-01-01', '2007-W01', 'Both years 2007 start with the same day.',],
    ['Mon 31 Dec 2007', '2007-12-31', '2008-W01', '',],
    ['Sun 30 Dec 2007', '2007-12-30', '2007-W52', '',],
    ['Sun 28 Dec 2008', '2008-12-28', '2008-W52', 'The ISO year 2009 is 3 days into the previous Gregorian year.',],
    ['Tue 30 Dec 2008', '2008-12-30', '2009-W01', '',],
    ['Tue  1 Jan 2008', '2008-01-01', '2008-W01', 'Gregorian year 2008 is a leap year, ISO year 2008 is 2 days shorter: 1 day longer at the start, 3 days shorter at the end.',],
    ['Mon 29 Dec 2008', '2008-12-29', '2009-W01', '',],
    ['Wed 31 Dec 2008', '2008-12-31', '2009-W01', '',],
    ['Tue 29 Dec 2009', '2009-12-29', '2009-W53', '',],
    ['Thu 31 Dec 2009', '2009-12-31', '2009-W53', 'ISO year 2009 has 53 weeks, thus it is 3 days into the Gregorian year 2010.',],
    ['Thu  1 Jan 2009', '2009-01-01', '2009-W01', '',],
    ['Wed 30 Dec 2009', '2009-12-30', '2009-W53', '',],
    ['Sat  2 Jan 2010', '2010-01-02', '2009-W53', '',],
    ['Sun  3 Jan 2010', '2010-01-03', '2009-W53', '',],
    ['Fri  1 Jan 2010', '2010-01-01', '2009-W53', '',],
    ['Sat  1 Jan 2011', '2011-01-01', '2010-W52', '',],
    ['Sun  2 Jan 2011', '2011-01-02', '2010-W52', '',],
    ['Sun  1 Jan 2012', '2012-01-01', '2011-W52', '',],

    ['Mon 27 Dec 1999', '1999-12-27', '1999-W52', '',],
    ['Tue 28 Dec 1999', '1999-12-28', '1999-W52', '',],
    ['Wed 29 Dec 1999', '1999-12-29', '1999-W52', '',],
    ['Thu 30 Dec 1999', '1999-12-30', '1999-W52', '',],
    ['Fri 31 Dec 1999', '1999-12-31', '1999-W52', '',],
    ['Sat  1 Jan 2000', '2000-01-01', '1999-W52', '',],
    ['Sun  2 Jan 2000', '2000-01-02', '1999-W52', '',],

    ['Mon  3 Jan 2000', '2000-01-03', '2000-W01', '',],
    ['Tue  4 Jan 2000', '2000-01-04', '2000-W01', '',],
    ['Wed  5 Jan 2000', '2000-01-05', '2000-W01', '',],
    ['Thu  6 Jan 2000', '2000-01-06', '2000-W01', '',],
    ['Fri  7 Jan 2000', '2000-01-07', '2000-W01', '',],
    ['Sat  8 Jan 2000', '2000-01-08', '2000-W01', '',],
    ['Sun  9 Jan 2000', '2000-01-09', '2000-W01', '',],

    ['Mon 10 Jan 2000', '2000-01-10', '2000-W02', '',],
    ['Tue 11 Jan 2000', '2000-01-11', '2000-W02', '',],
    ['Wed 12 Jan 2000', '2000-01-12', '2000-W02', '',],
    ['Thu 13 Jan 2000', '2000-01-13', '2000-W02', '',],
    ['Fri 14 Jan 2000', '2000-01-14', '2000-W02', '',],
    ['Sat 15 Jan 2000', '2000-01-15', '2000-W02', '',],
    ['Sun 16 Jan 2000', '2000-01-16', '2000-W02', '',],

    ['Mon 17 Jan 2000', '2000-01-17', '2000-W03', '',],
    ['Tue 18 Jan 2000', '2000-01-18', '2000-W03', '',],
    ['Wed 19 Jan 2000', '2000-01-19', '2000-W03', '',],
    ['Thu 20 Jan 2000', '2000-01-20', '2000-W03', '',],
    ['Fri 21 Jan 2000', '2000-01-21', '2000-W03', '',],
    ['Sat 22 Jan 2000', '2000-01-22', '2000-W03', '',],
    ['Sun 23 Jan 2000', '2000-01-23', '2000-W03', '',],

    ['Mon 24 Jan 2000', '2000-01-24', '2000-W04', '',],
    ['Tue 25 Jan 2000', '2000-01-25', '2000-W04', '',],
    ['Wed 26 Jan 2000', '2000-01-26', '2000-W04', '',],
    ['Thu 27 Jan 2000', '2000-01-27', '2000-W04', '',],
    ['Fri 28 Jan 2000', '2000-01-28', '2000-W04', '',],
    ['Sat 29 Jan 2000', '2000-01-29', '2000-W04', '',],
    ['Sun 30 Jan 2000', '2000-01-30', '2000-W04', '',],

    ['Mon 31 Jan 2000', '2000-01-31', '2000-W05', '',],
    ['Tue  1 Feb 2000', '2000-02-01', '2000-W05', '',],
    ['Wed  2 Feb 2000', '2000-02-02', '2000-W05', '',],
    ['Thu  3 Feb 2000', '2000-02-03', '2000-W05', '',],
    ['Fri  4 Feb 2000', '2000-02-04', '2000-W05', '',],
    ['Sat  5 Feb 2000', '2000-02-05', '2000-W05', '',],
    ['Sun  6 Feb 2000', '2000-02-06', '2000-W05', '',],
    );

plan tests => 10+3*scalar(@tests);

##1
ok(1, 'Date::WeekOfYear compiled, a good start');

##### Old Mode tests #####
#2
my $time = timelocal(0,0,12,1,0,108);
is(WeekOfYear($time, WOY_OLD_MODE), 1);

#3
$time = timelocal(0,0,12,5,0,108); #Saturday
is(WeekOfYear($time, WOY_OLD_MODE),1);

#4
$time = timelocal(0,0,12,29,0,108);
is(WeekOfYear($time, WOY_OLD_MODE),5);

#5
$time = timelocal(0,0,12,1,1,108);
is(WeekOfYear($time, WOY_OLD_MODE),5);

#6
$time = timelocal(0,0,12,1,0,116);
is(WeekOfYear($time, WOY_OLD_MODE),1);

#7
$time = timelocal(0,0,12,2,0,116);
is(WeekOfYear($time, WOY_OLD_MODE),1);

#8
$time = timelocal(0,0,12,6,0,116);
is(WeekOfYear($time, WOY_OLD_MODE),2);

is (WeekOfYear({ year => 2000, month => 1, day => 16}, WOY_ISO_MODE), '2000-W02', 'ISO_MODE hash ref date - 2000-01-16');

is (WeekOfYear({ year => 2000, month => 1, day => 17}, WOY_ISO_MODE), '2000-W03', 'ISO_MODE hash ref date - 2000-01-17');


# Run through the ISO test cases
foreach my $t (@tests)
{
    my $comment = $t->[0];
    $comment .= ' - ' . $t->[2] if $t->[2];
    $comment .= ' - ' . $t->[3] if $t->[3];

    # Generate the time value. Use midday so we don't run into any daylight saving time issues
    my ($year, $mon, $mday) = split /-/, $t->[1];
    my $time = timelocal(0, 0, 12, $mday, $mon - 1, $year - 1900);

    # Get the required answer
    my ($wk_num_year_answer, $wk_num_answer) = split /-/, $t->[2], 2;
    $wk_num_answer =~ s/W0*//;

    # Run the test
    my ($wk_num, $wk_num_year) = WeekOfYear($time);
    my $iso_wn = WeekOfYear($time, WOY_ISO_MODE);
    # Check the results for week number and year
    is ($wk_num, $wk_num_answer, 'Wk Num test - ' . $comment);
    is ($wk_num_year, $wk_num_year_answer, 'Year test - ' . $comment);
    is ($iso_wn, $t->[2], 'ISO Wk Number - ' . $comment);
}