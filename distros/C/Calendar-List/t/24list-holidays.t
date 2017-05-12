#!/usr/bin/perl -w
use strict;

use Test::More tests => 5;
use Calendar::List;
use Calendar::Functions qw(:test);

# switch off DateTime and Date::ICal, if loaded
_caltest(0,0);

###########################################################################
# name: 24list-holidays.t
# desc: Exclude holidays testing
###########################################################################

# -------------------------------------------------------------------------
# The tests

my @holidays = ('02-09-2005','04-09-2005','05-09-2005');
my @with     = ('01-09-2005','02-09-2005','03-09-2005','04-09-2005','05-09-2005','06-09-2005','07-09-2005');
my @without  = ('01-09-2005','03-09-2005','06-09-2005','07-09-2005');
my @weekdays = ('01-09-2005','06-09-2005','07-09-2005');
my @weekends = ('03-09-2005');

my %hash = (start => '01-09-2005',end=>'07-09-2005');
my @array = calendar_list(\%hash);
is_deeply(\@array,\@with);

$hash{exclude}->{holidays} = '04-09-2005';  # bad format, ignored
@array = calendar_list(\%hash);
is_deeply(\@array,\@with);

$hash{exclude}->{holidays} = \@holidays;
@array = calendar_list(\%hash);
is_deeply(\@array,\@without);

$hash{exclude}->{weekend} = 1;
@array = calendar_list(\%hash);
is_deeply(\@array,\@weekdays);

$hash{exclude}->{weekend} = 0;
$hash{exclude}->{weekday} = 1;
@array = calendar_list(\%hash);
is_deeply(\@array,\@weekends);
