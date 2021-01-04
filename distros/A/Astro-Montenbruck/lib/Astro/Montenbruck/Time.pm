package Astro::Montenbruck::Time;

use warnings;
use strict;

our $VERSION = 0.01;

use Exporter qw/import/;

our $SEC_PER_DAY = 86400;        # Seconds per day
our $SEC_PER_CEN = 3155760000;
our $J2000       = 2451545;      # Standard Julian Date for 1.1.2000 12:00
our $J1900       = 2415020
  ;    # Standard Julian Date for  31.12.1899 12:00 (astronomical epoch 1900.0)
our $SOLAR_TO_SIDEREAL = 1.002737909350795
  ;    # Difference in between Sidereal and Solar hour (the former is shorter)
our $GREGORIAN_START = 15821004;    # Start of Gregorian calendar (YYYYMMDD)
our $JD_UNIX_EPOCH = _gmtime2jd( gmtime(0) )
  ; # Standard Julian date for the beginning of Unix epoch, Jan 1 1970 on most Unix systems

our %EXPORT_TAGS = (
    all => [
        qw/jd_cent after_gregorian cal2jd jd2cal jd0 unix2jd jd2mjd mjd2jd
          jd2unix jdnow t1900 jd2gst jd2lst
          is_leapyear day_of_year
          $SEC_PER_DAY $SEC_PER_CEN $J2000 $J1900 $GREGORIAN_START $JD_UNIX_EPOCH/
    ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

use POSIX;
use Astro::Montenbruck::MathUtils qw/polynome ddd frac to_range/;

sub after_gregorian {
    my $y   = shift;
    my $m   = shift;
    my $d   = shift;
    my %arg = ( gregorian_start => $GREGORIAN_START, @_ );
    return 0 unless defined $arg{gregorian_start};
    polynome( 100, $d, $m, $y ) >= $arg{gregorian_start};
}

sub cal2jd {
    my $ye  = shift;
    my $mo  = shift;
    my $da  = shift;
    my %arg = ( gregorian_start => $GREGORIAN_START, @_ );

    my $j = $da + 1720996.5;
    my ( $m, $y ) = ( $mo > 2 ) ? ( $mo, $ye ) : ( $mo + 12, $ye - 1 );
    if ( after_gregorian( $ye, $mo, $da, %arg ) ) {
        $j += int( $y / 400 ) - int( $y / 100 ) + int( $y / 4 );
    }
    else {
        $j += int( ( $y + 4716 ) / 4 ) - 1181;
    }
    $j + 365 * $y + floor( 30.6001 * ( $m + 1 ) );
}

sub jd2cal {
    my $jd = shift;
    my %arg = ( gregorian => 1, @_ );

    my ( $f, $i ) = modf( $jd - $J1900 + 0.5 );
    if ( $arg{gregorian} && $i > -115860 ) {
        my $a = floor( $i / 36524.25 + 9.9835726e-1 ) + 14;
        $i += 1 + $a - floor( $a / 4 );
    }

    my $b  = floor( $i / 365.25 + 8.02601e-1 );
    my $c  = $i - floor( 365.25 * $b + 7.50001e-1 ) + 416;
    my $g  = floor( $c / 30.6001 );
    my $da = $c - floor( 30.6001 * $g ) + $f;
    my $mo = $g - ( $g > 13.5 ? 13 : 1 );
    my $ye = $b + ( $mo < 2.5 ? 1900 : 1899 );
    $ye, $mo, $da;
}

sub jd0 {
    my $j = shift;
    floor( $j - 0.5 ) + 0.5;
}

sub unix2jd {
    $JD_UNIX_EPOCH + $_[0] / $SEC_PER_DAY;
}

sub jd2unix {
    int( ( $_[0] - $JD_UNIX_EPOCH ) * $SEC_PER_DAY );
}

sub _gmtime2jd {
    cal2jd( $_[5] + 1900, $_[4] + 1, $_[3] + ddd( @_[ 2, 1, 0 ] ) / 24 );
}

sub jdnow {
    _gmtime2jd( gmtime() );
}

sub jd2mjd {
    $_[0] - $J2000;
}

sub mjd2jd {
    $_[0] + $J2000;
}

# converts Julian date to period in centuries since epoch
# Arguments:
# julian date
# julian date corresponding to the epoch start
sub _t {
    my ( $jd, $epoch ) = @_;
    ( $jd - $epoch ) / 36525;
}

sub jd_cent {
    _t( $_[0], $J2000 );
}

sub t1900 {
    _t( $_[0], $J1900 );
}

sub jd2gst {
    my $jh = shift;
    my $j0 = jd0($jh);
    my $s0 = polynome( t1900($j0), 0.276919398, 100.0021359, 0.000001075 );
    24 * ( frac($s0) + abs( $jh - $j0 ) * $SOLAR_TO_SIDEREAL );
}

sub jd2lst {
    my ( $jd, $lon ) = @_;
    $lon //= 0;
    to_range( jd2gst($jd) - $lon / 15, 24 );
}

sub is_leapyear {
    my $yr = shift;
    my %arg = ( gregorian => 1, @_ );
    $yr = int($yr);
    return $arg{gregorian}
      ? ( $yr % 4 == 0 ) && ( ( $yr % 100 != 0 ) || ( $yr % 400 == 0 ) )
      : $yr % 4 == 0;
}

sub day_of_year {
    my $yr = shift;
    my $mo = shift;
    my $dy = shift;

    my $k = is_leapyear($yr, @_) ? 1 : 2;
    $dy = int($dy);
    int(275 * $mo / 9.0) - ($k * int(($mo + 9) / 12.0)) + $dy - 30
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Time - Time-related routines

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Astro::Montenbruck::Time qw/:all/;

    # Convert Gregorian (new-style) date to old-style date
    my $j = cal2jd(1799, 6, 6); # Standard Julian date of A.Pushkin's birthday
    my $d = jd2cal($j, gregorian => 0) # (1799, 5, 25) = May 26, 1799.

    # Julian date in centuries since epoch 2000.0
    my $t = jd_cent($j); # -2.0056810403833
    ...

=head1 DESCRIPTION

Library of date/time manipulation routines for practical astronomy. Most of them
are based on so called I<Julian date (JD)>, which is the number of days elapsed
since mean UT noon of B<January 1st 4713 BC>. This system of time measurement is
widely adopted by the astronomers.

=head2 JD and MJD

Many routines use Modified Julian date, which starts at B<2000 January 0>
(2000 January 1.0) as the starting point.

=head2 Civil year vs astronomical year

There is disagreement between astronomers and historians about how to count the
years preceding the year 1. Astronomers generally use zero-based system. The
year before the year +1, is the year zero, and the year preceding the latter is
the year -1. The year which the historians call 585 B.C. is actually the year
-584.

In this module all subroutines accepting year assume that B<there is year zero>.
Thus, the sequence of years is: C<BC -3, -2, -1, 0, 1, 2, 3, AD>.

=head2 Date and Time

Time is represented by fractional part of a day. For example, 7h30m UT
is C<(7 + 30 / 60) / 24 = 0.3125>.

=head3 Gregorian calendar

I<Civil calendar> in most cases means I<proleptic Gregorian calendar>. it is
assumed that Gregorian calendar started at Oct. 4, 1582, when it was first
adopted in several European countries. Many other countries still used the older
Julian calendar. In Soviet Russia, for instance, Gregorian system was accepted
on Jan 26, 1918. See:
L<https://en.wikipedia.org/wiki/Gregorian_calendar#Adoption_of_the_Gregorian_Calendar>


=head1 EXPORTED CONSTANTS

=over

=item * C<$SEC_PER_DAY> seconds per day (86400)

=item * C<$SEC_PER_CEN> seconds per century (3155760000)

=item * C<$J2000> Standard Julian date for start of epoch 2000,0 (2451545)

=item * C<$J1900> Standard Julian date for start of epoch 1900,0 (2415020)

=item * C<$GREGORIAN_START> Start of Gregorian calendar, YYYYMMDD (15821004)

=item * C<$JD_UNIX_EPOCH> Standard Julian date for start of the Unix epoch

=back

=head1 EXPORTED FUNCTIONS

=over

=item * L</jd_cent($jd)>

=item * L</after_gregorian($year, $month, $date)>

=item * L</cal2jd($year, $month, $date)>

=item * L</jd2cal($jd)>

=item * L</jd0($jd)>

=item * L</unix2jd($seconds)>

=item * L</jd2unix($jd)>

=item * L</jdnow()>

=item * L</jd2mjd($jd)>

=item * L</mjd2jd($mjd)>

=item * L</jd_cent($jd)>

=item * L</t1900($jd)>


=item * L</jd2dt($jd)>

=item * L</jd2te($jd)>

=item * L</jd2gst($jd)>

=item * L</jd2lst($jd, $lng)>

=back

=head1 FUNCTIONS

=head2 jd_cent($jd)

Convert Standard Julian Date to centuries passed since epoch 2000.0

=head2 after_gregorian($year, $month, $date, gregorian_start => $YYYYMMDD )

Does the given date fall to period after Gregorian calendar?

=head3 Positional Arguments

=over

=item * B<year> (astronomic, zero-based)

=item * B<month> (1-12)

=item * B<date> UTC date (1-31) with hours and minutes as decimal part

=back

=head3 Optional Named Arguments

=over

=item *

B<gregorian_start> — start of Gregorian calendar. Default value is
B<15821004> If the date is Julian ("old style"), use C<undef> value.
To provide non-standard start of Gregorian calendar, provide a number
in format YYYYMMDDD, e.g. C<19180126> for Jan 26, 1918.

=back

=head3 Returns

I<true> or I<false>=.

=head2 cal2jd($year, $month, $date)

Convert civil date/time to Standard Julian date.

If C<gregorian_start> argument is not provided, it is assumed that this is a date
of I<Proleptic Gregorian calendar>, which started at Oct. 4, 1582.

=head3 Positional Arguments:

=over

=item * B<year> (astronomic, zero-based)

=item * B<month> (1-12)

=item * B<date> UTC date (1-31) with hours and minutes as decimal part

=back

=head3 Optional Named Arguments

=over

=item *

gregorian_start — start of Gregorian calendar. Default value is
B<15821004> If the date is Julian ("old style"), use C<undef> value.
To provide non-standard start of Gregorian calendar, provide a number
in format YYYYMMDDD, e.g. C<19180126> for Jan 26, 1918.

=back

=head3 Returns

Standard Julian date

=head2 jd2cal($jd)

Convert Standard Julian date to civil date/time

=head3 Positional Arguments

Standard Julian Date

=head3 Optional Named Arguments

=over

=item * gregorian — if i<true>, the result will be old-style (Julian) date

=back

=head3 Returns

A list corresponding to the input values of L</cal2jd($year, $month, $date)> function.
The date is given in the proleptic Gregorian calendar system unless B<gregorian>
flag is set to I<true>.

=head2 jd0($jd)

Given Standard Julian Date, calculate Standard Julian date for midnight of the same date.

=head2 unix2jd($seconds)

Given Unix time, in seconds, convert it to Standard Julian date.

=head2 jd2unix($jd)

Given a Standard Julian Date, convert it to Unix time, in seconds since start of
Unix epoch.

If JD falls before start of the epoch, result will be negative and thus, unusable
for Unix-specific functions like B<localtime()>.

=head2 jdnow()

Standard Julian date for the current moment.

=head2 jd2mjd($jd)

Standard to Modified Julian date.

=head2 mjd2jd($mjd)

Modified to Standard Julian date.

=head2 jd_cent($jd)

Given aI<Standard Julian date>, calculate time in centuries since epoch 2000.0.

=head2 t1900($jd)

Given a I<Standard Julian date>, calculate time in centuries since epoch 2000.0.


=head2 jd2gst($jd)

Given I<Standard Julian date>, calculate I<True Greenwich Sidereal time>.

=head2 jd2lst($jd, $lng)

Givan I<Standard Julian date>, calculate true I<Local Sidereal time>.

=head3 Arguments

=over

=item * $jd — Standard Julian date

=item * $lng — Geographic longitude, negative for Eastern longitude, 0 by default

=back


=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2019 Sergey Krushinsky.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
