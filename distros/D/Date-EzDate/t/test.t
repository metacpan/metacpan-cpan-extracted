#!/usr/bin/perl -w
use strict;
use lib '../../';
use Date::EzDate ':all';
use Carp 'confess';
use Test::More;

# plan tests
plan tests => 1226;

# stub for err_comp
sub err_comp;

# turn off warnings
$Date::EzDate::default_warning = 0;

# Jan 31 date used for a lot of tests
my $jan31 = {};
$jan31->{'in'} = 'January 31, 2002 1:05:07 am';
$jan31->{'funky'} = 'January 31, 2002  1:05:07 am Thu';
$jan31->{'full'} = 'Thu Jan 31, 2002 01:05:07';
$jan31->{'dmy'} = '31JAN2002';
$jan31->{'format'}->{'name'} = 'mypattern';
$jan31->{'format'}->{'name_changed'} = 'My Pattern';
$jan31->{'format'}->{'pattern'} = '{Month Long} {Day Of Month} {Year} ({Weekday Long}) ({Day Of Year Base1 NoZero})';
$jan31->{'format'}->{'output'} = 'January 31 2002 (Thursday) (31)';

# TESTING
# use Debug::ShowStuff ':all';



#------------------------------------------------------------------------------
# basic creation
#
do {
	my ($date, $clone);
	my $name = 'basic creation';
	
	# current date and time
	$date = Date::EzDate->new();
	ok($date, "$name: cannot create for current date and time");
	
	# create with known date
	$date = Date::EzDate->new($jan31->{'in'})
		or die "cannot create with $jan31->{'in'}";
	err_comp($date->{'full'}, $jan31->{'full'}, "$name: create with known date");
	
	# a date in DDMMMYYYY format
	$date = Date::EzDate->new($jan31->{'dmy'})
		or die "cannot create with $jan31->{'in'}";
	err_comp($date->{'dmy'}, $jan31->{'dmy'}, "$name: a date in DDMMMYYYY format");
	
	# a little forgiveness
	$date = Date::EzDate->new($jan31->{'funky'})
		or die "cannot create with $jan31->{'funky'}";
	err_comp($date->{'full'}, $jan31->{'full'}, "$name: a little forgiveness");
	
	# clone
	$clone = $date->clone;
	err_comp($date->{'full'}, $clone->{'full'}, "$name: clone");
};
#
# basic creation
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# some dates that have been known to give us problems
#
do {
	my $mydate = Date::EzDate->new('Jan 15 2002, 21:01:26');
	$mydate->{'dmy'} = '25OCT2001';
	
	foreach my $i (1 .. 10)
		{$mydate->{'epochday'}++}
};
#
# some dates that have been known to give us problems
#------------------------------------------------------------------------------


#----------------------------------------------------------------------------------
# date parsing
#
do {
	my ($orgstr, $mydate, $settings);
	
	$orgstr = 'Sun Apr 26, 1970 00:00:07';
	$mydate = Date::EzDate->new($orgstr);
	
	err_comp($orgstr, $mydate->{'full'}, 'full', '[5]');
};
#
# date parsing
#----------------------------------------------------------------------------------


#----------------------------------------------------------------------------------
# $mydate->{'epochday'}++ hour compare
#
COMPARE: {
	my ($mydate, $olddate, $oldhour);
	
	$mydate = Date::EzDate->new('Jan 1, 1980 00:00:07');
	$olddate = $mydate->{'full'};
	$oldhour = $mydate->{'hour'};
	
	while ($mydate->{'year'} <= 2033) {
		$mydate->{'epochday'} += 13;
		
		if ($mydate->{'hour'} != $oldhour) {
			die
				"failed\n",
				"$olddate \t old:$oldhour \t new:$mydate->{'hour'}\n";
		}
		
		$oldhour = $mydate->{'hour'};
		$olddate = $mydate->{'full'};
	}
}
#
# $mydate->{'epochday'}++ hour compare
#----------------------------------------------------------------------------------


