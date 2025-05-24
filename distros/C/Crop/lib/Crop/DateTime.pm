package Crop::DateTime;

=pod

=head1 NAME

Crop::DateTime - General purpose Date and Time class for Crop framework

=head1 SYNOPSIS

    use Crop::DateTime;
    my $dt = Crop::DateTime->new();
    my $epoch_ms = $dt->epoch_milli;
    my $timestamp = $dt->timestamp;

=head1 DESCRIPTION

Crop::DateTime provides date and time handling for the Crop framework, including high-resolution time, time zone support, and formatting utilities. By default, the time zone is set to Moscow time (UTC+3).

=head1 CONSTANTS

=over 4

=item * DEFAULT_TIMEZONE
The default time zone (C<03:00>, Moscow time).

=back

=head1 ATTRIBUTES

=over 4

=item * sec
Seconds since the epoch (read-only).

=item * usec
Microseconds (read-only).

=item * tz
Time zone (defaults to C<03:00>).

=back

=head1 METHODS

=head2 new([$time])

    my $dt = Crop::DateTime->new();
    my $dt = Crop::DateTime->new('2025-05-23 12:34:56.123456+03');

Creates a new Crop::DateTime object. If C<$time> is provided (in Postgres format), it is used; otherwise, the current time is used.

=head2 epoch_milli

    my $ms = $dt->epoch_milli;

Returns the epoch time in milliseconds as a string.

=head2 timestamp

    my $ts = $dt->timestamp;

Returns the time in the format C<'TIMESTAMP(6) WITH TIME ZONE'>.

=head1 DEPENDENCIES

=over 4

=item * Time::HiRes
=item * Date::Parse

=back

=head1 AUTHORS

Euvgenio (Core Developer)

Alex (Contributor)

=head1 COPYRIGHT AND LICENSE

Apache 2.0

=cut

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
