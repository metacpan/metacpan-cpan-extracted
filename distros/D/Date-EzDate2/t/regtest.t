#!/usr/bin/perl -w
use strict;
BEGIN { if ($ENV{'AUTOCLEAR'}) { system('/usr/bin/clear') } }
use lib '../../';
use Date::EzDate2 ':all';
use Carp 'confess', 'croak';

# prepare for tests
use Test::Most;
$ENV{'IDOCSDEV'} and die_on_fail();
plan tests => 16;

# TESING
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# stub for err_comp
sub err_comp;

# turn off warnings
$Date::EzDate2::default_warning = 0;

# set default time zone
$Date::EzDate::default_time_zone = 'America/New_York';

# Jan 31 date used for a lot of tests
my $jan31 = {};
$jan31->{'in'} = 'January 31, 2002 1:05:07 am';
$jan31->{'funky'} = 'January 31, 2002  1:05:07 am Thu';
$jan31->{'full'} = 'Thu Jan 31, 2002 01:05:07';
$jan31->{'dmy'} = '31JAN2002';
$jan31->{'format'}->{'name'} = 'mypattern';
$jan31->{'format'}->{'name_changed'} = 'My Pattern';
$jan31->{'format'}->{'pattern'} = '{Month Long} {Day Of Month} {Year} ({Weekday Long}) ({Day Of Year})';
$jan31->{'format'}->{'output'} = 'January 31 2002 (Thursday) (31)';


#------------------------------------------------------------------------------
##- basic creation
#
if (1) {
	my ($date, $clone);
	
	## current date and time
	$date = Date::EzDate2->new()
		or die 'cannot create for current date and time';
	
	## create with known date
	$date = Date::EzDate2->new($jan31->{'in'})
		or die "cannot create with $jan31->{'in'}";
	err_comp $date->{'full'}, $jan31->{'full'}, '[1]';
	
	## a date in DDMMMYYYY format
	$date = Date::EzDate2->new($jan31->{'dmy'})
		or die "cannot create with $jan31->{'in'}";
	err_comp $date->{'dmy'}, $jan31->{'dmy'}, '[2]';
	
	## a little forgiveness
	$date = Date::EzDate2->new($jan31->{'funky'})
		or die "cannot create with $jan31->{'funky'}";
	err_comp $date->{'full'}, $jan31->{'full'}, '[3]';
	
	## clone
	$clone = $date->clone;
	err_comp($date->{'full'}, $clone->{'full'}, '[4]');
};
#
# basic creation
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##- some dates that have been known to give us problems
#
if (1) {
	my $mydate = Date::EzDate2->new('Jan 15 2002, 21:01:26');
	$mydate->{'dmy'} = '25OCT2001';
};
#
# some dates that have been known to give us problems
#------------------------------------------------------------------------------


#----------------------------------------------------------------------------------
##- date parsing
#
if (1) {
	my ($orgstr, $mydate, $settings);
	
	$orgstr = 'Sun Apr 26, 1970 00:00:07';
	$mydate = Date::EzDate2->new($orgstr);
	
	err_comp($mydate->{'full'}, $orgstr, 'full', '[5]');
};
#
# date parsing
#----------------------------------------------------------------------------------




#----------------------------------------------------------------------------------
# $mydate->{'epochday'}++ hour compare
#
#if (1) {
#	COMPARE: {
#		my ($mydate, $olddate, $oldhour);
#		
#		$mydate = Date::EzDate2->new('Jan 1, 1880 00:00:07');
#		$olddate = $mydate->{'full'};
#		$oldhour = $mydate->{'hour'};
#		
#		while ($mydate->{'year'} <= 2033) {
#			$mydate->{'dayofmonth'} += 13;
#			
#			if ($mydate->{'hour'} != $oldhour) {
#				die
#					"failed\n",
#					"$olddate \t old:$oldhour \t new:$mydate->{'hour'}\n";
#			}
#			
#			$oldhour = $mydate->{'hour'};
#			$olddate = $mydate->{'full'};
#		}
#	}
#}
#
# $mydate->{'epochday'}++ hour compare
#----------------------------------------------------------------------------------



#------------------------------------------------------
##- next_month
#
if (1) {
	my ($date);
	
	## create with known date
	$date = Date::EzDate2->new($jan31->{'in'})
		or die "cannot create with $jan31->{'in'}";
	
	## next_month: go forward two months to March
	$date->next_month(2);
	err_comp($date->{'Day of Month'}, '31', '[6]');
	
	## go back to Feb of 2000
	$date->next_month(-25);
	err_comp($date->{'Day of Month'}, '29', '[7]');
	
	## go forward to Feb of 2001
	$date->next_month(12);
	err_comp($date->{'Day of Month'}, '28', '[8]');
};
#
# next_month
#------------------------------------------------------