#------------------------------------------------------
# next_month
#
do {
	my ($date);
	my $name = 'next_month';
	
	# create with known date
	$date = Date::EzDate->new($jan31->{'in'});
	ok($date, "$name: create with $jan31->{'in'}");
	
	# next_month: go forward two months to March
	$date->next_month(2);
	err_comp(
		$date->{'Day of Month'},
		'31',
		"$name: next_month: go forward two months to March",
	);
	
	# go back to Feb of 2000
	$date->next_month(-25);
	err_comp(
		$date->{'Day of Month'},
		'29',
		"$name: go back to Feb of 2000",
	);
	
	# go forward to Feb of 2001
	$date->next_month(12);
	err_comp(
		$date->{'Day of Month'},
		'28',
		"$name: go forward to Feb of 2001",
	);
};
#
# next_month
#------------------------------------------------------



#------------------------------------------------------
# custom format
#
do {
	my ($date);
	my $name = 'custom format';
	
	# create with known date
	$date = Date::EzDate->new($jan31->{'in'})
		or die "cannot create with $jan31->{'in'}";
	
	# set format
	$date = Date::EzDate->new($jan31->{'in'})
		or die "cannot create with $jan31->{'in'}";
	
	# set the format
	$date->set_format($jan31->{'format'}->{'name'}, $jan31->{'format'}->{'pattern'});
	
	# check the format, using the same name but with different capitalization and spacing
	err_comp(
		$date->{$jan31->{'format'}->{'name_changed'}},
		$jan31->{'format'}->{'output'},
		$name,
	);
};
#
# custom format
#------------------------------------------------------



#------------------------------------------------------
# operator overloads
#
do {
	my ($date, $otherdate);
	my $name = 'operator overloads';
	
	$date = Date::EzDate->new('January 3, 2001 5:15:00 pm');
	$otherdate = Date::EzDate->new('January 3, 2001 6:00:00 pm');
	
	# compare two dates
	ok (($date == $otherdate), "$name: compare dates");
	
	# overloaded addition
	$date = Date::EzDate->new('January 31, 2003 1:05:07 am');
	$date++;
	err_comp(
		$date->{'{month short} {day of month}, {year}'},
		'Feb 01, 2003',
		"$name: overloaded addition",
	);
	
	# overloaded subtraction
	$date--;
	err_comp(
		$date->{'{month short} {day of month}, {year}'},
		'Jan 31, 2003',
		"$name: overloaded subtraction",
	);
};
#
# operator overloads
#------------------------------------------------------



# check all properties
check_all(Date::EzDate->new($jan31->{'in'}), 'initial');


