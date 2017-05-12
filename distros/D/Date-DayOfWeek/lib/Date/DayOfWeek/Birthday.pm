# $Header: /home/cvs/date-doomsday/lib/Date/DayOfWeek/Birthday.pm,v 1.4 2003/02/02 13:40:38 rbowen Exp $

package Date::DayOfWeek::Birthday;
use Date::DayOfWeek qw();

use strict;
use vars qw(@ISA @EXPORT $VERSION);
require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw( birthday );
$VERSION = ( qw($Revision: 1.4 $) )[1];

=head1 NAME

Date::DayOfWeek::Birthday - Monday's child is fair of face ...

=head1 SYNOPSIS

    use Date::DayOfWeek::Birthday;
    $personality = birthday( 25, 10, 1971 ); # day month year

=head1 DESCRIPTION

    Monday's child is fair of face.
    Tuesday's child is full of grace.
    Wednesday's child is full of woe.
    Thursday's child has far to go.
    Friday's child is loving and giving.
    Saturday's child works hard for his living.
    The child that is born on the Sabbath day
     is great, and good, and fair, and gay.

Although our Jewish friends would disagree with the designation of
Sunday as "the Sabbath day," the above poem puepoerts to describe the
character of an individual based on the day of their birth.

I'm not certain as to the origins of this poem. I'm trying to track
that down.

Note also that there are various other versions of this poem,
depending on which part of the world you come from. Another version,
for example, says that ...

    The child that is born on the Sabbath day
     is bonny and blithe and good and gay.

And yet another says that ...

    The child that is born on the Sabbath day
     is witty and wise and good and gay.

=head1 birthday

    $personality = birthday( 25, 10, 1971 ); # day month year

=cut    

sub birthday {
    my ($day, $month, $year) = @_;

    unless ( $day && $month && $year ) {
        ( $day, $month, $year ) = ( localtime(time) )[ 3, 4, 5 ];
        $month++;
        $year += 1900;
    }
    my $dayofweek = Date::DayOfWeek::dayofweek( $day, $month, $year );
   
    my @days = (
    "The child that is born on the Sabbath day\nis great, and good, and fair, and gay.",
    "Monday's child is fair of face.",
    "Tuesday's child is full of grace.",
    "Wednesday's child is full of woe.",
    "Thursday's child has far to go.",
    "Friday's child is loving and giving.",
    "Saturday's child works hard for his living.",
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


