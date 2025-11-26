#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Date::Age qw(describe details);

plan tests => 26;

# Call describe as class method (uncovered branch)
my $result = Date::Age::describe('2000-01-01', '2020-01-01');
is($result, '20', 'describe as class method - precise age');

# Call details as class method (uncovered branch)
my $info = Date::Age::details('2000-01-01', '2020-01-01');
is($info->{range}, '20', 'details as class method - precise age');
is($info->{min_age}, 20, 'details min_age correct');
is($info->{max_age}, 20, 'details max_age correct');
is($info->{precise}, 20, 'details precise age available');

# Test _now_string function (completely uncovered)
# We can't test the exact output since it depends on current date,
# but we can verify it returns a string in YYYY-MM-DD format
my $today = eval { Date::Age::_now_string() };
like($today, qr/^\d{4}-\d{2}-\d{2}$/, '_now_string returns valid date format');

# Test YYYY-MM date format (uncovered branch)
$info = details('2000-05', '2020-01-01');
is($info->{range}, '19', 'YYYY-MM format gives single age when ref date before birthday month');
is($info->{min_age}, 19, 'YYYY-MM min_age correct');
is($info->{max_age}, 19, 'YYYY-MM max_age correct');

# Test YYYY-MM date format that should produce a range
$info = details('2000-05', '2020-05-15');
is($info->{range}, '19-20', 'YYYY-MM format produces range when ref date in birthday month');
is($info->{min_age}, 19, 'YYYY-MM range min_age correct');
is($info->{max_age}, 20, 'YYYY-MM range max_age correct');

# Test age calculation where birthday hasn't occurred yet
# Born in December, checking in January - should be younger
$info = details('2000-12-31', '2020-01-01');
is($info->{min_age}, 19, 'Age correct when birthday not yet occurred');
is($info->{max_age}, 19, 'Max age correct when birthday not yet occurred');

# Test age calculation where birthday has occurred
# Born in January, checking in December - should be older
$info = details('2000-01-01', '2020-12-31');
is($info->{min_age}, 20, 'Age correct when birthday has occurred');
is($info->{max_age}, 20, 'Max age correct when birthday has occurred');

# Test _end_of_month function (completely uncovered)
my $end_feb_2000 = eval { Date::Age::_end_of_month(2000, 2) };
is($end_feb_2000, '2000-02-29', '_end_of_month for leap year February');

my $end_feb_2001 = eval { Date::Age::_end_of_month(2001, 2) };
is($end_feb_2001, '2001-02-28', '_end_of_month for non-leap year February');

my $end_apr = eval { Date::Age::_end_of_month(2000, 4) };
is($end_apr, '2000-04-30', '_end_of_month for April');

# Test _is_leap function edge cases
is(Date::Age::_is_leap(2000), 1, 'Year 2000 is leap (divisible by 400)');
is(Date::Age::_is_leap(1900), 0, 'Year 1900 is not leap (divisible by 100 but not 400)');
is(Date::Age::_is_leap(2004), 1, 'Year 2004 is leap (divisible by 4 but not 100)');
is(Date::Age::_is_leap(2003), 0, 'Year 2003 is not leap (not divisible by 4)');

# Test error conditions
eval { details('invalid-date', '2020-01-01') };
like($@, qr/Unrecognized date format/, 'Dies on invalid date format');

eval { details('2000-13-01', '2020-01-01') };
like($@, qr/Invalid month/, 'Dies on invalid month');

eval { details('2000-02-30', '2020-01-01') };
like($@, qr/Invalid day/, 'Dies on invalid day');