#------------------------------------------------------
# set properties
#
do {
	my ($date, $alt, $name);
	
	$name = 'January 31, 2002 12:59:07 pm';
	$date = Date::EzDate->new($name);
	$date->{'hour'} = '01';
	$date->{'min'} = '05';
	$date->{'sec'} = '07';
	check_all($date, $name);
	
	$name = 'January 31, 2002 12:59:07 pm';
	$date = Date::EzDate->new($name);
	$date->{'ampmhour'} = '01';
	$date->{'ampm'} = 'am';
	$date->{'min no Zero'} = 5;
	$date->{'sec no Zero'} = 7;
	check_all($date, $name);
	
	$name = 'March 31, 2001 1:05:07 pm';
	$date = Date::EzDate->new($name);
	$date->{'year'} = '2002';
	$date->{'month num'} = '00';
	$date->{'weekday num'} = 4;
	$date->{'ampm lc'} = 'am';
	check_all($date, $name);
	
	$name = 'January 29, 2002 1:05:07 pm';
	$date = Date::EzDate->new($name);
	$date->{'ampm uc'} = 'AM';
	$date->{'weekday short'} = 'Thu';
	check_all($date, $name);
	
	$name = 'Dec 1, 2031 11:55 pm';
	$date = Date::EzDate->new($name);
	$date->{'day of month'} = '31';
	$date->{'yeartwodigits'} = '02';
	$date->{'month num base 1'} = '01';
	$date->{'clocktime'} = '1:05:07am';
	check_all($date, $name);
	
	$name = 'Dec 29, 2002 11:55:07 pm';
	$date = Date::EzDate->new($name);
	$date->{'month long'} = 'January';
	$date->{'WeekDay Long'} = 'Thursday';
	$date->{'miltime'} = '0105';
	check_all($date, $name);
	
	$name = 'Dec 29, 2002 11:55:07 pm';
	$date = Date::EzDate->new($name);
	$date->{'day of year'} = 30;
	$date->{'miltime'} = '105';
	check_all($date, $name);
	
	$name = 'Jan 1, 2002 11:55:07 pm';
	$date = Date::EzDate->new($name);
	$date->{'Day of Month'} = 31;
	$date->{'minofday'} = 65;
	check_all($date, $name);
	
	$name = 'March 31, 2002 1:05:07 am';
	$date = Date::EzDate->new($name);
	$date->{'month short'} = 'January';
	check_all($date, $name);
	
	$name = 'Dec 31, 2002 1:05:07 am';
	$date = Date::EzDate->new($name);
	$date->{'yearday'} = 30;
	check_all($date, $name);
	
	$name = 'Dec 31, 2002 1:05:07 am';
	$date = Date::EzDate->new($name);
	$date->{'yeardaybase1'} = 31;
	check_all($date, $name);
	
	$name = 'Dec 31, 2002 1:05:07 am';
	$date = Date::EzDate->new($name);
	$date->{'day of year base 1 no zero'} = 31;
	check_all($date, $name);
	
	$name = 'January 29, 2003 11:00:07 pm';
	$date = Date::EzDate->new($name);
	$date->{'%Y'} = 2002;         # %Y'} = 'year';
	$date->{'%a'} = 'thursday';
	$date->{'%H'} = 1;            # %H'} = 'hour';
	$date->{'%M'} = 5;            # %M'} = 'min';
	$date->{'%P'} = 'a';          # %P'} = 'ampmuc';
	$date->{'%S'} = 7;            # %S'} = 'sec';
	check_all($date, $name);
	
	$name = 'June 30, 2002 12:05:07 Pm';
	$date = Date::EzDate->new($name);
	$date->{'%h'} = 'JANUARY';   # %h'} = 'monthshort';
	$date->{'%d'} = 31;          # %d'} = 'dayofmonth';
	$date->{'%b'} = '01';        # %b'} = 'ampmhournozero';
	$date->{'%p'} = 'AM';        # %p'} = 'ampmlc';
	check_all($date, $name);
	
	$name = 'August 1, 2002 11:05:07 Am';
	$date = Date::EzDate->new($name);
	$date->{'%B'} = '01';       # hournozero
	$date->{'%e'} = '01';       # monthnumbase1nozero
	$date->{'%f'} = '031';      # dayofmonthnozero
	check_all($date, $name);
	
	$name = 'January 01, 2002 1:05:07 am';
	$date = Date::EzDate->new($name);
	$date->{'%j'} = '031';  # yeardaybase1
	check_all($date, $name);
	
	$name = 'July 31, 2012 10:05:07 am';
	$date = Date::EzDate->new($name);
	$date->{'%y'} = '2002';   # %y'} = 'yeartwodigits';
	$date->{'%m'} = '01';     # monthnumbase1
	$date->{'%k'} = '01';     # ampmhour
	$date->{'%w'} = '04';     # weekdaynum
	check_all($date, $name);
	
	$name = 'January 30, 2002 1:05:07 am';
	$date = Date::EzDate->new($name);
	$date->{'%a'} = 'THURSDAY';     # weekdayshort
	check_all($date, $name);
	
	$name = 'January 30, 2002 1:05:07 am';
	$date = Date::EzDate->new($name);
	$date->{'%A'} = 'THUR';     # weekdaylong
	check_all($date, $name);
	
	# removing this test: it assumes a particular
	# epoch second which may not be valid on the
	# specific system on which these tests are run.
	# 
	# January 31, 2002 1:05:07 am Thu
	#$date = Date::EzDate->new('July 31, 2012 10:05:07 am');
	#$date->{'%s'} = 1012457107;     # epochsec
	#check_all($date);
};
#
# set properties
#------------------------------------------------------



