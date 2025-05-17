package Crop::DateTime;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::DateTime
	General purpose Date and Time.
=cut

use v5.14;
use warnings;

use Time::HiRes qw/ gettimeofday /;
use Date::Parse;

use Crop::Error;

use Crop::Debug;

=begin nd
Constant: DEFAULT_TIMEZONE
	By default is the Moscow time (UTC+3).
=cut
use constant DEFAULT_TIMEZONE => '03:00';

=begin nd
Variable: our %Attributes
	Class attributes:

	sec  - seconds,
	usec - microseconds the left aligned!
	tz   - time zone,
=cut
our %Attributes = (
	sec  => {mode => 'read'},
	usec => {mode => 'read'},
	tz   => {default => DEFAULT_TIMEZONE},
);

=begin nd
Constructor: new ($time)
	Init exemplar with the $time data.

Parameters:
	$time - in postgres format; optional;
	        unless $time is given, the current time is used

Returns:
	$self
=cut
sub new {
	my ($class, $time) = @_;

	my ($second, $usecond);
	my $tz = DEFAULT_TIMEZONE;

	if (defined $time) {
		$second    = str2time $time;
		$second =~ s/\.\d+//;
		($usecond) = $time =~ /\.(\d+)/;
		
		my ($sign, $zone) = $time =~ /(\+|-)(\d{1,2})$/;
		$tz = "$sign$zone";
	} else {
		($second, $usecond) = gettimeofday;
	}

	$class->SUPER::new(
		sec  => $second,
		usec => $usecond || 0,
		tz   => $tz,
	);
}

=begin nd
Method: epoch_milli ( )
	The 'epoch' time in milliseconds
	
Returns:
	1652907999123 string where last 123 are milliseconds
=cut
sub epoch_milli {
	my $self = shift;
	
	my $result = $self->{sec} * 1000;  # in milliseconds without mantissa
	
	my ($usec) = $self->{usec} =~ /^(\d{0,3})/;  # milliseconds part
	
	my $left = 3 - length $usec;
	$usec *= 10**$left if $left;
	
	$result + $usec;
}

=begin nd
Method: timestamp ( )
	Time in the format of 'TIMESTAMP(6) WITH TIME ZONE'.
=cut
sub timestamp {
	my $self = shift;

	return warn 'TIME: Time is not initialized' unless defined $self->{sec} and defined $self->{usec};

	my ($second, $minute, $hour, $monthday, $month, $year, $weekday, $yearday, $isdst) = localtime $self->{sec};
	my $usecond  = $self->{usec};
	my $timezone = $self->{tz};

	sprintf("%04d-%02d-%02d %02d:%02d:%02d.%06d+%s", $year+1900, $month+1, $monthday, $hour, $minute, $second, $usecond, $timezone);
}

1;
