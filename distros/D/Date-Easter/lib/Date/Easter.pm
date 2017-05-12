# $Header: /cvsroot/date-easter/lib/Date/Easter.pm,v 1.15 2003/04/21 03:23:29 rbowen Exp $
package Date::Easter;

=head1 NAME

Date::Easter - Calculates Easter for any given year

=head1 SYNOPSIS

  use Date::Easter;
  ($month, $day) = julian_easter(1752);
  ($month, $day) = easter(1753);
  ($month, $day) = gregorian_easter(1753);
  ($month, $day) = orthodox_easter(1823);

=head1 DESCRIPTION

Calculates Easter for a given year.

easter() is, for the moment, an alias to gregorian_easter(), since
that's what most people use now. The thought was to somehow know which of the
other methods to call, that that proved to be rather sticky.

=cut

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Time::Local;
require Exporter;

@ISA     = qw( Exporter );
@EXPORT  = qw( julian_easter gregorian_easter orthodox_easter easter );
$VERSION = '1.22';

=pod

Date::Easter provides the following functions:

=head2 julian_easter

    ( $month, $day ) = julian_easter( $year );

Returns the month and day of easter in the given year, in the Julian
calendar.

=cut

sub julian_easter {
    my ($year) = @_;
    my ( $G, $I, $J, $L, $month, $day, );
    $G     = $year % 19;
    $I     = ( 19 * $G + 15 ) % 30;
    $J     = ( $year + int( $year / 4 ) + $I ) % 7;
    $L     = $I - $J;
    $month = 3 + int( ( $L + 40 ) / 44 );
    $day   = $L + 28 - ( 31 * ( int( $month / 4 ) ) );
    return ( $month, $day );
}

=head2 gregorian_easter

    ( $month, $day ) = gregorian_easter( $year );

Returns the month and day of easter in the given year, in the
Gregorian calendar, which is what most of the world uses.

=cut

sub gregorian_easter {
    my ($year) = @_;
    my ( $G, $C, $H, $I, $J, $L, $month, $day, );
    $G = $year % 19;
    $C = int( $year / 100 );
    $H = ( $C - int( $C / 4 ) - int( ( 8 * $C + 13 ) / 25 ) + 19 * $G + 15 ) % 30;
    $I = $H - int( $H / 28 ) *
      ( 1 - int( $H / 28 ) * int( 29 / ( $H + 1 ) ) * int( ( 21 - $G ) / 11 ) );
    $J     = ( $year + int( $year / 4 ) + $I + 2 - $C + int( $C / 4 ) ) % 7;
    $L     = $I - $J;
    $month = 3 + int( ( $L + 40 ) / 44 );
    $day   = $L + 28 - ( 31 * int( $month / 4 ) );
    return ( $month, $day );
}

=head2 easter

    ( $month, $day ) = easter( $year );

Returns the month and day of easter in the given year, in the
Gregorian calendar, which is what most of the world uses.

=cut

sub easter { return gregorian_easter(@_); }

# sub orthodox_easter {{{

=head2 orthodox_easter

    ( $month, $day ) = orthodox_easter( $year );

Returns the month and day of easter in the given year, in the
Orthodox calendar.

From code by Pascalis Ligdas, based on original code by
Apostolos Syropoulos

=cut


sub orthodox_easter {
    my $year   = shift;

    die "Invalid year for Gregorian calendar" if ($year < 1583);

    # Find the date of the Paschal Full Moon (based on Alexandrian computus)
    my $epact = ( ( $year % 19 ) * 11 ) % 30;
    my $fullmoon = 5 - $epact;
    $fullmoon += 30 if $fullmoon < -10;

    # Convert from Julian to Gregorian calender
    $fullmoon += int($year / 100) - int($year / 400) - 2;

    my $month = 4;
    if ( $fullmoon > 30 ) {
        $month = 5;
        $fullmoon -= 30;
    } elsif ( $fullmoon <= 0 ) {
        $month = 3;
        $fullmoon += 31;
    }

    # Find the next Sunday
    my $fullmoonday = dow( $fullmoon, $month, $year );
    my $easter = $fullmoon + ( 7 - $fullmoonday );

    if ( $month == 3 && $easter > 31 ) {
        $month++;
        $easter -= 31;
    } elsif ( $month == 4 && $easter > 30 ) {
        $month++;
        $easter -= 30;
    }
    return ( $month, $easter );
}

#}}}

sub dow { ( localtime( timelocal( 0, 0, 0, $_[0], $_[1] - 1, $_[2] ) ) )[6] } 

1;

=head1 AUTHOR

Rich Bowen <rbowen@rcbowen.com>

=head1 To Do

Since the dates that various countries switched to the Gregorian
calendar vary greatly, it's hard to figure out when to use
which method. Perhaps some sort of locale checking would be
cool?

I need to test the Julian easter calculations, but I'm a little
confused as to the difference between the Orthodox Easter and the
Julian Easter. I need to read some more.

The use of localtime and timelocal locks us into the epoch, which is a
rather silly limitation. Need to move to Date::DayOfWeek or other
module to calculate the day of the week. This should immediately make
the module usable back to the beginning of celebration of Easter.

=head1 Other Comments

Yes, Date::Manip already has code in it to do this. But Date::Manip
is very big, and rather slow. I needed something faster and
smaller, and did not need all that other stuff. And I have a real
interest in date calculations, so I thought this would be fun.
Date::Manip is a very cool module. I use it myself.

See also http://www.pauahtun.org/CalendarFAQ/cal/node3.html
for more details on calculating Easter.

And many thanks to Simon Cozens who provided me with the code for the
orthodox_easter function.

The tests are taken from a table at
http://www.chariot.net.au/~gmarts/eastcalc.htm

The script 'easter' is just a simple way to find out when easter falls
in a given year. Type 'easter' to find easter for this year, and 'easter
1983' to find when easter falls in 1983.


