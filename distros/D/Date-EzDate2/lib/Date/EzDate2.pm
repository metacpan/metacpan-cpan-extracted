package Date::EzDate2;
use strict;
use Carp 'croak';

# debugging tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# version
our $VERSION = '0.03';


#------------------------------------------------------------------------------
# pod
#

=head1 NAME

Date::EzDate2 - Date and time manipulation made easy

=head1 EzDate2 vs EzDate

EzDate2 is the next generation of the module Date::EzDate. EzDate2 provides
the same easy interface for dealing with date and time, but uses DateTime
to provide a wider and more accurate set of services.

EzDate2 is *NOT* a drop-in replacement for EzDate. That's why it's not just
an updated version of EzDate.

This early release is just to test EzDate2's distribution on CPAN. It's not yet
ready for prime time.

=head1 SYNOPSIS

An EzDate2 object represents a single point in time and exposes all properties
of that point.  It also makes it easy to change those properties to produce
a different point in time.  EzDate2 has many features, here are a few:

 use Date::EzDate2;
 my $mydate = Date::EzDate2->new();

 # output some date information
 print $mydate, "\n";  # e.g. output: Fri Jul 22, 2016 16:53:33

=cut

#
# pod
#------------------------------------------------------------------------------


# warn levels
use constant WARN_NONE   => 0;
use constant WARN_STDERR => 1;
use constant WARN_CROAK  => 2;
our $default_warning = WARN_STDERR;

# default time zone
our $default_time_zone = undef;


#------------------------------------------------------------------------------
# object overloading
#
use overload
	'""'     => sub{$_[0]->{'default'}}, # stringification
	'<=>'    => \&compare,               # comparison
	'+'      => \&addition,              # addition
	'-'      => \&subtraction,           # subtraction
	fallback => 1;                       # operations not defined here
