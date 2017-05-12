# $Header: /home/cvs/date-doomsday/lib/Date/DayOfWeek/Nails.pm,v 1.5 2003/02/02 13:40:38 rbowen Exp $

package Date::DayOfWeek::Nails;
use Date::DayOfWeek qw();

use strict;

require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);

@EXPORT = qw( nails );
$VERSION = ( qw($Revision: 1.5 $) )[1];

=head1 NAME

Date::DayOfWeek::Nails - Cut your nails on a Friday, cut them for woe ...

=head1 SYNOPSIS

    use Date::DayOfWeek::Nails;
    $advice = nails( 25, 10, 1971 ); # day month year

=head1 DESCRIPTION

 Cut your nails on a Monday, cut them for news.
 Cut your nails on a Tuesday, a new pair of shoes.
 Cut your nails on a Wednesday, cut them for health.
 Cut your nails on a Thursday, cut them for wealth.
 Cut your nails on a Friday, cut them for woe.
 Cut your nails on a Saturday, a journey to go.
 Cut your nails on a Sunday, you cut them for evil,
 For all the next week you'll be ruled by the devil.

Yes, this is strange. And I'm looking for the source of these beliefs.
I think I probably have to read a few more chapters. But this amused
me, so here it is.

The reference for this is The Oxford Companion to the Year, however,
it does not say exactly where this rhyme comes from.

=head1 nails

    $advice = nails( 25, 10, 1971 ); # day month year

=cut    

sub nails {
    my ($day, $month, $year) = @_;

    unless ( $day && $month && $year ) {
        ( $day, $month, $year ) = ( localtime(time) )[ 3, 4, 5 ];
        $month++;
        $year += 1900;
    }
    my $dayofweek = Date::DayOfWeek::dayofweek( $day, $month, $year );
   
    my @days = (
 "Cut your nails on a Sunday, you cut them for evil,\nFor all the next week you'll be ruled by the devil.",
 "Cut your nails on a Monday, cut them for news.",
 "Cut your nails on a Tuesday, a new pair of shoes.",
 "Cut your nails on a Wednesday, cut them for health.",
 "Cut your nails on a Thursday, cut them for wealth.",
 "Cut your nails on a Friday, cut them for woe.",
 "Cut your nails on a Saturday, a journey to go.",
    );

    return $days[$dayofweek];
}

1;

=head1 AUTHOR

Rich Bowen ( rbowen@rcbowen.com )

=head1 See Also

Date::Doomsday

Date::DayOfWeek

The Oxford Companion to the Year (Bonnie Blackburn and Leofranc
Holford-Strevens. Oxford Press.)

=cut


