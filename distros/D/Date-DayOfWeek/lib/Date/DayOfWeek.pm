# $Header: /home/cvs/date-doomsday/lib/Date/DayOfWeek.pm,v 1.22 2003/02/02 13:40:37 rbowen Exp $

package Date::DayOfWeek;
use Date::Doomsday qw();
use Date::Leapyear qw();
use strict;

require Exporter;
use vars qw( @ISA @EXPORT $VERSION );
@ISA = qw(Exporter);

@EXPORT = qw( dayofweek );
$VERSION = ( qw($Revision: 1.22 $) )[1];

# Docs {{{

=head1 NAME

Date::DayOfWeek - Determine the day of the week for any date.

=head1 SYNOPSIS

  use Date::DayOfWeek;
  $dow = dayofweek( 25, 10, 1971 ); # dd, mm, yyyy

=head1 DESCRIPTION

Calculates the day of the week for any date in the Gregorian calendar
(1563 and following).
Based on the Doomsday algorithm of John Conway.

=cut

#}}}

# sub dayofweek {{{

=head1 dayofweek

    $dow = dayofweek( 25, 10, 1971 );
    $dow = dayofweek( 4, 7, 1776 );

Returns the day of the week for any date between 1500 and 2699.

Month should be in the range 1..12

The day of week that is returned is an integer in the range 0..6, with 0 =
sunday, 1 = monday, etc.

=cut

sub dayofweek {
    my ($day, $month, $year) = @_;

    # When is doomsday this year?
    my $doomsday = Date::Doomsday::doomsday( $year );

    # And when is doomsday this month?

    my @base = ( 0, 0, 7, 4, 9, 6, 11, 8, 5, 10, 7, 12 );
    @base[0,1] = Date::Leapyear::isleap($year) ? (32,29) : (31,28);

    # And how far after that are we?
    my $on = $day - $base[$month - 1];
    $on = $on % 7;
    
    # So, the day of the week should be doomsday, plus however far on we are
    return ($doomsday + $on) % 7;
} # }}}

=head1 AUTHOR

Rich Bowen (rbowen@rcbowen.com)

=head1 See Also

Date::Doomsday

Date::DayOfWeek::Birthday, Date::DayOfWeek::Nails, and
Date::DayOfWeek::Birthday

Date::Christmas

=cut

# CVS history {{{

=head1 HISTORY

    $Log: DayOfWeek.pm,v $
    Revision 1.22  2003/02/02 13:40:37  rbowen
    Change link in documentation. Other minor cosmetic changes.

    Revision 1.21  2001/12/22 01:28:54  rbowen
    Documentation updates.

    Revision 1.20  2001/10/10 02:35:07  rbowen
    Bug reported by Francois Claveau.

    Revision 1.19  2001/08/25 21:28:14  rbowen
    Moved files to lib directory
    Removed 5.6 dependencies.

    Revision 1.18  2001/08/03 04:24:39  rbowen
    Alter locations of modules - moved into Date subdir.
    Added to MANIFEST
    No longer reqiure 5.005_62. Not sure why that was there.

    Revision 1.17  2001/06/11 01:49:05  rbowen
    Additional docs. Added Sneeze.pm

    Revision 1.16  2001/06/10 18:46:03  rbowen
    Moved isleap functionality into Date::Leapyear. Added Birthday.pm and
    Nails.pm as examples of the strange things that people believe - or
    believed a few hundred years ago, with regard to days of the week.

    Revision 1.15  2001/06/06 02:29:14  rbowen
    Added some more doomsday tests. Removed dayofweek tests that referred
    to years before the Gregorian calendar. Extended the range of
    Doomsday.pm indefinately into the future. And a small bug fix in
    DayOfWeek.pm

    Revision 1.14  2001/06/06 01:41:45  rbowen
    Made the calculation a little more elegant, if somewhat less
    informative. Thanks for patch from Jerrad Pierce. Thanks for
    various suggestions from David Pitts.

    Revision 1.13  2001/05/27 19:34:46  rbowen
    Rearranged argument order. day month year makes more sense.

    Revision 1.12  2001/05/27 03:44:03  rbowen
    Need to mod return value by 7.

    Revision 1.11  2001/05/27 03:41:31  rbowen
    This seems to work on all the dates that I've tested it for. More testing is
    needed.

    Revision 1.10  2001/05/27 03:13:57  rbowen
    Add DayOfWeek to repository.

=cut

# }}}

1;

