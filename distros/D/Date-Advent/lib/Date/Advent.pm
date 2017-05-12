package Date::Advent;

use v5.22;
use Moose;

use Carp;
use Time::Piece;
use Date::Lectionary::Time qw(nextSunday prevSunday);
use namespace::autoclean;

=head1 NAME

Date::Advent - Calculate the Sundays of Advent

=head1 VERSION

Version 1.20161222

=cut

our $VERSION = '1.20161222';

=head1 SYNOPSIS

Date::Advent takes a Time::Piece date and calculates all four Sundays of Advent for the current Christian liturgical year.

As Advent is the beginning of the Christian liturgical calendar, this usually results in the date for Advent in the current year being dates in the past.  E.g. The Sundays of Advent returned for 12. March 2016 would be 29. November 2015, 6. December 2015, 13. December 2015, and 20. December 2015.

    use Time::Piece;
    use Date::Advent;

    my $testAdvent = Date::Advent->new(date => Time::Piece->strptime("2016-01-01", "%Y-%m-%d"));
    say $testAdvent->firstSunday; #Gives date for first Sunday of Advent
    say $testAdvent->secondSunday; #Gives date for second Sunday of Advent
    say $testAdvent->thirdSunday; #Gives date for third Sunday of Advent
    say $testAdvent->fourthSunday; #Gives date for fourth Sunday of Advent
    say $testAdvent->christmas; #Gives date of Christmas

The development of this module is hosted on GitHub -- L<https://github.com/marmanold/Date-Advent> -- and tested via TravisCI.

=for html <a href='https://travis-ci.org/marmanold/Date-Advent'><img src='https://travis-ci.org/marmanold/Date-Advent.svg?branch=master' /></a>

=for html <a href='https://coveralls.io/github/marmanold/Date-Advent?branch=master'><img src='https://coveralls.io/repos/github/marmanold/Date-Advent/badge.svg?branch=master' alt='Coverage Status' /></a>

=head1 Object Attributes

=head2 date

Time::Piece date object.  Only attribute required at object construction.

=head2 christmas

Time::Piece attribute for Christmas Day as calculated from the C<date> given at object construction.

=head2 firstSunday

Time::Piece attribute for the first Sunday of Advent as calculated from the C<date> given at object construction.

=head2 secondSunday

Time::Piece attribute for the second Sunday of Advent as calculated from the C<date> given at object construction.

=head2 thirdSunday

Time::Piece attribute for the third Sunday of Advent as calculated from the C<date> given at object construction.

=head2 fourthSunday

Time::Piece attribute for the fourth Sunday of Advent as calculated from the C<date> given at object construction.

=cut

has 'date' => (
    is  => 'ro',
    isa => 'Time::Piece',
);

has 'christmas' => (
    is       => 'ro',
    isa      => 'Time::Piece',
    init_arg => undef,
    writer   => '_setChristmas',
);

has 'firstSunday' => (
    is       => 'ro',
    isa      => 'Time::Piece',
    init_arg => undef,
    writer   => '_setFirstSunday',
);

has 'secondSunday' => (
    is       => 'ro',
    isa      => 'Time::Piece',
    init_arg => undef,
    writer   => '_setSecondSunday',
);

has 'thirdSunday' => (
    is       => 'ro',
    isa      => 'Time::Piece',
    init_arg => undef,
    writer   => '_setThirdSunday',
);

has 'fourthSunday' => (
    is       => 'ro',
    isa      => 'Time::Piece',
    init_arg => undef,
    writer   => '_setFourthSunday',
);

=head1 Object Constructor

=head2 BUILD

Constructor for the Date::Advent object.  Takes the Time::Piece argument of C<date> as the date to calculate the current Christian liturgical year's Sundays of Advent from.  The resulting object is immutable and cannot be changed once created.

  my $testAdvent = Date::Advent->new(date => Time::Piece->strptime("2016-01-01", "%Y-%m-%d"));

=cut

sub BUILD {
    my $self = shift;

    my $xmasYear;
    if ( $self->date->mon == 11 || $self->date->mon == 12 ) {
        $xmasYear = $self->date->year;
    }
    else {
        $xmasYear = $self->date->year - 1;
    }

    my $christmasDay = Time::Piece->strptime( "$xmasYear-12-25", "%Y-%m-%d" );

    my $fourthAdvent = prevSunday($christmasDay);
    my $thirdAdvent  = prevSunday($fourthAdvent);
    my $secondAdvent = prevSunday($thirdAdvent);
    my $firstAdvent  = prevSunday($secondAdvent);

    if ( $self->date < $firstAdvent ) {
        $christmasDay = $christmasDay->add_years(-1);

        $fourthAdvent = prevSunday($christmasDay);
        $thirdAdvent  = prevSunday($fourthAdvent);
        $secondAdvent = prevSunday($thirdAdvent);
        $firstAdvent  = prevSunday($secondAdvent);
    }

    $self->_setChristmas($christmasDay);
    $self->_setFirstSunday($firstAdvent);
    $self->_setSecondSunday($secondAdvent);
    $self->_setThirdSunday($thirdAdvent);
    $self->_setFourthSunday($fourthAdvent);
}

=head1 AUTHOR

Michael Wayne Arnold, C<< <marmanold at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-date-advent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Advent>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Advent


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Advent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Advent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Advent>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Advent/>

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

__PACKAGE__->meta->make_immutable;

1;    # End of Date::Advent
