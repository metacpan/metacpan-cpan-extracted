package Armadito::Agent::Tools::Time;

use strict;
use warnings;
use base 'Exporter';
use English qw(-no_match_vars);
use Time::Piece;
use Date::Calc 'Add_Delta_DHMS';
use Time::Local;
use POSIX qw(strftime);

our @EXPORT_OK = qw(
	computeDuration
	msFiletimeToUnixTimestamp
	iso8601ToUnixTimestamp
	nowToISO8601
);

# ; Time Start:   2016-11-30 16:04:34
# ; Time Finish:  2016-11-30 16:04:37

sub computeDuration {
	my (%params) = @_;

	my $format = '%Y-%m-%d %H:%M:%S';
	my $diff = Time::Piece->strptime( $params{end}, $format ) - Time::Piece->strptime( $params{start}, $format );

	return _secondsToDuration( $diff->seconds );
}

sub _secondsToDuration {
	my $totalsecs = shift;
	my ( $hours, $mins, $secs, $leftover ) = ( 0, 0, 0, 0 );

	$leftover = $totalsecs;
	if ( $totalsecs >= 3600 ) {
		$hours    = $totalsecs / 3600;
		$leftover = $totalsecs % 3600;
	}

	if ( $leftover >= 60 ) {
		$mins     = $leftover / 60;
		$leftover = $leftover % 60;
	}

	return "PT" . $hours . "H" . $mins . "M" . $leftover . "S";
}

sub msFiletimeToUnixTimestamp {
	my ( $vt_filetime, $time_zone ) = @_;

	# Disregard the 100 nanosecond units (but you could save them for later)
	$vt_filetime = substr( $vt_filetime, 0, 11 );

	my $days = int( $vt_filetime / ( 24 * 60 * 60 ) );
	my $hours = int( ( $vt_filetime % ( 24 * 60 * 60 ) ) / ( 60 * 60 ) );
	my $mins  = int( ( $vt_filetime % ( 60 * 60 ) ) / 60 );
	my $secs  = $vt_filetime % 60;

	my @date = Add_Delta_DHMS( 1601, 1, 1, 0, 0, 0, $days, $hours, $mins, $secs );

	my ( $year, $mon, $mday, $hour, $min, $sec )
		= ( $date[0], $date[1], $date[2], $date[3], $date[4], $date[5] );

	if ( $time_zone eq "Local" ) {
		return timelocal( $sec, $min, $hour, $mday, $mon - 1, $year );
	}
	elsif ( $time_zone eq "UTC" ) {
		return timegm( $sec, $min, $hour, $mday, $mon - 1, $year );
	}
}

sub iso8601ToUnixTimestamp {
	my ( $vt_iso8601, $time_zone ) = @_;

	if ( $vt_iso8601 =~ /(\d{4,})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/ms ) {
		my ( $year, $mon, $mday, $hour, $min, $sec ) = ( $1, $2, $3, $4, $5, $6 );

		if ( $time_zone eq "Local" ) {
			return timelocal( $sec, $min, $hour, $mday, $mon - 1, $year );
		}
		elsif ( $time_zone eq "UTC" ) {
			return timegm( $sec, $min, $hour, $mday, $mon - 1, $year );
		}
	}
}

sub nowToISO8601 {
	my ($time_zone) = @_;

	if ( $time_zone eq "Local" ) {
		return strftime "%Y-%m-%d  %H:%M:%S", localtime;
	}
	elsif ( $time_zone eq "UTC" ) {
		return strftime "%Y-%m-%d %H:%M:%S", gmtime;
	}
}

1;
__END__

=head1 NAME

Armadito::Agent::Tools::Time - Tools for time manipulation

=head1 DESCRIPTION

This module provides some functions for time and date manipulation.

=head1 FUNCTIONS

=head2 computeDuration(%params)

Returns the duration at ISO8601 format.

=over

=item I<dirpath>

Path of the directory to read.

=head2 msFiletimeToUnixTimestamp($msfiletime)

Converts from Microsoft FileTime format to Unix timestamp.

=head2 iso8601ToUnixTimestamp($iso8601datetime)

Converts from ISO8601 Date time format to Unix timestamp.

=head2 nowToISO8601($timezone)

Return ISO8601 formatted string for now for a specified timezone (Local or UTC).

