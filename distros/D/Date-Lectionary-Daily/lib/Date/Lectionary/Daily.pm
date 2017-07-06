package Date::Lectionary::Daily;

use v5.22;
use strict;
use warnings;

use Moose;
use Carp;
use Try::Tiny;
use XML::LibXML;
use File::Share ':all';
use Time::Piece;
use Date::Lectionary::Time qw(isSunday prevSunday);
use Date::Lectionary::Day;
use namespace::autoclean;
use Moose::Util::TypeConstraints;

=head1 NAME

Date::Lectionary::Daily - Daily Readings for the Christian Lectionary

=head1 VERSION

Version 1.20170703

=cut

=head1 SYNOPSIS

    use Time::Piece;
    use Date::Lectionary::Daily;

    my $dailyReading = Date::Lectionary::Daily->new('date' => Time::Piece->strptime("2017-12-24", "%Y-%m-%d"));
    say $dailyReading->readings->{evening}->{1}; #First lesson for evening prayer

=head1 DESCRIPTION

Date::Lectionary::Daily takes a Time::Piece date and returns ACNA readings for morning and evening prayer for that date.

=cut

our $VERSION = '1.20170703';

enum 'LectionaryType', [qw(acna)];
no Moose::Util::TypeConstraints;

=head1 SUBROUTINES/METHODS

=cut

has 'date' => (
    is       => 'ro',
    isa      => 'Time::Piece',
    required => 1,
);

has 'week' => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_setWeek',
    init_arg => undef,
);

has 'day' => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_setDay',
    init_arg => undef,
);

has 'lectionary' => (
    is      => 'ro',
    isa     => 'LectionaryType',
    default => 'acna',
);

has 'readings' => (
    is       => 'ro',
    isa      => 'HashRef',
    writer   => '_setReadings',
    init_arg => undef,
);

=head2 BUILD

Constructor for the Date::Lectionary object.  Takes a Time::Piect object, C<date>, to create the object.

=cut

sub BUILD {
    my $self = shift;

    my $sunday;
    if ( isSunday( $self->date ) ) {
        $sunday = $self->date;
    }
    else {
        $sunday = prevSunday( $self->date );
    }

    my $fixedHolyDay = 0;
    if ( $self->date->mon == 1 || $self->date->mon == 12 ) {
        $fixedHolyDay = _checkFixed( $self->date, $self->lectionary );
    }

    $self->_setWeek(
        Date::Lectionary::Day->new(
            'date'       => $sunday,
            'lectionary' => $self->lectionary
        )->name
    );

    if ($fixedHolyDay) {
        $self->_setReadings(
            _buildReadings(
                "Fixed Holy Days",
                $self->date->fullmonth . " " . $self->date->mday,
                $self->lectionary
            )
        );
    }
    else {
        $self->_setReadings(
            _buildReadings(
                $self->week, $self->date->fullday, $self->lectionary
            )
        );
    }
}

=head2 _parseLectDB

Private method to open and parse the lectionary XML to be used by other methods to XPATH queries.

=cut

sub _parseLectDB {
    my $lectionary = shift;

    my $parser = XML::LibXML->new();
    my $lectDB;

    try {
        my $data_location = dist_file( 'Date-Lectionary-Daily',
            $lectionary . '_lect_daily.xml' );
        $lectDB = $parser->parse_file($data_location);
    }
    catch {
        carp
            "The readings database for the $lectionary daily lectionary could not be found or parsed.";
    };

    return $lectDB;
}

=head2 _checkFixed

Private method to determine if the day given is a fixed holiday rather than a standard day.

=cut

sub _checkFixed {
    my $date       = shift;
    my $lectionary = shift;

    my $searchDate = $date->fullmonth . " " . $date->mday;

    my $lectDB = _parseLectDB($lectionary);

    my $fixed_xpath
        = XML::LibXML::XPathExpression->new(
        "/daily-lectionary/week[\@name=\"Fixed Holy Days\"]/day[\@name=\"$searchDate\"]/lesson"
        );

    if ( $lectDB->exists($fixed_xpath) ) {
        return 1;
    }

    return 0;
}

=head2 _buildReadings

Private method that returns an ArrayRef of strings for the lectionary readings associated with the date.

=cut

sub _buildReadings {
    my $weekName   = shift;
    my $weekDay    = shift;
    my $lectionary = shift;

    my $readings = _parseLectDB($lectionary);

    my $morn1_xpath
        = XML::LibXML::XPathExpression->new(
        "/daily-lectionary/week[\@name=\"$weekName\"]/day[\@name=\"$weekDay\"]/lesson[\@service=\"morning\" and \@order=\"1\"]"
        );
    my $morn2_xpath
        = XML::LibXML::XPathExpression->new(
        "/daily-lectionary/week[\@name=\"$weekName\"]/day[\@name=\"$weekDay\"]/lesson[\@service=\"morning\" and \@order=\"2\"]"
        );
    my $eve1_xpath
        = XML::LibXML::XPathExpression->new(
        "/daily-lectionary/week[\@name=\"$weekName\"]/day[\@name=\"$weekDay\"]/lesson[\@service=\"evening\" and \@order=\"1\"]"
        );
    my $eve2_xpath
        = XML::LibXML::XPathExpression->new(
        "/daily-lectionary/week[\@name=\"$weekName\"]/day[\@name=\"$weekDay\"]/lesson[\@service=\"evening\" and \@order=\"2\"]"
        );

    my %readings = (
        morning => {
            1 => $readings->find($morn1_xpath)->string_value(),
            2 => $readings->find($morn2_xpath)->string_value()
        },
        evening => {
            1 => $readings->find($eve1_xpath)->string_value(),
            2 => $readings->find($eve2_xpath)->string_value()
        }
    );

    return \%readings;
}

=head1 AUTHOR

Michael Wayne Arnold, C<< <marmanold at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-date-lectionary-daily at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Lectionary-Daily>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Lectionary::Daily


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Lectionary-Daily>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Lectionary-Daily>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Lectionary-Daily>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Lectionary-Daily/>

=back


=head1 ACKNOWLEDGEMENTS

Many thanks to my beautiful wife, Jennifer, and my amazing daughter, Rosemary.  But, above all, SOLI DEO GLORIA!

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Michael Wayne Arnold.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

__PACKAGE__->meta->make_immutable;

1;    # End of Date::Lectionary::Daily