#
# object overloading
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# new
#
sub new {
	my ($class, $time, %opts) = @_;
	my ($rv, %tiehash);
	
	# TESTING
	# println subname(); ##i
	
	# create tied hash
	tie(%tiehash, $class . '::Tie', $time, %opts) or return undef;
	
	# create blessed reference to tied hash
	$rv = bless(\%tiehash, $class);
	
	# return
	return $rv;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# clone
#
sub clone {
	my ($ezdate) = @_;
	
	# TESTING
	# println subname(), ' - ', __PACKAGE__; ##i
	
	# call tied object's new()
	return ref($ezdate)->new($ezdate);
}
#
# clone
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# next_month
#
sub next_month {
	my ($ezdate, $count) = @_;
	
	# TESTING
	# println subname(); ##i
	
	# call tied object's next_month()
	return tied(%$ezdate)->next_month($count);
}
#
# next_month
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# settings and utility subs
#
sub zero_hour_ampm {return $_[0]->tie_ob->{'zero_hour_ampm'} = $_[1]}

sub set_format {return $_[0]->tie_ob->set_format(@_[1..$#_])}

sub get_format {
	my ($self, $key) = @_;
	my $ob = $self->tie_ob;
	$key =~ s|\s||gs;
	$key = lc($key);
	return join('', @{$ob->{'formats'}->{$key}});
}

sub del_format {return delete $_[0]->{$_[1]}}
sub tie_ob{return tied(%{$_[0]})}

# warnings level
sub set_warnings {
	my ($ezdate, $level) = @_;
	
	# TESTING
	# println subname(); ##i
	
	# level must be defined
	if (! defined $level)
		{ croak 'level-not-defined: warning level is not defined' }
	
	# normalize
	$level = lc($level);
	$level =~ s|\s||gs;
	
	# plain english
	if ($level eq 'none')
		{ $level = WARN_NONE }
	elsif ($level eq 'stderr')
		{ $level = WARN_STDERR }
	elsif ($level eq 'croak')
		{ $level = WARN_CROAK }
	elsif ($level eq 'default')
		{ $level = $default_warning }
	
	# set tied object
	return $ezdate->tie_ob->{'warnings'} = $level;
}

#
# settings and utility subs
#------------------------------------------------------------------------------


###############################################################################
# Date::EzDate2::Tie
#
package Date::EzDate2::Tie;
use strict;
use DateTime;
use DateTime::TimeZone;
use Carp qw{carp croak};
use Clone;
use base 'Tie::Hash';

# debugging tools
# use Debug::ShowStuff ':all';


#------------------------------------------------------------------------------
# globals
#
our (
	@ltimefields, @OrdWords, $OrdWordsRx, %PCodes, %WeekDayNums,
	%OrdWordsNums, @OrdNums, %MonthNums, $pcode,
);

# localtime() fields
# @ltimefields = qw[sec min hour dayofmonth monthnum year weekdaynum yearday dst];
@ltimefields = qw[sec min hour dayofmonth monthnum year];

# words for the days of the month
@OrdWords = qw[
	Zeroth First Second Third Fourth Fifth Sixth Seventh Eighth Ninth Tenth
	Eleventh Twelfth Thirteenth Fourteenth Fifteenth Sixteenth Seventeenth
	Eighteenth Ninteenth Twentieth Twentyfirst Twentysecond Twentythird
	Twentyfourth Twentyfifth Twentysixth Twentyseventh Twentyeighth Twentyninth
	Thirtieth Thirtyfirst
];

# regular expression versions of OrdWords
$OrdWordsRx = '\b(' . join('|', @OrdWords[1..$#OrdWords]) . ')\b';

# build hash or ord words
foreach my $i (1..$#OrdWords)
	{ $OrdWordsNums{lc($OrdWords[$i])} = $i }

# number ordinals
@OrdNums = qw[
	0th 1st 2nd 3rd 4th 5th 6th 7th 8th 9th 10th 11th 12th 13th 14th 15th 16th
	17th 18th 19th 20th 21st 22nd 23rd 24th 25th 26th 27th 28th 29th 30th 31st
];

# month numbers
@MonthNums{qw[jan feb mar apr may jun jul aug sep oct nov dec]} = (1..12);

# weekday numbers
$WeekDayNums{'mon'} = 1;
$WeekDayNums{'tue'} = 2;
$WeekDayNums{'wed'} = 3;
$WeekDayNums{'thu'} = 4;
$WeekDayNums{'fri'} = 5;
$WeekDayNums{'sat'} = 6;
$WeekDayNums{'sun'} = 7;

# @WeekDayShort = qw[Sun Mon Tue Wed Thu Fri Sat];
# @WeekDayLong  = qw[Sunday Monday Tuesday Wednesday Thursday Friday Saturday];
# @MonthShort   = qw[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec];
# @MonthLong    = qw[January February March April May June July August September October November December];
# @MonthDays    = qw[31 x 31 30 31 30 31 31 30 31 30 31];

# percent code regex
$pcode = '^\%[\w\%]$';

# warn levels
use constant WARN_NONE   => Date::EzDate2::WARN_NONE;
use constant WARN_STDERR => Date::EzDate2::WARN_STDERR;
use constant WARN_CROAK  => Date::EzDate2::WARN_CROAK;

%PCodes = qw[
	yearlong         year
	yearshort        yeartwodigit
	dayofyear        yearday
	dayofyear3d      yearday3d
	dayofweeknum     weekdaynum
	dayofweeknum2d   weekdaynum2d
	%Y               year
	%y               yeartwodigit
	%a               weekdayshort
	%A               weekdaylong
	%d               dayofmonth
	%D               {monthnum2d}/{dayofmonth2d}/{year2d}
	%H               hour2d
	%h               monthshort
	%b               ampmhournozero
	%B               hournozero
	%e               monthnum
	%m               monthnum2d
	%j               dayofyear3d
	%f               dayofmonthnozero
	%k               ampmhour
	%M               min2d
	%P               ampmuc
	%p               ampmlc
	%s               epochsec
	%S               sec2d
	%w               weekdaynum
	%y               yeartwodigit
	%T               %H:%M:%S
	%n               newline
	%t               tab
	%%               percent
];

$PCodes{'%c'} = '{weekdayshort} %h %d {hour2d}:{min2d}:{sec2d} %Y';
$PCodes{'%r'} = '%k:%M:%S %P';

#
# globals
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# TIEHASH
#
sub TIEHASH {
	my ($class, $time, %opts) = @_;
	my $eztied = bless ({}, $class);
	
	# TESTING
	# println subname(); ##i
	
	# set some non-date properties
	# $eztied->{'zero_hour_ampm'} = defined($opts{'zero_hour_ampm'}) ? $opts{'zero_hour_ampm'} : 1;
	$eztied->{'formats'} = {};
	$eztied->{'settings'} = {'dst_kludge' => 1};
	
	# default builtin formats
	$eztied->set_format('fullday',    '{month short} {day of month no zero}, {year}');
	$eztied->set_format('fulldate',   '{fullday}');
	$eztied->set_format('dayandtime', '{month short} {day of month}, {year} {ampmhour no zero}:{minute}{ampm}');
	$eztied->set_format('default',    '{full}');
	
	# if clone
	if (UNIVERSAL::isa $time, 'Date::EzDate2'){
		$eztied->clone($time);
	}
	
	# else
	else {
		# set DateTime object to current time
		$eztied->{'dt'} = DateTime->now(
			time_zone =>
				$Date::EzDate::default_time_zone ||
				DateTime::TimeZone->new( name => 'local' )->name(),
		);
		
		# if time is a scalar and has content, call timefromstring()
		if ( defined($time) && (! ref $time) && ($time =~ m|\S|s) ) {
			$eztied->timefromstring($time);
		}
	}
	
	# return
	return  $eztied;
}
#
# TIEHASH
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# clone
#
sub clone {
	my ($new, $old) = @_;
	
	# TESTING
	# println subname(), ' - ', __PACKAGE__; ##i
	
	# ensure we're using the tied hash
	if ( UNIVERSAL::isa $old, 'Date::EzDate2' )
		{ $old = $old->tie_ob() }
	
	# formats and settings
	$new->{'formats'} = Clone::clone($old->{'formats'});
	$new->{'settings'} = Clone::clone($old->{'settings'});
	
	# datetime object
	$new->{'dt'} = $old->{'dt'}->clone();
	
	# return
	return $new;
}
#
# clone
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# STORE
#
our $left_brace_rx = quotemeta('{');

sub STORE {
	my ($eztied, $key, $val) = @_;
	my (%set, $orgkey, $orgval, $dt);
	
	# TESTING
	# println subname(); ##i
	
	# hold on to original values
	$orgkey = $key;
	$orgval = $val;
	
	# error checking
	if (! defined $val) {
		return $eztied->warn(
			'value-not-defined-in-store: ' .
			'Must send a defined value when setting a ' .
			'property of an EzDate object'
		);
	}
	
	# if value contains {, assume they're assigning a format
	$val =~ m|$left_brace_rx| and return $eztied->set_format($key, $val);
	
	# normalize key
	normalize_key($key);
	$key = $eztied->get_alias($key, 'strip_no_zero'=>1);
	
	# TESTING
	# showvar $key;
	
	# normalize value
	$val = lc($val);
	$val =~ s|^\s+||gs;
	$val =~ s|\s+$||gs;
	$val =~ s|\s+| |gs;
	
	# TESTING
	# println $key, ': ', $val;
	
	# get DateTime object
	$dt = $eztied->{'dt'};
	
	# day of month
	if ($key eq 'dayofmonth') {
		$set{'day'} = $val;
	}
	
	# year
	elsif ($key eq 'year') {
		$set{'year'} = $val;
	}
	
	# month
	elsif ( ($key eq 'month') || ($key eq 'monthnum') || ($key eq 'monthlong') || ($key eq 'monthshort') ) {
		# letters
		unless ( $val =~ m|^\d+$|si ) {
			# get just first three letters
			$val =~ s|\s||gs;
			$val = substr($val, 0, 3);
			
			# if a month number exists, use it, else throw error
			# KLUDGE: assuming English names for now, will work with
			# DateTime's locale functions later.
			if (my $num = $MonthNums{$val}) {
				$val = $num;
			}
			else {
				return $eztied->warn(
					"invalid-month-name: do not know this month name: $orgval"
				)
			}
		}
		
		# set month
		$set{'month'} = $val;
	}
	
	# weekday
	elsif ( ($key eq 'weekday') || ($key eq 'weekdaynum') || ($key eq 'weekdayshort') || ($key eq 'weekdaylong') ) {
		# if not integer, get integer value
		unless ($val =~ m|^\d+$|s) {
			# get just first three letters
			$val = lc($val);
			$val =~ s|\s||gs;
			$val = substr($val, 0, 3);
			
			# attempt to get value
			unless ($val = $WeekDayNums{$val}) {
				return $eztied->warn(
					"invalid-weekday-name: do not know this weekday name: $orgval"
				)
			}
		}
		
		# set day
		unless ( $val == $dt->day_of_week ) {
			$set{'day'} = $dt->day + $val - $dt->day_of_week;
		}
	}
	
	# yearday
	elsif ( ($key eq 'yearday') || ($key eq 'yearday3d') ) {
		my ($current);
		
		# check for integer and range
		$eztied->integer_check($key, $val)
			or return 0;
		
		# get current value
		$current = $dt->day_of_year();
		
		# if they're not equal, set to new day of year
		unless ($current == $val) {
			# add days
			$dt->add(
				days     =>  $val - $current,
			);
			
			# return
			return 1;
		}
	}
	
	# hour
	elsif ( ($key eq 'hour') || ($key eq 'hour2d') ) {
		# check for integer and range
		$eztied->integer_check($key, $val)
			or return 0;
		
		# assign value
		$set{'hour'} = $val;
	}
	
	# minute
	elsif ( ($key eq 'min') || ($key eq 'min2d') ) {
		# check for integer
		$eztied->integer_check($key, $val)
			or return 0;
		
		# assign value
		$set{'minute'} = $val;
	}
	
	# second
	elsif ( ($key eq 'sec') || ($key eq 'sec2d') ) {
		# check for integer and range
		$eztied->integer_check($key, $val)
			or return 0;
		
		# assign value
		$set{'second'} = $val;
	}
	
	# ampm
	elsif ( ($key eq 'ampm') || ($key eq 'ampmlc') || ($key eq 'ampmuc') ) {
		my ($current);
		
		# add 'm' to just or or p
		if (length($val) == 1)
			{$val .= 'm'}
		
		# normalize
		$val =~ s|\s||gs;
		
		# error checking
		unless ( ($val eq 'am') || ($val eq 'pm') )
			{ return $eztied->warn('invalid-ampm: ampm may only be set to am or pm') }
		
		# get dt object
		$current = $dt->hour;
		
		# if no change, we're done
		if ($current < 12) {
			if ($val eq 'am')
				{ return 1}
		}
		else {
			if ($val eq 'pm')
				{ return 1}
		}
		
		# set change
		if ($val eq 'am')
			{ $set{'hour'} = $current - 12 }
		else
			{ $set{'hour'} = $current + 12 }
	}
	
	# ampmhour
	elsif ($key eq 'ampmhour') {
		# check for integer
		$eztied->integer_check($key, $val)
			or return 0;
		
		# add twelve if necessary
		if ($dt->hour >= 12)
			{ $val += 12 }
		
		# set
		$set{'hour'} = $val;
	}
	
	# miltime
	elsif ($key eq 'miltime') {
		# must ve exactly four digits
		unless ($val =~ m|^\d{4}$|s)
			{ return $eztied->warn('invalid-miltime: miltime must consist of exactly four digits') }
		
		# set
		$set{'hour'} = substr($val, 0, 2);
		$set{'minute'} = substr($val, 2, 2);
	}
	
	# dmy
	elsif ($key eq 'dmy') {
		my (@tokens, $day, $month, $year);
		
		# split
		$val = lc($val);
		@tokens = split(m/(\d+)|([a-z]+)/si, $val);
		@tokens = grep {defined $_} @tokens;
		@tokens = grep {m|\S|s} @tokens;
		
		# get values
		($day, $month, $year) = @tokens;
		
		# check day
		$eztied->integer_check("$key - day", $day)
			or return 0;
		
		# normalize month
		$month = substr($month, 0, 3);
		
		# if a month number exists, use it, else throw error
		# KLUDGE: assuming English names for now, will work with
		# DateTime's locale functions later.
		if (my $num = $MonthNums{$month}) {
			$month = $num;
		}
		else {
			return $eztied->warn(
				"invalid-month-name: do not know this month name: $orgval"
			)
		}
		
		# check year
		$eztied->integer_check("$key - year", $year)
			or return 0;
		
		# set
		$set{'day'} = $day;
		$set{'month'} = $month;
		$set{'year'} = $year;
	}
	
	#	elsif ($key eq 'minofday') {
	#		$eztied->setfromtime (
	#			DST_ADJUST_NO,
	#			$eztied->{'epochsec'} - ($eztied->{'hour'} * t_60_60)  - ($eztied->{'min'} * 60) + ($val * 60)
	#		)
	#	}
	#	
	#	elsif ($key eq 'hour') {
	#		$val = timelocal(
	#			$eztied->{'sec'},
	#			$eztied->{'min'},
	#			$val,
	#			$eztied->{'dayofmonth'},
	#			$eztied->{'monthnum'},
	#			$eztied->{'year'},
	#		);
	#		
	#		$eztied->setfromtime(DST_ADJUST_NO, $val);
	#	}
	#	
	#	# hour and minute
	#	elsif ( ($key eq 'clocktime') || ($key =~ m|^mil(itary)?time$|) ) {	
	#		my ($changed, $hour, $min, $sec) = $eztied->gettime($val);
	#		
	#		unless (defined $hour)
	#			{$hour = $eztied->{'hour'}}
	#		unless (defined $min)
	#			{$min = $eztied->{'min'}}
	#		unless (defined $sec)
	#			{$sec = $eztied->{'sec'}}
	#		
	#		$eztied->setfromtime
	#			(
	#			0,
	#			$eztied->{'epochsec'}
	#			
	#			- ($eztied->{'sec'})
	#			- ($eztied->{'min'} * 60)
	#			- ($eztied->{'hour'} * t_60_60)
	#			
	#			+ ($sec)
	#			+ ($min * 60)
	#			+ ($hour * t_60_60)
	#			);
	#	}
	#	
	#	elsif ($key eq 'dst')
	#		{return $eztied->warn('dst property is read-only')}
	#	
	#	elsif ($key eq 'epochsec')
	#		{$eztied->setfromtime(DST_ADJUST_NO, $val)}
	#	
	#	elsif ($key eq 'epochmin')
	#		{$eztied->setfromtime(DST_ADJUST_NO, $eztied->{'epochsec'} - ($eztied->getepochmin * 60) + ($val * 60) )}
	#	
	#	elsif ($key eq 'epochhour')
	#		{$eztied->setfromtime(DST_ADJUST_NO, $eztied->{'epochsec'} - ($eztied->getepochhour * t_60_60) + ($val * t_60_60) )}
	#	
	#	elsif ($key eq 'epochday') {
	#		my ($oldhour, $oldepochsec, $oldmin);
	#		
	#		$eztied->setfromtime(
	#			DST_ADJUST_YES,
	#			$eztied->{'epochsec'} - ($eztied->getepochday * t_60_60_24) + (int($val) * t_60_60_24)
	#		);
	#	}
	#	
	#	# ordinals
	#	elsif ($key =~ m/dayofmonthord(word|num)?/) {
	#		# if numeric
	#		if ($val =~ s|^(\d+)\s*\w*$|$1|s)
	#			{$eztied->STORE('dayofmonth', $val)}
	#		
	#		# else word
	#		else {
	#			my $nval = $val;
	#			$nval =~ tr/A-Z/a-z/;
	#			$nval =~ s|\W||gs;
	#		
	#			# if no such ordinal exists
	#			unless ($nval = $OrdWordsNums{$nval})
	#				{ return $eztied->warn("Invalid ordinal: $val") }
	#			
	#			$eztied->STORE('dayofmonth', $nval);
	#		}
	#	}
	#	
	#	elsif ($key eq 'year') {
	#		my ($maxday, $targetday);
	#		
	#		# if same year, nothing to do
	#		if ($eztied->{'year'} == $val)
	#			{return}
	#		
	#		# make sure day of month isn't greater than maximum day of target month
	#		$maxday = daysinmonth($eztied->{'monthnum'}, $val);
	#		
	#		if ($eztied->{'dayofmonth'} > $maxday) {
	#			$eztied->warn(
	#				"Changing the year sets day of month ($eztied->{'dayofmonth'}) to higher than days in month ($maxday); ",
	#				"setting the day down to $maxday"
	#				);
	#			$targetday = $maxday;
	#		}
	#		else
	#			{$targetday = $eztied->{'dayofmonth'}}
	#		
	#		$val = timelocal($eztied->{'sec'}, $eztied->{'min'}, $eztied->{'hour'}, $targetday, $eztied->{'monthnum'}, $val);
	#		$eztied->setfromtime(DST_ADJUST_YES, $val);
	#	}
	#	
	#	elsif ($key =~ m/^year(two|2)digit/) {
	#		$val =~ s|^.*(..)$|$1|;
	#		$eztied->STORE('year', substr($eztied->{'year'}, 0, 2) . zeropad_2($val));
	#	}
	#	
	#	elsif ($key =~ m/^monthnumbase(one|1)/)
	#		{$eztied->STORE('monthnum', $val - 1)}
	#	
	#	
	#	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	#	# monthnum
	#	#
	#	elsif ($key eq 'monthnum') {
	#		my ($target, $epoch_second);
	#		my $month = $eztied->{'monthnum'};
	#		my $year = $eztied->{'year'};
	#		my $orgday = $eztied->{'dayofmonth'};
	#		my $dayofmonth = $eztied->{'dayofmonth'};
	#		my $jumps = $val - $month;
	#		
	#		# if nothing to do
	#		$jumps or return;
	#		
	#		$target = $jumps;
	#		$target = abs($target);
	#		
	#		# jumping forward
	#		if ($jumps > 0) {
	#			foreach (1..$target) {
	#				# if end of year
	#				if ($month == 11) {
	#					$month = 0;
	#					$year++;
	#				}
	#				else
	#					{$month++}
	#			}
	#		}
	#		
	#		# jumping backward
	#		else {
	#			foreach (1..$target) {
	#				# if beginning of year
	#				if ($month == 0) {
	#					$month = 11;
	#					$year--;
	#				}
	#				else
	#					{$month--}
	#			}
	#		}
	#		
	#		
	#		# adjust day for shorter month (if necessary)
	#		if ($dayofmonth > 28) {
	#			my $dim = daysinmonth($month, $year);
	#			
	#			if ($dim < $dayofmonth)
	#				{ $dayofmonth = $dim }
	#		}
	#		
	#		# get epoch second from timelocal
	#		$epoch_second = timelocal($eztied->{'sec'}, $eztied->{'min'}, $eztied->{'hour'}, $dayofmonth, $month, $year);
	#		$eztied->setfromtime(DST_ADJUST_NO, $epoch_second);
	#	}
	#	#
	#	# monthnum
	#	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	#	
	#	
	#	elsif ( ($key eq 'monthshort') || ($key eq 'monthlong') )
	#		{$eztied->STORE('monthnum', $MonthNums{lc(substr($val, 0, 3))})}
	#	
	#	elsif (
	#		($key eq 'weekdayshort') ||
	#		($key eq 'weekdaylong') ||
	#		($key eq 'dayofweekshort') ||
	#		($key eq 'dayofweeklong')
	#		) {
	#		$eztied->STORE(
	#			'weekdaynum',
	#			$WeekDayNums{lc(substr($val, 0, 3))})
	#	}
	#	
	#	else
	#		{ return $eztied->warn("Do not understand key: $orgkey") }
	
	# else don't know key
	else {
		# TESTING
		# die "unknown-name-for-store: do not know this property name: $orgkey";
		
		# return with warning
		return $eztied->warn(
			"unknown-name-for-store: do not know this property name: $orgkey"
		)
	}
	
	# set new date and time
	$eztied->new_date_time(\%set);
	
	# return value
	return $val;
}
#
# STORE
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# integer_check
#
sub integer_check {
	my ($eztied, $key, $val) = @_;
	
	# TESTING
	# println subname(); ##i
	
	# must be all digit and greater than zero
	unless ( defined($val) && ($val =~ m|^\d+$|s) && ($val > 0) ) {
		# warn
		$eztied->warn(
			"not-integer-for-$key: " .
			"the value for $key must be a positive integer but is " .
			(defined($val) ? "\"$val\"" : 'undef') . ' ' .
			"instead"
		);
		
		# return false
		return 0;
	}
	
	# return true
	return 1;
}
#
# integer_check
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# timefromstring
#

# today, now, yesterday, tomorrow
our %relative = (
	today => 1,
	now => 1,
	yesterday => 1,
	tomorrow => 1,
);

# map time units to duractions
#my %duration_map = (
#	year => 'years',
#	month => 'months',
#	day => 'days',
#	hour => 'hours',
#	minute => 'minutes',
#	second => 'seconds',
#);

sub timefromstring {
	my ($eztied, $val, %opts) = @_;
	
	# TESTING
	# println subname(); ##i
	
	# error checking
	if (! defined $val)
		{ return $eztied->warn('time-string-not-defined: did not get a defined time string') }
	
	# alias hour am/pm to hour:00 am/pm
	# $eztied->{'zero_hour_ampm'} and $val =~ s/(^|[^:\d])(\d+)\s*([ap]m)/$1$2:00:00 $3/gis;
	# $eztied->{'zero_hour_ampm'} and $val =~ s/(^|[^:\d])(\d+)\s*([ap]m?\b)/$1$2:00:00 $3/gis;
	
	# normalize
	# $val = lc($val);
	$val =~ s|^\s+||s;
	$val =~ s|\s+$||s;
	$val =~ s|\s+| |s;
	
	# if just an integer
	if ($val =~ m/^\d+$/i) {
		my ($year, $month, $day, $hour, $min, $sec, $doy, $dow, $dst) = Gmtime($val);
		
		# set from gmtime
		$eztied->{'year'} = $year;
		$eztied->{'monthnum'} = $month;
		$eztied->{'dayofmonth'} = $day;
		$eztied->{'hour'} = $hour;
		$eztied->{'min'} = $min;
		$eztied->{'sec'} = $sec;
	}
	
	# elsif today, now, yesterday, tomorrow
	elsif ($relative{lc $val}) {
		# lowercase
		$val = lc($val);
		
		# today
		if ( ($val eq 'today') || ($val eq 'now') ) {
			$eztied->setfromtime();
		}
		
		# tomorrow
		if ($val eq 'tomorrow') {
			$eztied->setfromtime();
			
			@$eztied{qw{year monthnum dayofmonth}} =
				Add_Delta_Days(@$eztied{qw{year monthnum dayofmonth}}, 1);
		}
		
		# yesterday
		if ($val eq 'yesterday') {
			$eztied->setfromtime();
			
			@$eztied{qw{year monthnum dayofmonth}} =
				Add_Delta_Days(@$eztied{qw{year monthnum dayofmonth}}, -1);
		}
	}
	
	# else a date string
	else {
		my (%set);
		
		# TESTING
		# println 'date string'; ##i
		# showvar $val;
		
		# special case: ##:##.#####
		# In some time formats, the hour, min, second is
		# followed by fractional seconds.  We don't handle those
		# fractions, so we'll just remove them.
		$val =~ s/(\d+\:\d+)\.[\d\-]+/$1/g;
		
		# Another special case: A.M. to AM and P.M. to PM
		$val =~ s/a\.m\b/am/gis;
		$val =~ s/p\.m\b/pm/gis;
		
		# remove time zone if it exists
		if ( $val =~ s|[a-z_]+\s*/\s*[a-z_]+$||si ) {
			$set{'time_zone'} = $&;
			$val =~ s|\s+$||s;
		}
		
		# normalize
		$val = lc($val);
		$val =~ s/[^\w:]/ /g;
		$val =~ s/\s*:\s*/:/g;
		
		# change ordinals to numbers
		$val =~ s|$OrdWordsRx|$OrdWordsNums{$1}|gis;
		$val =~ s/(\d)(th|rd|st|nd)\b/$1/gis;
		
		# noon to 12:00:00
		# midnight to 00:00:00
		$val =~ s/\bnoon\b/ 12:00:00 /gis;
		$val =~ s/\bmidnight\b/ 00:00:00 /gis;
		
		# normalize some more
		$val =~ s/(\d)([a-z])/$1 $2/g;
		$val =~ s/([a-z])(\d)/$1 $2/g;
		$val =~ s/\s+/ /g;
		$val =~ s/^\s*//;
		$val =~ s/\s*$//;
		$val =~ s/([a-z]{3})[a-z]+/$1/gs;
		
		# remove weekday
		# TOD0: use localized names of weekdays
		$val =~ s/((sun)|(mon)|(tue)|(wed)|(thu)|(fri)|(sat))\s*//;
		$val =~ s/\s*$//;
		
		# attempt to get time
		unless ($opts{'dateonly'}) {
			($val, @set{qw{hour minute second}}) = $eztied->gettime($val, 'skipjustdigits'=>1);
		}
		
		# attempt to get date
		unless ($opts{'timeonly'}) {
			if (length $val) {
				($val, @set{qw{day month year}}) = getdate($val);
			}
		}
		
		# attempt to get time again
		unless ($opts{'dateonly'}) {
			if (length($val) && (! defined($set{'hour'})) ) {
				my ($hour_new, $min_new, $sec_new);
				
				# parse again
				($val, $hour_new, $min_new, $sec_new) = $eztied->gettime($val, 'skipjustdigits'=>1, 'croakonfail'=>1);
				
				# set from new valued if they are defined
				defined($hour_new) and $set{'hour'} = $hour_new;
				defined($min_new)  and $set{'minute'} = $min_new;
				defined($sec_new)  and $set{'second'} = $sec_new;
			}
		}
		
		# is somehow we don't still have a defined string, return
		if (! defined $val)
			{ return 0 }
		
		# trim
		$val =~ s/^\s*//;
		
		# create new datetime object
		if (%set) {
			$eztied->new_date_time(\%set);
		}
	}
	
	# return
	return 1;
}
#
# timefromstring
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# new_date_time
#
sub new_date_time {
	my ($eztied, $set) = @_;
	my ($old, $new, %offset);
	
	# TESTING
	# println subname(); ##i
	
	# old datetime object
	$old = $eztied->{'dt'};
	
	# create new datetime object with just year
	$new = DateTime->new(
		year => coal($set->{'year'}, $old->year),
		time_zone  => $set->{'time_zone'} || $old->time_zone,
	);
	
	# delete year
	delete $set->{'year'};
	
	# build duration
	foreach my $key (keys %$set) {
		if (defined $set->{$key}) {
			$offset{$key . 's'} = $set->{$key};
		}
	}
	
	# decrement months and days
	foreach my $key (qw{months days}) {
		if (defined $offset{$key})
			{ $offset{$key}-- }
	}
	
	# add offset to new datetime object
	$new->add(
		months   =>  coal($offset{'months'},   $old->month  -  1  ),
		days     =>  coal($offset{'days'},     $old->day    -  1  ),
		hours    =>  coal($offset{'hours'},    $old->hour         ),
		minutes  =>  coal($offset{'minutes'},  $old->minute       ),
		seconds  =>  coal($offset{'seconds'},  $old->second       ),
	);
	
	# set new dattime object
	$eztied->{'dt'} = $new;
}
#
# new_date_time
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# coal
# short for coalesce
#
sub coal {
	my ($new, $old) = @_;
	return defined($new) ? $new : $old;
}
#
# coal
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# getdate
# attempt to get date
# supported date formats
# 14 Jan 2001
# 14 JAN 01
# 14JAN2001
# Jan 14, 2001
# Jan 14, 01
# 01-14-01
# 1-14-01
# 1-7-01
# 01-14-2001
#
sub getdate {
	my ($val) = @_;
	my ($day, $month, $year);
	
	# TESTING
	# println subname(); ##i
	
	# Tue Jun 12 13:03:28 2012
	if ($val =~ s/^([a-z]+) (\d+) (\S+) (\d+)$/$3/) {
		$year  = $4;
		$month = $MonthNums{$1};
		$day   = $2;
	}
	
	# 14 Jan 2001
	# 14 JAN 01
	# 14JAN2001   # will be normalized to have spaces
	elsif ($val =~ m/^\d+ [a-z]+ \d{4}$/) {
		my @tokens = split(' ', $val);
		$day = $tokens[0];
		$month = $MonthNums{$tokens[1]};
		$year = $tokens[2];
		$val = '';
	}
	
	# Jan 14, 2001
	# Jan 14, 01
	elsif ($val =~ s/^([a-z]+) (\d+) (\d+)//) {
		$month = $MonthNums{$1};
		$day = $2;
		$year = $3;
	}
	
	# Jan 2001
	# Jan 01
	elsif ($val =~ s/^([a-z]+) (\d+)//) {
		$month = $MonthNums{$1};
		$year = $2;
	}
	
	# 2001-01-14
	elsif ($val =~ s/^(\d{4}) (\d+) (\d+)//) {
		$year  = $1;
		$month = $2 - 1;
		$day   = $3;
	}
	
	# 01-14-01
	# 1-14-01
	# 1-7-01
	# 01-14-2001
	elsif ($val =~ s/^(\d+) (\d+) (\d+)//) {
		$month = $1 - 1;
		$day = $2;
		$year = $3;
	}
	
	# return
	return ($val, $day, $month, $year);
}
#
# getdate
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# gettime
# supported time formats:
#   5pm
#   5:34 pm
#   17:34
#   17:34:13
#   5:34:13
#   5:34:13 pm
#   2330 (military time)
#
sub gettime {
	my ($eztied, $str, %opts)= @_;
	my ($hour, $min, $sec);
	
	# TESTING
	# println subname(); ##i
	
	# string must be defined
	unless (defined $str) {
		croak 'strin-not-defined: $str is not defined';
	}
	
	# clean up a little
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	$str =~ s/^://;
	$str =~ s/:$//;
	$str =~ s/(\d)(am|pm)/$1 $2/;
	
	# 5:34:13 pm
	# 5:34:13 p
	if ($str =~ s/^(\d+):(\d+):(\d+) (a|p)(m|\b)\s*//) {
		$hour = ampmhour($1, $4);
		$min = $2;
		$sec = $3;
	}
	
	# 17:34:13
	elsif ($str =~ s/^(\d+):(\d+):(\d+)\s*//) {
		$hour = $1;
		$min = $2;
		$sec = $3;
	}
	
	# 5:34 pm
	elsif ($str =~ s/^(\d+):(\d+) (a|p)m?\s*//) {
		$hour = ampmhour($1, $3);
		$min = $2;
	}
	
	# 17:34
	elsif ($str =~ s/^(\d+):(\d+)\s*//) {
		$hour = $1;
		$min = $2;
	}
	
	# 5 pm
	elsif ($str =~ s/^(\d+) (a|p)m?\b\s*//) {
		$hour = ampmhour($1, $2);
		$min = 0;
		$sec = 0;
	}
	
	# elsif just digits
	elsif ( (! $opts{'skipjustdigits'}) && ($str =~ m/^\d+$/) ) {
		$str = zeropad_open($str, 4);
		$hour = substr($str, 0, 2);
		$min = substr($str, 2, 2);
	}
	
	# else don't recognize format
	elsif ($opts{'croakonfail'}) {
		return $eztied->warn("unrecognized-format: don't recognize time format: $str");
	}
	
	# return
	return ($str, $hour, $min, $sec);
}
#
# gettime
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# ampmhour
#
sub ampmhour {
	my ($hour, $ampm) = @_;
	
	# if 12
	if ($hour == 12) {
		# if am, set to 0
		if ($ampm =~ m/^a/)
			{$hour = 0}
	}
	
	# else if pm, add 12
	elsif ($ampm =~ m/^p/) {
		$hour += 12;
	}
	
	# return
	return $hour;
}
#
# ampmhour
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# set_format
#
sub set_format {
	my ($eztied, $name, $format) = @_;
	
	# normalize name
	$name =~ s|\s||g;
	$name =~ lc($name);
	
	$eztied->{'formats'}->{$name} = format_split($format);
}

sub format_split {
	# split
	my @rv = split(m/(\{[^\{\}]*\}|\%.)/, $_[0]);
	
	# normalize
	foreach my $el (@rv) {
		if ($el =~ m|^\{.*\}$|s)
			{ normalize_key($el) }
	}
	
	# remove empties
	@rv = grep {length $_} @rv;
	
	# return
	return \@rv;
}
#
# set_format
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# setfromtime
#
sub setfromtime {
	my ($eztied, $time) = @_;
	
	# TESTING
	# println subname(); ##i
	
	# set time fields
	@$eztied{@ltimefields} = localtime();
	
	# add 1900 to year
	$eztied->{'year'} += 1900;
	
	# increment monthnum, which was base zero, to base one
	$eztied->{'monthnum'}++;
}
#
# setfromtime
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# normalize_key
#
sub normalize_key {
	$_[0] =~ s|\s||gs;
	$_[0] =~ tr/A-Z/a-z/ unless $_[0] =~ m|^\%\w$|;
	$_[0] =~ s|ordinal|ord|sg;
	
	$_[0] =~ s|hours|hour|sg;
	
	$_[0] =~ s|minute|min|sg;
	$_[0] =~ s|mins|min|sg;
	
	$_[0] =~ s|second|sec|sg;
	$_[0] =~ s|secs|sec|sg;
	
	$_[0] =~ s/two/2/gs;
	$_[0] =~ s/three/3/gs;
	$_[0] =~ s/digits?/d/gs;
	
	$_[0] =~ s/timezone/tz/gs;
	
	$_[0] =~ s|number|num|sg;
}
#
# normalize_key
#------------------------------------------------------------------------------




#------------------------------------------------------------------------------
# zeropad_open, zeropad_2
#
sub zeropad_open {
	my ($rv, $length) = @_;
	$length ||= 2;
	# return ('0' x ($length - length($rv))) . $rv;
	return sprintf "%0${length}d", $rv;
}

sub zeropad_2 {
	my ($val) = @_;
	
	# $val must be defined
	if (! defined $val) {
		croak 'zeropad_2~val-not-defined: the value sent to zeropad_2 is not defined';
	}
	
	# return
	return sprintf "%02d", $_[0];
}
#
# zeropad_open, zeropad_2
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# month_short
#
#sub month_short {
#	my ($eztied) = @_;
#	my ($rv);
#	
#	# get name of month, return just the first three letters
#	$rv = Month_to_Text($eztied->{'monthnum'});
#	$rv = substr($rv, 0, 3);
#	
#	# return
#	return $rv;
#}
#
# month_short
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# FETCH
#
sub FETCH {
	my ($eztied, $key, %opts) = @_;
	my ($orgkey, $dt);
	
	# TESTING
	# println subname(); ##i
	
	# hold on to original key
	$orgkey = $key;
	
	# get key from aliases if necessary
	$key = $eztied->get_alias($key);
	
	
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	# nested properties
	#
	if ( (! ref $key) && ($key =~ m|[\{\%]|) && ($key !~ m|$pcode|o) )
		{ $key = format_split($key) }
	
	if (ref $key) {
		my @rv = @$key;
		
		foreach my $el (@rv) {
			# if this is one of the format elements
			# then fetch the value of the given key
			if (
				($el =~ s|\{([^\}]+)\}|$1|) ||  # if it is enclosed in {}
				($el =~ m|$pcode|o)             # if it is a %x code
				) {
				$el =~ s|['"\s]||g;
				$el = $eztied->FETCH($el, normalized=>1);
			}
		}
		
		# ensure defined values in @rv
		foreach my $val (@rv) {
			if (! defined $val)
				{ $val = '' }
		}
		
		# return
		return join('', @rv);
	}
	#
	# nested properties
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	
	# clean up key
	$opts{'normalized'} or normalize_key($key);
	
	# datetime object
	$dt = $eztied->{'dt'};
	
	# datetime object
	if ( ($key eq 'dt') || $key eq 'datetime' ) {
		return $dt;
	}
	
	# already or mostly calculated
	#if (exists $eztied->{$key}) {
	#	# ensure two digits for several properties
	#	if ( $key =~ m/^(dayofmonth|monthnum|hour|min|sec)$/ )
	#		{ return zeropad_2($eztied->{$key}) }
	#	
	#	# all other properties, return key as-is
	#	return $eztied->{$key};
	#}
	
	# character codes
	$key eq 'newline'     and return "\n";
	$key eq 'tab'         and return "\t";
	$key eq 'leftbrace'   and return '{';
	$key eq 'lb'          and return '{';
	$key eq 'rightbrace'  and return '}';
	$key eq 'rb'          and return '}';
	$key eq 'percent'     and return '%';
	
	# nozero's
	if ($key =~ s/no(zero|0)//)
		{ return $eztied->FETCH($key) + 0 }
	
	# day of month
	if ($key eq 'dayofmonth')
		{ return $dt->day }
	
	# day of month, two digits
	if ($key eq 'dayofmonth2d')
		{ return zeropad_2($dt->day) }
	
	# day of month ord
	if ($key =~ m|^dayofmonthord(word)?$|)
		{ return $OrdWords[$eztied->{'dayofmonth'}] }
	if ($key eq 'dayofmonthordnum')
		{ return $OrdNums[$eztied->{'dayofmonth'}] }
	
	# weekdaynum
	if ($key eq 'weekdaynum')
		{ return $dt->day_of_week() }
	
	# weekdaynum2d
	if ($key eq 'weekdaynum2d')
		{ return zeropad_2($dt->day_of_week()) }
	
	# weekday
	if ($key =~ m/^(weekdayshort|dayofweekshort|dayofweek)$/)
		{ return $dt->day_abbr() }
	if ($key =~ m/^(weekdaylong|dayofweeklong)$/)
		{ return $dt->day_name() }
	
	# month
	if ($key eq 'monthshort')
		{ return $dt->month_abbr() }
	if ( ($key eq 'month') || ($key eq 'monthlong') )
		{ return $dt->month_name() }
	
	# month number
	if ($key eq 'monthnum')
		{ return $dt->month }
	if ($key eq 'monthnum2d')
		{ return zeropad_2($dt->month) }
	
	# day of year
	if ($key eq 'yearday')
		{ return $dt->day_of_year() }
	if ($key eq 'yearday3d')
		{ return zeropad_open($dt->day_of_year(), 3) }
	
	# year
	if ($key eq 'year')
		{ return $dt->year }
	if ($key eq 'year2d')
		{ return substr($dt->year, -2) }
	
	# epoch
	if ( ($key eq 'epoch') || ($key eq 'epochsec') )
		{ return Date_to_Time(@$eztied{qw{year monthnum dayofmonth hour min sec}}) }
	
	# leapyear
	if ($key =~ m/^(is)?leapyear/)
		{ return $dt->is_leap_year() }
	
	# days in month
	if ($key eq 'daysinmonth') {
		return DateTime->last_day_of_month(  
			year  =>  $dt->year,
			month =>  $dt->month,
			time_zone => $dt->time_zone_long_name()
		)->day;
	}
	
	# DMY: eg 15JAN2001
	if ($key eq 'dmy') {
		return
			zeropad_2($dt->day) .
			uc($dt->month_abbr()) .
			$dt->year;
	}
	
	# full
	if ($key eq 'full') {
		my ($weekday);
		
		# return
		return
			$dt->day_abbr()         .  ' ' .
			$dt->month_abbr()       .  ' ' .
			$dt->day()              .  ', ' .
			$dt->year()             .  ' ' .
			zeropad_2($dt->hour)    .  ':' .
			zeropad_2($dt->minute)  .  ':' .
			zeropad_2($dt->second);
	}
	
	# military time, aka "miltime"
	if ($key =~ m|^mil(itary)?time$|)
		{ return zeropad_2($dt->hour) . zeropad_2($dt->minute) }
	
	# iso8601
	if ($key eq 'iso8601') {
		return
			$eztied->{'year'}                   .  '-' .
			zeropad_2($eztied->{'monthnum'})    .  '-' .
			zeropad_2($eztied->{'dayofmonth'})  .  ' ' .
			
			zeropad_2($eztied->{'hour'})        .  ':' .
			zeropad_2($eztied->{'min'})         .  ':' .
			zeropad_2($eztied->{'sec'});
	}
	
	# hour
	if ($key eq 'hour')
		{ return $dt->hour }
	
	# hour two digits
	if ($key eq 'hour2d')
		{ return zeropad_2($dt->hour) }
	
	# minute
	if ($key eq 'min')
		{ return $dt->minute }
	
	# minute two digits
	if ($key eq 'min2d')
		{ return zeropad_2($dt->minute) }
	
	# second
	if ($key eq 'sec')
		{ return $dt->second }
	
	# second two digits
	if ($key eq 'sec2d')
		{ return zeropad_2($dt->second) }
	
	# variable
	my ($ampm);
	
	# calculate ampm, which is needed in most results from here down
	$ampm = ($dt->hour >= 12) ? 'pm' : 'am';
	
	# am/pm
	if ( ($key eq 'ampm') || ($key eq 'ampmlc') )
		{ return $ampm }
	
	# AM/PM uppercase
	if ($key eq 'ampmuc')
		{ return uc($ampm) }
	
	# variable
	my ($ampmhour);
	
	# calculate ampmhour, which is needed from here down
	if ( ($dt->hour == 0) || ($dt->hour == 12) )
		{ $ampmhour = 12 }
	elsif ($dt->hour > 12)
		{ $ampmhour = $dt->hour - 12 }
	else
		{ $ampmhour = $dt->hour }
	
	# am/pm hour
	if ($key eq 'ampmhour')
		{ return zeropad_2($ampmhour) }
	
	# hour and minute with ampm
	if (
		($key eq 'clocktime') ||
		($key eq 'clocktimestrict')
		) {
		
		return
			$ampmhour . ':' .
			zeropad_2($dt->minute) . ' ' .
			$ampm;
	}
	
	# tz
	if ( $key eq 'tz' ) {
		return $dt->time_zone_short_name;
	}
	
	# olson
	if ( $key eq 'olson' ) {
		return $dt->time_zone_long_name;
	}
	
	# else we don't know what property is needed
	return $eztied->warn("unknown-format: do not know this format: $orgkey");
}
#
# FETCH
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# warn
#
sub warn {
	my $eztied = shift;
	my $level = defined($eztied->{'warnings'}) ? $eztied->{'warnings'} : $Date::EzDate2::default_warning;
	
	# TESTING
	# println subname(); ##i
	
	# if no level, return undef
	$level or return undef;
	
	if ($level == WARN_STDERR) {
		# showstack();
		carp 'WARNING: ', @_;
		return undef;
	}
	
	# croak
	croak @_;
}
#
# warn
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# get_alias
#
sub get_alias {
	my ($eztied, $key, %opts) = @_;
	
	# normalize
	unless ($key =~ m|[\{\%]|) {
		$key =~ s|\s||g;
		$key = lc($key);
		
		# strip "nozero" if that option was sent
		$opts{'strip_no_zero'} and $key =~ s|nozero||g;
	}
	
	# if this key has an alias
	if (exists $PCodes{$key})
		{return $eztied->get_alias($PCodes{$key}, %opts)}
	
	# if this is a named format
	if (exists $eztied->{'formats'}->{$key})
		{return $eztied->{'formats'}->{$key}}
	
	return $key;
}
#
# get_alias
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# ym, ymd
#
sub ym {
	my ($eztied) = @_;
	return @$eztied{qw{year monthnum}};
}

sub ymd {
	my ($eztied) = @_;
	return @$eztied{qw{year monthnum dayofmonth}};
}
#
# ym, ymd
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# next_month
#
sub next_month {
	my ($eztied, $count) = @_;
	
	# TESTING
	# println subname(); ##i
	
	# add months and return
	return $eztied->{'dt'}->add(months => $count, end_of_month=>'limit');
}
#
# next_month
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# DELETE
#
sub DELETE {
	my ($eztied, $key) = @_;
	
	# normalize key
	$key =~ s|\s||gs;
	$key = lc($key);
	
	# delete from formats, but not properties
	return delete $eztied->{'formats'}->{$key};
}
#
# DELETE
#------------------------------------------------------------------------------

#
# Date::EzDate2::Tie
###############################################################################


# return true
1;

__END__


#------------------------------------------------------------------------------
# pod
#

=head1 TERMS AND CONDITIONS

Copyright (c) 2016 by Miko O'Sullivan.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>

Props also must be given to Dave Rolsky for his excellent DateTime module which
does the complex date and time calculations used by EzDate2.  Furthermore,
props also to the many people who have helped Dave with DateTime.

=head1 VERSION

Version: 0.01

=head1 HISTORY

=over

=item Version 0.01 July 22, 2016

Initial release.

=item Version 0.02 July 23, 2016

Added support for default time zone.

=item Version 0.03 Aug 6, 2016

Modified to use Tie::Hash.

=back

=cut

#
# pod
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# module info
# This info is used by a home-grown CPAN module builder. This info has no use
# in the wild.
#
{
	# include in CPAN distribution
	include : 1,
	
	# allow modules
	allow_modules : {
	},
	
	# test scripts
	test_scripts : {
		'EzDate2/tests/regtest.pl' : 1,
	},
}
#
# module info
#------------------------------------------------------------------------------
