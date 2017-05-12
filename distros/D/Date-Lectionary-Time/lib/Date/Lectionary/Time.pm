package Date::Lectionary::Time;

use v5.22;
use strict;
use warnings;

use Exporter::Easy ( OK => [qw(nextSunday prevSunday closestSunday isSunday)], );

use Carp;
use Try::Tiny;
use Time::Piece;
use Time::Seconds;

=head1 NAME

Date::Lectionary::Time - Find your way in time relative to Sundays.

=head1 VERSION

Version 1.20170311

=cut

our $VERSION = '1.20170311';

=head1 SYNOPSIS

Working in the liturgical time of the lectionary means tracking time relative to Sundays.  This is a quick utility to find the next, previous, or the closest Sunday to a given date.  Further, it can determine if the date given is a Sunday or not.

	use Time::Piece;
	use Date::Lectionary::Time qw(nextSunday prevSunday closestSunday isSunday);

	my $christmasDay = Time::Piece->strptime("2015-12-25", "%Y-%m-%d");

    if (isSunday($christmasDay)) {
        say "Christmas is on a Sunday!";
    }
    else {
        say "Christmas isn't on a Sunday.";
    }

	my $sundayAfterChristmas = nextSunday($christmasDay);
	my $sundayBeforeChristmas = prevSunday($christmasDay);
	my $sundayClosestToChristmas = closestSunday($christmasDay);

=head1 EXPORTS

nextSunday

prevSunday

closestSunday

isSunday

  use Date::Lectionary::Time qw(nextSunday prevSunday closestSunday isSunday);

=head1 SUBROUTINES/METHODS

=head2 nextSunday

For a given Time::Piece date returns a Time::Piece object of the date of the Sunday immediately following the given date.

=cut

sub nextSunday {
    my ( $class, @params ) = @_;
    my $date = $params[0] // $class;
    my $nextSunday = undef;

    if ( !length $date ) {
        croak
"Method [nextSunday] expects an input argument of type Time::Piece.  The given type could not be determined.";
    }

    if ( $date->isa('Time::Piece') ) {
        try {
            my $daysToAdd    = 7 - $date->_wday;
            my $secondsToAdd = $daysToAdd * ONE_DAY;
            $nextSunday = $date + $secondsToAdd;
        }
        catch {
            croak "Could not calculate the next Sunday after $date.";
        };
    }
    else {
        croak
          "Method [nextSunday] expects an input argument of type Time::Piece.";
    }

    return $nextSunday;
}

=head2 prevSunday

For a given Time::Piece date returns a Time::Piece object of the date of the Sunday immediately before the given date.

=cut

sub prevSunday {
    my ( $class, @params ) = @_;
    my $date = $params[0] // $class;
    my $prevSunday = undef;

    if ( !length $date ) {
        croak
"Method [prevSunday] expects an input argument of type Time::Piece.  The given type could not be determined.";
    }

    if ( $date->isa('Time::Piece') ) {
        try {
            my $daysToSubtract = $date->_wday;
            if ( $daysToSubtract == 0 ) { $daysToSubtract = 7; }
            my $secondsToSubtract = $daysToSubtract * ONE_DAY;
            $prevSunday = $date - $secondsToSubtract;
        }
        catch {
            carp "Could not calculate the previous Sunday before $date.";
        };
    }
    else {
        croak
          "Method [prevSunday] expects an input argument of type Time::Piece.";
    }

    return $prevSunday;
}

=head2 closestSunday

For a given Time::Piece date returns a Time::Piece object of the date of the Sunday closest to the given date.

=cut

sub closestSunday {
    my ( $class, @params ) = @_;
    my $date = $params[0] // $class;
    my $closestSunday = undef;

    if ( !length $date ) {
        croak
"Method [closestSunday] expects an input argument of type Time::Piece.  The given type could not be determined.";
    }

    if ( $date->isa('Time::Piece') ) {
        try {
            my $nextSunday = nextSunday($date);
            my $prevSunday = prevSunday($date);

            my ( $dif1, $dif2 );

            $dif1 = abs( $date - $nextSunday );
            $dif2 = abs( $prevSunday - $date );

            if ( $dif1 < $dif2 ) {
                $closestSunday = $nextSunday;
            }
            elsif ( $dif1 == $dif2 ) {
                $closestSunday = $date;
            }
            else {
                $closestSunday = $prevSunday;
            }
        }
        catch {
            carp "Could not calculate the Sunday closest to $date.";
        };
    }
    else {
        croak
"Method [closestSunday] expects an input argument of type Time::Piece.";
    }

    return $closestSunday;
}

=head2 isSunday

For a given Time::Piece date returns C<1> if the date is a Sunday or C<0> if the date isn't a Sunday.

=cut

sub isSunday {
    my ( $class, @params ) = @_;
    my $date = $params[0] // $class;
    my $isSunday = 0;

    if ( !length $date ) {
        croak
"Method [isSunday] expects an input argument of type Time::Piece.  The given type could not be determined.";
    }

    if ( $date->isa('Time::Piece') ) {
        try {
            if ($date->wday == 1) {
                $isSunday = 1;
            }
        }
        catch {
            carp "Could not calculate the Sunday closest to $date.";
        };
    }
    else {
        croak
"Method [isSunday] expects an input argument of type Time::Piece.";
    }

    return $isSunday;
}

=head1 AUTHOR

Michael Wayne Arnold, C<< <marmanold at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-date-lectionary-time at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Lectionary-Time>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Lectionary::Time

The development of this module is hosted on GitHub -- L<https://github.com/marmanold/Date-Lectionary-Time> -- and tested via TravisCI.

=for html <a href='https://travis-ci.org/marmanold/Date-Lectionary-Time'><img src='https://travis-ci.org/marmanold/Date-Lectionary-Time.svg?branch=master' /></a>

=for html <a href='https://coveralls.io/github/marmanold/Date-Lectionary-Time?branch=master'><img src='https://coveralls.io/repos/github/marmanold/Date-Lectionary-Time/badge.svg?branch=master' alt='Coverage Status' /></a>

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Lectionary-Time>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Lectionary-Time>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Lectionary-Time>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Lectionary-Time/>

=back

=head1 ACKNOWLEDGEMENTS

Many thanks to my beautiful wife, Jennifer, and my amazing daughter, Rosemary.  But, above all, SOLI DEO GLORIA!

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Michael Wayne Arnold.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1;    # End of Date::Lectionary::Time
