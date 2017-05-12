package Date::Lectionary::Year;

use v5.22;
use strict;
use warnings;

use Moose;
use Carp;
use Try::Tiny;
use namespace::autoclean;
use Moose::Util::TypeConstraints;

=head1 NAME

Date::Lectionary::Year - Cycle Year for the Lectionary

=head1 VERSION

Version 1.20161227

=cut

our $VERSION = '1.20161227';

=head1 SYNOPSIS

A helper object for Date::Lectionary to package which keeps information about the liturgical cycle year for the RCL, ACNA, and possibly other three-year lectionary systems.  Valid values for the liturgical cycle are A, B, or C.

=cut

enum 'litCycleYear', [qw(A B C)];
no Moose::Util::TypeConstraints;

=head1 SUBROUTINES/METHODS

=cut

has 'year' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'litCycleYear',
    writer   => '_setName',
    init_arg => undef,
);

=head2 BUILD

Constructor for the Date::Lectionary::Year object.  Takes a four-digit representation of the Common Era year and returns the correct liturgical cycle year for the RCL, ACNA, and possibly other three-year lectionary systems.

=cut

sub BUILD {
    my $self = shift;

    $self->_setName( _determineYear( $self->year ) );
}

=head2 _determineYear

Private method that takes a four-digit representation of the Common Era year and calculates the liturgical year -- A, B, or C -- for the year.

=cut

sub _determineYear {
    my $calYear = shift;

    try {
        if ( $calYear % 3 == 0 ) {
            return 'A';
        }
        elsif ( ( $calYear - 1 ) % 3 == 0 ) {
            return 'B';
        }
        elsif ( ( $calYear - 2 ) % 3 == 0 ) {
            return 'C';
        }
        else {
            confess "The liturgical year for the year [" . $calYear
              . "] could not be determined.";
        }
    }
    catch {
        confess "A liturgical year for the value [" . $calYear
          . "] could not be calculated.";
    };
}

=head1 AUTHOR

Michael Wayne Arnold, C<< <marmanold at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-date-lectionary at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Lectionary-Year>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Lectionary::Year


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Lectionary-Year>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Lectionary-Year>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Lectionary-Year>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Lectionary-Year/>

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

1;    # End of Date::Lectionary::Year
