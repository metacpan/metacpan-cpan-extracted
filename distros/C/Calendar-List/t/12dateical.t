#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More;
use TestData;
use Calendar::Functions qw(:all :test);

# check we can load the module
eval "use Date::ICal";
if($@) {
	plan skip_all => "Date::ICal not installed.";
}

Date::ICal->import;
plan qw|no_plan|;

diag("using Date::ICal version " . $Date::ICal::VERSION);

###########################################################################
# name: 12dateical.t
# desc: Functionality check with Date::ICal
###########################################################################

# switch off DateTime, if loaded
_caltest(0,1,0);

foreach my $test (@datetest) {
	my $date = encode_date(@{$test->{array}});
    if($test->{invalid}) {
        is($date,undef,"date failed to encode [@{$test->{array}}] correctly");
    } else {
        ok($date,"date encoded [@{$test->{array}}]");
        my @date = decode_date($date);
        is_deeply(\@date,$test->{array},"date decoded [@{$test->{array}}]");
    }
}

foreach my $test (@diffs) {
    my ($date1,$date2);
	$date1 = encode_date(@{$test->{from}})  if(@{$test->{from}});
	$date2 = encode_date(@{$test->{to}})    if(@{$test->{to}});
	is(compare_dates($date1,$date2),$test->{compare},
            sprintf ".. [%02d/%02d/%04d] => [%02d/%02d/%04d]",
                $test->{from}[0]||'-1',$test->{from}[1]||'-1',$test->{from}[2]||'-1',
                $test->{to}[0]||'-1',$test->{to}[1]||'-1',$test->{to}[2]||'-1');
}

# fail_range
is(fail_range(0),1);
is(fail_range(1899),0);
is(fail_range(1965),0);
is(fail_range(1999),0);
is(fail_range(2000),0);
is(fail_range(2038),0);