#------------------------------------------------------
##- custom format
#
if (1) {
	my ($date);
	
	## create with known date
	$date = Date::EzDate2->new($jan31->{'in'})
		or die "cannot create with $jan31->{'in'}";
	$date->set_warnings('croak');
	
	## set the format
	$date->set_format($jan31->{'format'}->{'name'}, $jan31->{'format'}->{'pattern'});
	
	## check the format, using the same name but with different capitalization and spacing
	err_comp($date->{$jan31->{'format'}->{'name_changed'}}, $jan31->{'format'}->{'output'}, '[9]');
};
#
# custom format
#------------------------------------------------------



#------------------------------------------------------
##- operator overloads
#
#if (1) {
#	my ($date, $otherdate);
#	
#	## create ezdate objects
#	$date = Date::EzDate2->new('January 3, 2001 5:15:00 pm');
#	$otherdate = Date::EzDate2->new('January 3, 2001 6:00:00 pm');
#	
#	# TESTING
#	println $date + 0;
#	
#	## dates should be equal
#	ok_check ('dates should be equal', $date == $otherdate);
#	
#	## overloaded addition
#	$date = Date::EzDate2->new('January 31, 2003 1:05:07 am');
#	$date++;
#	err_comp($date->{'{month short} {day of month}, {year}'}, 'Feb 01, 2003',  'overloaded addition');
#	ok 1;
#	
#	# overloaded subtraction
#	$date--;
#	err_comp($date->{'{month short} {day of month}, {year}'}, 'Jan 31, 2003',  'overloaded subtraction');
#	ok 1;
#};
#
# operator overloads
#------------------------------------------------------


#------------------------------------------------------
##- check all properties, Jan 31
#
if (1) {
	check_all(Date::EzDate2->new($jan31->{'in'}));
}
#
# check all properties, Jan 31
#------------------------------------------------------



#------------------------------------------------------
##- set properties
#
if (1) {
	my ($date, $alt);
	
	## January 31, 2002 12:59:07 pm
	$date = Date::EzDate2->new('January 31, 2002 12:59:07 pm');
	$date->{'hour'} = '01';
	$date->{'min'} = '05';
	$date->{'sec'} = '07';
	# showvar $date->{'full'};
	check_all($date);
	
	## January 31, 2002 12:59:07 pm
	$date = Date::EzDate2->new('January 31, 2002 12:59:07 pm');
	$date->{'ampmhour'} = '01';
	$date->{'ampm'} = 'am';
	$date->{'min no Zero'} = 5;
	$date->{'sec no Zero'} = 7;
	check_all($date);
	
	## March 31, 2001 1:05:07 pm
	$date = Date::EzDate2->new('March 31, 2001 1:05:07 pm');
	$date->{'year'} = '2002';
	$date->{'month num'} = '01';
	$date->{'weekday num'} = 4;
	$date->{'ampm lc'} = 'am';
	check_all($date);
	
	## January 29, 2002 1:05:07 pm
	$date = Date::EzDate2->new('January 29, 2002 1:05:07 pm');
	$date->{'ampm uc'} = 'AM';
	$date->{'weekday short'} = 'Thu';
	check_all($date);
	
	# Dec 1, 2031 11:55 pm
	# $date = Date::EzDate2->new('Dec 1, 2031 11:55 pm');
	# $date->{'day of month'} = '31';
	# $date->{'yeartwodigits'} = '02';
	# $date->{'month num base 1'} = '01';
	# $date->{'clocktime'} = '1:05:07am';
	# check_all($date);
	
	##- Dec 29, 2002 11:55:07 pm [1]
	$date = Date::EzDate2->new('Dec 29, 2002 11:55:07 pm');
	$date->{'month long'} = 'January';
	$date->{'WeekDay Long'} = 'Thursday';
	$date->{'miltime'} = '0105';
	# showvar $jan31->{'in'};
	# showvar $date->{'full'};
	check_all($date);
	
	##- Dec 29, 2002 11:55:07 pm [2]
	$date = Date::EzDate2->new('Dec 29, 2002 11:55:07 pm');
	$date->{'day of year'} = 31;
	$date->{'miltime'} = '0105';
	check_all($date);
	
	# Jan 1, 2002 11:55:07 pm
	# $date = Date::EzDate2->new('Jan 1, 2002 11:55:07 pm');
	# $date->{'Day of Month'} = 31;
	# $date->{'minofday'} = 65;
	# showvar $jan31->{'in'};
	# showvar $date->{'full'};
	# check_all($date);
	
	##- March 31, 2002 1:05:07 am - month short
	$date = Date::EzDate2->new('March 31, 2002 1:05:07 am');
	$date->{'month short'} = 'January';
	check_all($date);
	
	##- Dec 31, 2002 1:05:07 am - yearday
	$date = Date::EzDate2->new('Dec 31, 2002 1:05:07 am');
	$date->{'yearday'} = 31;
	check_all($date);
	
	##- January 29, 2003 11:00:07 pm
	$date = Date::EzDate2->new('January 29, 2003 11:00:07 pm');
	$date->{'%Y'} = 2002;         # %Y'} = 'year';
	$date->{'%a'} = 'thursday';
	$date->{'%H'} = 1;            # %H'} = 'hour';
	$date->{'%M'} = 5;            # %M'} = 'min';
	$date->{'%P'} = 'a';          # %P'} = 'ampmuc';
	$date->{'%S'} = 7;            # %S'} = 'sec';
	check_all($date);
	
	##- June 30, 2002 12:05:07 Pm
	$date = Date::EzDate2->new('June 30, 2002 12:05:07 Pm');
	$date->{'%h'} = 'JANUARY';   # %h'} = 'monthshort';
	$date->{'%d'} = 31;          # %d'} = 'dayofmonth';
	$date->{'%b'} = '01';        # %b'} = 'ampmhournozero';
	$date->{'%p'} = 'AM';        # %p'} = 'ampmlc';
	check_all($date);
	
	##- August 1, 2002 11:05:07 Am
	$date = Date::EzDate2->new('August 1, 2002 11:05:07 Am');
	$date->{'%B'} = '01';       # hournozero
	$date->{'%e'} = '01';       # monthnumbase1nozero
	$date->{'%f'} = '031';      # dayofmonthnozero
	check_all($date);
	
	##- January 01, 2002 1:05:07 am
	$date = Date::EzDate2->new('January 01, 2002 1:05:07 am');
	$date->{'%j'} = '031';  # yeardaybase1
	check_all($date);
	
	# January 31, 2002 1:05:07 am Thu
	# $date = Date::EzDate2->new('July 31, 2012 10:05:07 am');
	# $date->{'%y'} = '2002';   # %y'} = 'yeartwodigits';
	# $date->{'%m'} = '01';     # monthnumbase1
	# $date->{'%k'} = '01';     # ampmhour
	# $date->{'%w'} = '04';     # weekdaynum
	# check_all($date);
	
	##- January 31, 2002 1:05:07 am Thu
	$date = Date::EzDate2->new('January 30, 2002 1:05:07 am');
	$date->{'%a'} = 'THURSDAY';     # weekdayshort
	check_all($date);
	
	##- January 31, 2002 1:05:07 am Thu
	$date = Date::EzDate2->new('January 30, 2002 1:05:07 am');
	$date->{'%A'} = 'THUR';     # weekdaylong
	check_all($date);
};
#
# set properties
#------------------------------------------------------


