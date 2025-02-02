#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 11;

BEGIN { use_ok('DateTime::Format::Genealogy') }

# Create an instance
my $dtf = new_ok('DateTime::Format::Genealogy');

# Test valid date
my $date_str = '25 Dec 2022';
my $dt = $dtf->parse_datetime($date_str);
ok(defined $dt, "Parsed date: $date_str");
is($dt->year(), 2022, 'Year is correct');
is($dt->month(), 12, 'Month is correct');
is($dt->day(), 25, 'Day is correct');

# Test invalid date
my $invalid_date = '31 Nov 2022';
my $dt_invalid = $dtf->parse_datetime($invalid_date);
ok(!defined($dt_invalid), "Invalid date: $invalid_date");

# Test date range
my $range = '1 Jan 2022 - 31 Dec 2022';
my @range_dates = $dtf->parse_datetime({ date => $range });
ok(scalar(@range_dates) == 2, "Parsed range: $range");
is($range_dates[0]->day(), 1, 'Range start day');
is($range_dates[1]->day(), 31, 'Range end day');

# Test approximate date
my $approx_date = 'abt 2022';
my $dt_approx = $dtf->parse_datetime(date => $approx_date);
ok(!defined($dt_approx), "Approximate date: $approx_date");