#------------------------------------------------------
# check epoch days around the epoch
#
do {
	my (@timevalues);
	my $name = 'check epoch days around the epoch';
	my $iterations = 10;
	
	# check if this system can handle negative epoch values
	@timevalues = localtime(-1);
	
	# skip block:
	SKIP: {
		# skip section
		if (! @timevalues) {
			skip 'this system cannot handle dates before the epoch', $iterations;
		}
		
		# variables
		my ($date, $control, @timevalues);
		
		# get date object and control day
		$date = Date::EzDate->new('Jan 4, 1970 5pm');
		$control = $date->{'epoch day'};
		
		foreach my $i (0..$iterations) {
			err_comp(
				$date->{'epoch day'},
				$control,
				"$name: iteration $i",
			);
			
			$control--;
			$date->{'epoch day'}--;
		}
	}
	
	ok(1, "$name: end");
};
#
# check epoch days around the epoch
#------------------------------------------------------


#------------------------------------------------------------------------------
# check for daylight savings time issue
#
do {
	my ($date);
	my $name = 'daylight savings time';
	
	$date = Date::EzDate->new('Jan 1, 2005 3pm');
	err_comp ($date->{'miltime'}, '1500', "$name: initial");
	
	$date->{'epoch day'} += 180;
	err_comp ($date->{'miltime'}, '1500', "$name: epoch day (1)");
	
	$date->{'epoch day'} += 180;
	err_comp ($date->{'miltime'}, '1500', "$name: epoch day (2)");
	
	ok(1, "$name: end");
};
#
# check for daylight savings time issue
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# revised monthnum algorithm
#
do {
	my ($date);
	my $name = 'revised monthnum algorithm';
	
	$date = Date::EzDate->new('Dec 1, 2004 12:54:15');
	
	err_comp
		$date->{'{month short} {day of month}, {year} {clock time}'},
		'Dec 01, 2004 12:54 pm',
		"$name: (1)";
	
	$date->{'monthnum'}++;
	
	err_comp
		$date->{'{month short} {day of month}, {year} {clock time}'},
		'Jan 01, 2005 12:54 pm',
		"$name: (2)";
	
	ok(1, "$name: end");
};
#
# revised monthnum algorithm
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# date_range_string
#
do {
	my $name = 'date_range_string';
	
	# same month and year
	err_comp
		date_range_string('Mar 5, 2004', 'Mar 7, 2004'),
		'Mar 5-7, 2004',
		"$name: same month and year";
	
	# same year, different months
	err_comp
		date_range_string('feb 20, 2004', 'mar 3, 2004'),
		'Feb 20-Mar 3, 2004',
		"$name: same year, different months";
	
	# different years
	err_comp
		date_range_string('Dec 23, 2004', 'Jan 3, 2005'),
		'Dec 23, 2004-Jan 3, 2005',
		"$name: different years";
	
	# same day
	err_comp
		date_range_string('Dec 23, 2004', 'Dec 23, 2004'),
		'Dec 23, 2004',
		"$name: same day";
	
	# expand array references
	err_comp
		date_range_string('May 3, 2005', 'May 5, 2005'),
		date_range_string( ['May 3, 2005', 'May 5, 2005'] ),
		"$name: expand array references";
	
	ok(1, "$name: end");
};
#
# date_range_string
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# time_range_string
#
do {
	my $name = 'time_range_string';
	
	# different am/pm
	err_comp
		time_range_string('10:00am','2:00pm'),
		'10:00am-2:00pm',
		"$name: different am/pm";
	
	# same am/pm
	err_comp
		time_range_string('10:00am', '11:00am'),
		'10:00-11:00am',
		"$name: same am/pm";
	
	ok(1, "$name: end");
};
#
# time_range_string
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# day_lumps
#
do {
	my (@dates, @lumps);
	my $name = 'day_lumps';
	
	@dates = (
		'Jan 3, 2005',
		'Jan 4, 2005',
		'Jan 5, 2005',
		'Jan 6, 2005',
		'Jan 10, 2005',
		'Jan 15, 2005',
		'Jan 16, 2005',
		'Jan 17, 2005',
	);
	
	@lumps = day_lumps(@dates);
	
	# lump 0: Jan 3-6, 2005
	err_comp
		date_range_string($lumps[0]),
		'Jan 3-6, 2005',
		"$name: lump 0: Jan 3-6, 2005";
	
	# lump 1: Jan 10, 2005
	err_comp
		date_range_string($lumps[1]),
		'Jan 10, 2005',
		"$name: lump 1: Jan 10, 2005";
	
	# lump 2: Jan 15-17, 2005
	err_comp
		date_range_string($lumps[2]),
		'Jan 15-17, 2005',
		"$name: lump 2: Jan 15-17, 2005";
	
	ok(1, "$name: end");
};
#
# day_lumps
#------------------------------------------------------------------------------



