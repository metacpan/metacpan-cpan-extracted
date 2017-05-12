#$Header: /cvsroot/date-chinese/lib/Date/Chinese.pm,v 1.10 2002/08/29 23:43:33 rbowen Exp $
package Date::Chinese;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = (qw'$Revision: 1.12 $')[1];
	@ISA         = qw (Exporter);
	@EXPORT      = qw ( yearofthe );
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

=head1 NAME

Date::Chinese - Calculate dates in the Chinese calendar

=head1 SYNOPSIS

  use Date::Chinese;

  $year = yearofthe( 1999 ); # "Year of the hare, earth"

=head1 DESCRIPTION

Please note that the API of this module is I<guaranteed> to change in
future versions. I'll hopefully be adding more details about the date,
rather than just the year.

You should also note that the Chinese new year does not conicide with
the Gregorian new year, so the determination of what year it is in the
Chinese calendar is only going to be correct for a portion of the
Gregorian year.

=head1 SUPPORT

datetime@perl.org

=head1 AUTHOR

	Rich Bowen
	CPAN ID: RBOW
	rbowen@rcbowen.com
	http://www.rcbowen.com

=head1 COPYRIGHT

Copyright (c) 2001 Rich Bowen. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

 perl(1).
 http://dates.rcbowen.com/

=head1 About the Chinese calendar

Reference: The Oxford Companion to the Year - Bonnie Blackburn and
Leofranc Holford-Strevens. Pg 696-707

The Chinese calendar is a 19 year cycle. Seven of these 19 years have 13
months, and the rest have 12. There's a whole heck of a lot more to it
than the 12 animals that you see on your placemat at your favorite
Chinese restaurant.

There is a cycle of 10 stems and 12 branches. Each stem has associated
with it an element (wood, fire, earth, metal, water) a yang (fir,
kindling, hill, weapons, waves) a yin (bamboo, lamp-flame, plain,
kettle, brooks) a cardinal point (east, south, centre, west, north)
and a planet (Jupiter, Mars, Saturn, Venus, Mercury).

Likewise, each branch has associated with it an animal, an element, a
double-hour, a compass point, and a sign of the zodiac.

Each of these various cycles are going on at the same time, and so
interact with each other to produce combinations of all of these
different components. And various combinations mean various things.

There are, of course, many folks that have more knowledge of how this
all works than I do. I just used to be a mathematician.

http://www.math.nus.edu.sg/aslaksen/calendar/chinese.shtml seems like
a good place to start, but there are many other very informative sites
on the net.

=cut

sub yearofthe {
    my $year = shift;

    my $cycle = ( $year - 3 )%60;

    my $stem = $cycle % 10; # Not using this right now
    # my @stems = qw(jia yi bing ding wu ji geng xin ren gui);
    my @stems = qw(wood wood fire fire earth earth metal metal water water);
    $stem = $stems[$stem-1];

    my $branch = $cycle % 12; 
    # my @branches = qw( zi chou yin mao chen si 
    #                    wu wei shen you xu hai );
    my @branches = qw(rat ox tiger hare dragon snake horse
                      sheep monkey fowl dog pig );
    my $yearofthe = $branches[$branch - 1];

    return "Year of the $yearofthe, $stem";
}

1;

