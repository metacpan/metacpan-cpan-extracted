#$Header: /home/cvs/date-sundayletter/lib/Date/SundayLetter.pm,v 1.10 2002/08/29 23:33:13 rbowen Exp $
package Date::SundayLetter;
use Date::Leapyear;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = (qw'$Revision: 1.10 $')[1];
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw (sundayletter letter);
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

# Documentation {{{

=head1 NAME

Date::SundayLetter - Calculates the Sunday Letters for a given year

=head1 SYNOPSIS

  use Date::SundayLetter;
  $letter = sundayletter( 1996 );

  - or just - 

  $letter = letter( 1996 );

=head1 DESCRIPTION

Sunday Letters are an important concept from calendrics. Stated very
simply, the sunday letter represents how many days after January 1 the
first Sunday of the year is. Knowing the makes it easy to calculate
the day of the week of a given day, when Easter falls, and a variety
of other things.

There is a full treatment of Sunday Latters in The Oxford Companion to
the Year (Blackburn, Holford-Strevens).

For example, the following table shows the Sunday Letters, given the
day of the week of January 1:

 1 January      First Sunday    Sunday Letter
 Sunday         1 January       A
 Monday         7 January       G
 Tuesday        6 January       F
 Wednesday      5 January       E
 Thursday       4 January       D
 Friday         3 January       C
 Saturday       2 January       B

In leap years, you have two Sunday Letters. After leap day, you have a
Sunday Letter calculated with the usual formulae. Before leap day, the
Sunday Letter is one place ahead of that (with A being considered one
latter after G).

Given the Sunday Letter and the Golden Number (see
Date::GoldenNumber), you can immediately look up the dates for Easter
(Gregorian or Julian) in a simple table. That is, if you happen to
have said table. I'll try to put this table on my web site, but I need
to ask the authors of The Oxford Companion first.

=head1 SUPPORT

For support, email me directly (drbacchus@drbacchus.com) or subscribe
to datetime@perl.org (see http://lists.perl.org/ for subscription
information) and ask there.

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
 Date::ICal
 Reefknot (http://reefknot.org/)
 Date::Easter
 Date::Passover
 Date::Leapyear

=cut

# }}}

# sub sundayletter {{{

sub letter { return sundayletters(@_) }

sub sundayletters {
    my $year = shift;
    
    my @letters = qw(A G F E D C B);

    my $p = parameter($year);

    my $q = int($year / 4); # divide by 4, discard remainder
    my $t = $year + $q + $p; # Add quotient to year, and add
                             # the parameter.
    my $d = $t % 7; # Remainder when divided by 7 gives the
                    # displacement from January 1 to the first Sunday
                    # of the year.

    my $letter;
    if (Date::Leapyear::isleap( $year )) {
        $letter = $letters[$d-1] . $letters[$d] ;
    } else {
        $letter = $letters[$d];
    }

    return $letter;
} #}}}

# sub parameter {{{

sub parameter {
# The "parameter" is a magic number that tracks how far the Gregorian
# calendar is from the Julian calendar. It has roughly to do with the
# fact that the Gregorian calendar observes leap year on the 4-century
# mark, and the Julian calendar does not.
    my $year = shift;

    my $S = int ($year / 100 );
    my $P = ( int( $S/4 ) - $S ) % 7;

    return $P;
} # }}}

1;