###############################################################################
# end of tests
###############################################################################



#------------------------------------------------------------------------------
# check all properties
# 
sub check_all {
	my ($date, $str) = @_;
	my ($alt);
	
	# prepend sub name to $str
	$str = "CAP - $str";
	
	# beginning of month
	$alt = $date->clone;
	$alt->{'dayofmonth'} = 1;
	$alt->{'month'} = 'Feb';
	$alt->{'ampm'} = 'pm';
	$alt->{'year'} = 2000;
	
	err_comp($date->{'hour'},      '01',  "$str: hour");
	err_comp($date->{'ampmhour'},  '01',  "$str: ampmhour");
	
	# am/pm
	err_comp($date->{'ampm'},      'am',  "$str: ampm");
	err_comp($date->{'ampm lc'},   'am',  "$str: ampm lc");
	err_comp($date->{'ampm uc'},   'AM',  "$str: ampm uc");
	
	# minute
	err_comp($date->{'min'},          $date->{'Minute'}, "$str: min (1)");
	err_comp($date->{'min'},          '05',              "$str: min (2)");
	err_comp($date->{'min no Zero'},  5,                 "$str: min no Zero");
	
	# second
	err_comp($date->{'sec'},         $date->{'Second'}, "$str: Second");
	err_comp($date->{'sec'},         '07',              "$str: 07");
	err_comp($date->{'sec no Zero'}, 7,                 "$str: sec no Zero");
	
	# weekdays
	err_comp($date->{'weekday num'},     4,          "$str: weekday num");
	err_comp($date->{'weekday short'},  'Thu',       "$str: weekday short");
	err_comp($date->{'WeekDay Long'},   'Thursday',  "$str: WeekDay Long");
	
	# day of month
	err_comp($alt->{'day of month'}, '01', "$str: day of month");
	
	# month
	err_comp($date->{'month num'},        '00',      "$str: month num");
	err_comp($date->{'month num base 1'}, '01',      "$str: month num base 1");
	err_comp($date->{'month long'},       'January', "$str: month long");
	err_comp($date->{'month short'},      'Jan',     "$str: month short");
	
	# year
	err_comp($date->{'year'},          '2002', "$str: year");
	err_comp($date->{'yeartwodigits'}, '02',   "$str: yeartwodigits");
	
	# day of year
	err_comp($date->{'day of year'},                30,    "$str: day of year");
	err_comp($date->{'day of year base 1'},         '031', "$str: day of year base 1");
	err_comp($date->{'day of year base 1 no zero'}, 31,    "$str: day of year base 1 no zero");
	
	# various time formats
	err_comp($date->{'clocktime'}, '1:05 am', "$str: clocktime");
	err_comp($date->{'miltime'},   '0105',    "$str: miltime");
	err_comp($alt->{'miltime'},    '1305',    "$str: miltime");
	err_comp($date->{'minofday'},   65,       "$str: minofday");
	
	# read-only's
	err_comp($date->{'leapyear'},     '0',   "$str: leapyear");
	err_comp($alt->{'leapyear'},      '1',   "$str: leapyear");
	err_comp($date->{'daysinmonth'},  '31',  "$str: daysinmonth");
	err_comp($alt->{'daysinmonth'},   '29',  "$str: daysinmonth");
	
	# Un*x-style date formatting
	
	# 01:05:07 Thu Jan 31, 2002
	err_comp($date->{'%a'}, 'Thu',                       "$str: \%a");  #    weekday, short
	err_comp($date->{'%A'}, 'Thursday',                  "$str: \%A");  #    weekday, long
	err_comp($date->{'%b'}, '1',                         "$str: \%b");  #  * hour, 12 hour format, no leading zero
	err_comp($date->{'%B'}, '1',                         "$str: \%B");  #  * hour, 24 hour format, no leading zero
	err_comp($date->{'%c'}, 'Thu Jan 31 01:05:07 2002',  "$str: \%c");  #    full date
	err_comp($date->{'%d'}, '31',                        "$str: \%d");  #    numeric day of the month
	err_comp($date->{'%D'}, '01/31/02',                  "$str: \%D");  #    date as month/date/year
	err_comp($date->{'%e'}, '1',                         "$str: \%e");  #  x numeric month, 1 to 12, no leading zero
	err_comp($date->{'%f'}, '31',                        "$str: \%f");  #  x numeric day of month, no leading zero
	err_comp($date->{'%h'}, 'Jan',                       "$str: \%h");  #    short month
	err_comp($date->{'%H'}, '01',                        "$str: \%H");  #    hour 00 to 23
	err_comp($date->{'%j'}, '031',                       "$str: \%j");  #    day of the year, 001 to 366
	err_comp($date->{'%k'}, '01',                        "$str: \%k");  #    hour, 12 hour format
	err_comp($date->{'%m'}, '01',                        "$str: \%m");  #    numeric month, 01 to 12
	err_comp($date->{'%M'}, '05',                        "$str: \%M");  #    minutes
	err_comp($date->{'%n'}, "\n",                        "$str: \\n");  #    newline
	err_comp($date->{'%P'}, 'AM',                        "$str: \%P");  #  x AM/PM
	err_comp($date->{'%p'}, 'am',                        "$str: \%p");  #  * am/pm
	err_comp($date->{'%r'}, '01:05:07 AM',               "$str: \%r");  #    hour:minute:second AM/PM
	err_comp($date->{'%S'}, '07',                        "$str: \%S");  #    seconds
	err_comp($date->{'%t'}, "\t",                        "$str: \\t");  #    tab
	err_comp($date->{'%T'}, '01:05:07',                  "$str: \%T");  #    hour:minute:second (24 hour format)
	err_comp($date->{'%w'}, '4',                         "$str: \%w");  #    numeric day of the week, 0 to 6, Sun is 0
	err_comp($date->{'%y'}, '02',                        "$str: \%y");  #    last two digits of the year
	err_comp($date->{'%Y'}, '2002',                      "$str: \%Y");  #    four digit year
	err_comp($date->{'%%'}, '%',                         "$str: \%\%"); #    percent sign
	
	ok(1, "$str: end");
}
#
# check all properties
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# err_comp
#
sub err_comp {
	my ($is, $should, $test_name) = @_;
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	# add got and should to test name
	$test_name .=
		' | is: ' . show_val($is) .
		' | got: ' . show_val($should);
	
	if($is ne $should) {
		if ($ENV{'IDOCSDEV'}) {
			print STDERR 
				"\n", $test_name, ":\n",
				"\tis:     $is\n",
				"\tshould: $should\n\n";	
		}
		
		ok(0, $test_name);
	}
	
	else {
		ok(1, $test_name);
	}
}
#
# err_comp
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# show_val
#
sub show_val {
	my ($str) = @_;
	
	# not defined
	if (! defined $str) {
		return '[undef]';
	}
	
	# empty string
	if ($str eq '') {
		return '[empty string]';
	}
	
	# no content string
	if ($str !~ m|\S|s) {
		return '[no content string]';
	}
	
	# else return value
	return $str;
}
#
# show_val
#------------------------------------------------------------------------------


# success
# print "\nall tests successful\n";