#------------------------------------------------------------------------------
##- test revised monthnum algorithm
#
if (1) {
	my ($date);
	
	$date = Date::EzDate2->new('Dec 1, 2004 12:54:15');
	err_comp $date->{'{month short} {day of month}, {year} {clock time}'}, 'Dec 1, 2004 12:54 pm';
	
	$date->{'monthnum'}++;
	err_comp $date->{'{month short} {day of month}, {year} {clock time}'}, 'Jan 1, 2005 12:54 pm';
	
	ok(1);
};
#
# test revised monthnum algorithm
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# done
# The following code is purely for a home grown testing system. It has no
# purpose outside of my own system. -Miko
#
if ($ENV{'IDOCSDEV'}) {
	require FileHandle;
	FileHandle->new('> /tmp/regtest-done.txt') or die "unable to open check file: $!";
	print "[done]\n";
}
#
# done
#------------------------------------------------------------------------------


###############################################################################
# end of tests
###############################################################################



#------------------------------------------------------------------------------
# check all properties
#
sub check_all {
	my ($date) = @_;
	my ($alt);
	
	# TESTING
	# println subname(); ##i
	
	## beginning of month
	$alt = $date->clone;
	$alt->{'dayofmonth'} = 1;
	$alt->{'month'} = 'Feb';
	$alt->{'ampm'} = 'pm';
	$alt->{'year'} = 2000;
	
	# TESTING
	# showvar $date->{'full'};
	# showvar $alt->{'full'};
	
	## hour and ampm hour
	err_comp($date->{'hourtwodigits'}, '01',  'hour',     '[check_all: 1]');
	err_comp($date->{'ampmhour'},      '01',  'ampmhour', '[check_all: 2]');
	
	## am/pm
	err_comp($date->{'ampm'},      'am', '[check_all: 3]');
	err_comp($date->{'ampm lc'},   'am', '[check_all: 4]');
	err_comp($date->{'ampm uc'},   'AM', '[check_all: 5]');
	
	## minute
	err_comp($date->{'min'}, $date->{'Minute'}, '[check_all: 6]');
	err_comp($date->{'minutetwodigits'}, '05', '[check_all: 7]');
	err_comp($date->{'min no Zero'}, 5, '[check_all: 8]');
	
	## second
	err_comp($date->{'sec'}, $date->{'Second'});
	err_comp($date->{'sec'}, '7');
	err_comp($date->{'sec 2d'}, '07');
	err_comp($date->{'sec no Zero'}, 7);
	
	## weekdays
	err_comp($date->{'weekday num'},    4);
	err_comp($date->{'weekday short'},  'Thu');
	err_comp($date->{'WeekDay Long'},   'Thursday');
	
	## day of month
	err_comp($alt->{'day of month'}, '1');
	err_comp($alt->{'day of month two digits'}, '01');
	
	## month
	err_comp($date->{'month num'}, '1');
	err_comp($date->{'month num 2d'}, '01');
	err_comp($date->{'month long'}, 'January');
	err_comp($date->{'month short'}, 'Jan');
	
	## year
	err_comp($date->{'year'},          '2002');
	err_comp($date->{'yeartwodigits'}, '02');
	
	## day of year
	err_comp($date->{'day of year'}, 31);
	err_comp($date->{'day of year 3d'}, '031');
	
	## various time formats
	err_comp($date->{'clocktime'}, '1:05 am');
	err_comp($date->{'miltime'}, '0105');
	err_comp($alt->{'miltime'}, '1305');
	# err_comp($date->{'minofday'}, 65);
	
	## read-only's
	err_comp($date->{'leapyear'},      '0');
	err_comp($alt->{'leapyear'},     '1');
	err_comp($date->{'daysinmonth'},   '31');
	err_comp($alt->{'daysinmonth'},  '29');
	
	# Un*x-style date formatting
	
	## 01:05:07 Thu Jan 31, 2002
	err_comp($date->{'%a'}, 'Thu');                        #    weekday, short
	err_comp($date->{'%A'}, 'Thursday');                   #    weekday, long
	err_comp($date->{'%b'}, '1');                          #  * hour, 12 hour format, no leading zero
	err_comp($date->{'%B'}, '1');                          #  * hour, 24 hour format, no leading zero
	err_comp($date->{'%c'}, 'Thu Jan 31 01:05:07 2002');   #    full date
	err_comp($date->{'%d'}, '31');                         #    numeric day of the month
	err_comp($date->{'%D'}, '01/31/02');                   #    date as month/date/year
	err_comp($date->{'%e'}, '1');                          #  x numeric month, 1 to 12, no leading zero
	err_comp($date->{'%f'}, '31');                         #  x numeric day of month, no leading zero
	err_comp($date->{'%h'}, 'Jan');                        #    short month
	err_comp($date->{'%H'}, '01');                         #    hour 00 to 23
	err_comp($date->{'%j'}, '031');                        #    day of the year, 001 to 366
	err_comp($date->{'%k'}, '01');                         #    hour, 12 hour format
	err_comp($date->{'%m'}, '01');                         #    numeric month, 01 to 12
	err_comp($date->{'%M'}, '05');                         #    minutes
	err_comp($date->{'%n'}, "\n");                         #    newline
	err_comp($date->{'%P'}, 'AM');                         #  x AM/PM
	err_comp($date->{'%p'}, 'am');                         #  * am/pm
	err_comp($date->{'%r'}, '01:05:07 AM');                #    hour:minute:second AM/PM
	err_comp($date->{'%S'}, '07');                         #    seconds
	err_comp($date->{'%t'}, "\t");                         #    tab
	err_comp($date->{'%T'}, '01:05:07');                   #    hour:minute:second (24 hour format)
	err_comp($date->{'%w'}, '4');                          #    numeric day of the week, 0 to 6, Sun is 0
	err_comp($date->{'%y'}, '02');                         #    last two digits of the year
	err_comp($date->{'%Y'}, '2002');                       #    four digit year
	err_comp($date->{'%%'}, '%');                          #    percent sign
	
	# all good
	ok(1);
}
#
# check all properties
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# ok_check
#
sub ok_check {
	my ($test_name, $ok) = @_;
	
	# die on failure
	if (! $ok) {
		confess 'test fail: ' . $test_name;
	}
	
	# else ok
	ok(1);
}
#
# ok_check
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# err_comp
#
sub err_comp {
	my ($is, $should, $testname) = @_;
	
	if($is ne $should) {
		$testname ||= 'fail';
		
		print STDERR 
			"\n\n--- ", $testname, " -----------------------------------------\n",
			"is:     $is\n",
			"should: $should\n",
			"--------------------------------------------------------------\n";
		ok(0);
		
		# croak
		croak 'err_comp failure';
	}
}
#
# err_comp
#------------------------------------------------------------------------------


# success
# print "\nall tests successful\n";
