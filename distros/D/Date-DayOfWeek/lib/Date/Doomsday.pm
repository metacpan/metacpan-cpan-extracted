package Date::Doomsday;

use strict;
use vars qw( @ISA @EXPORT $VERSION );

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw( doomsday );
$VERSION = ( qw($Revision: 1.12 $) )[1];

=head1 NAME

Date::Doomsday - Determine doomsday for a given year

=head1 SYNOPSIS

  use Date::Doomsday;
  $doomsday = doomsday(1945);

=head1 VERSION

$Revision: 1.12 $

=head1 DESCRIPTION

Doomsday is a concept invented by John Horton Conway to make it easier to
figure out what day of the week particular events occur in a given year.

=head1 doomsday

    $doomsday = doomsday( 1945 );

Returns the day of the week (in the range 0..6) of doomsday in the particular
year given. If no year is specified, the current year is assumed.

=cut

# sub doomsday {{{

sub doomsday {
    my $year = shift;

    $year = ( localtime(time) )[5] unless $year;

    if ($year < 1583) {
        warn "The Gregorian calendar did not come into use until 
1583. Your date predates the usefulness of this algorithm."
    }

    my $century = $year - ( $year % 100 );

    my $base = ( 3, 2, 0, 5 )[ ( ($century - 1500)/100 )%4 ];

    my $twelves = int ( ( $year - $century )/12);
    my $rem = ( $year - $century ) % 12;
    my $fours = int ($rem/4);

    my $doomsday = $base + ($twelves + $rem + $fours)%7;

    return $doomsday % 7;
}#}}}

# Docs {{{

=head1 AUTHOR

Rich Bowen (rbowen@rcbowen.com)

=head1 Doomsday

Doomsday is a simple way to find out what day of the week any event occurs, in
any year. It was invented by Dr John Horton Conway.

In conjunction with Date::DayOfWeek, it can calculate the day of the
week for any date since the beginning of the Gregorian calendar.

The concept of doomsday is simple: If you know this special day
(called "doomsday") for a given year, you can figure out the day of
the week for any other day that year by a few simple calculations that
you can do in your head, thus:

The last day of February is doomsday. That's the 28th most years, and
the 29th in leap years.

The Nth day of the Nth month is doomsday, for even values of N. That
is, 4/4 (April 4), 6/6, 8/8, 10/10, and 12/12, are all doomsdays.
(That is, if doomsday is Wednesday, as it is in 2001, then October 10
will also be a Wednesday.)

For odd months, after March, the following mnemonic will help you
remember: "I work from 9-5 at the 7-11." (For those of you not living
in the USA, you might like to know that 7-11 is the name of a chain of
stores.) What this means is that 9/5 (September 5) and 5/9 (May 9) are
both doomsday. Likewise, 7/11 and 11/7 are doomsday.

The 0th day of march is always doomsday.

The last day of January is doomsday in most years, and the day after
tha last day of January (think January 32nd) is doomsday in leap
years.

So, if you know the above, and you want to figure out what day of the
week a particular day is, you do something like the following:

When is Christmas in 2001? Doomsday in 2001 is Wednesday. So December
12 is Wednesday. Count forward 2 week, and find that December 26 is a
Wednesday. So Christmas (December 25) is a Tuesday.

For more information about the origins and mathematics surrounding
doomsday, see the following web sites:

http://rudy.ca/doomsday.html

http://quasar.as.utexas.edu/BillInfo/doomsday.html

http://www.cst.cmich.edu/users/graha1sw/Pub/Doomsday/Doomsday.html

=cut

# }}}

1;

