package Date::Lectionary::Daily;

use v5.22;
use strict;
use warnings;

use Try::Tiny::Tiny;

use Moose;
use Carp;
use Try::Catch;
use XML::LibXML;
use File::Share ':all';
use Time::Piece;
use Date::Lectionary::Time qw(isSunday prevSunday);
use Date::Lectionary::Day;
use namespace::autoclean;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;

=head1 NAME

Date::Lectionary::Daily - Daily Readings for the Christian Lectionary

=head1 VERSION

Version 1.20180316

=cut

=head1 SYNOPSIS

    use Time::Piece;
    use Date::Lectionary::Daily;

    #Using the old ACNA Liturgical Daily Lectionary
    my $dailyReading = Date::Lectionary::Daily->new(
        'date' => Time::Piece->strptime("2017-12-24", "%Y-%m-%d"), 
        'lectionary' => 'acna-xian'
    );
    say $dailyReading->readings->{evening}->{1}; #First lesson for evening prayer, Isaiah 51

    #Using the new ACNA Secular/Civil Daily Lectionary
    my $dailyNewReading = Date::Lectionary::Daily->new( 
        'date' => Time::Piece->strptime( "2018-03-12", "%Y-%m-%d" ), 
        'lectionary' => 'acna-sec' 
    );
    say $dailyNewReading->readings->{morning}->{2}; #Second lesson for morning prayer, Matthew 5

=head1 DESCRIPTION

Date::Lectionary::Daily takes a Time::Piece date and returns readings for morning and evening prayer for that date.

=head2 CONSTRUCTOR ATTRIBUTES

=head3 date

The Time::Piece object date of the day you woudl like the lessons for.

=head3 lectionary

One of two choices `acna-sec` for the new secular calendar based ACNA daily lectionary or `acna-xian` for the previous liturgically-based ACNA daily lectionary.

If lectionary is not given at construction, the ACNA secular daily lectionary — `acna-sec` — will be used.

=head2 ATTRIBUTES

=head3 week

The name of the liturgical week in the lectionary; e.g. `The First Sunday in Lent`.

=head3 day

The name of the day of the week; e.g. `Sunday`.

=head3 tradition

Presently only returns `acna`.  Future version of the module may include daily lectionary from other traditions.

=head3 type

Returns `secular` for daily lectionaries based on the secular/civil calendar and `liturgical` for daily lectionaries based on the liturgical calendar.

=head3 readings

A hasref of the readings for the day.

=cut

our $VERSION = '1.20180316';

enum 'DailyLectionary', [qw(acna-sec acna-xian)];
enum 'Tradition',       [qw(acna)];
enum 'LectionaryType',  [qw(secular liturgical)];
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
    isa     => 'DailyLectionary',
    default => 'acna-sec',
);

has 'tradition' => (
    is       => 'ro',
    isa      => 'Tradition',
    writer   => '_setTradition',
    init_arg => undef,
);

has 'type' => (
    is       => 'ro',
    isa      => 'LectionaryType',
    writer   => '_setType',
    init_arg => undef,
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

    $self->_setTradition( _buildTradition( $self->lectionary ) );
    $self->_setType( _buildType( $self->lectionary ) );

    my $sunday;
    if ( isSunday( $self->date ) ) {
        $sunday = $self->date;
    }
    else {
        $sunday = prevSunday( $self->date );
    }

    my $fixedHolyDay = 0;
    if ( $self->lectionary eq 'acna-xian' && ( $self->date->mon == 1 || $self->date->mon == 12 ) ) {
        $fixedHolyDay = _checkFixed( $self->date, $self->lectionary );
    }

    $self->_setWeek(
        Date::Lectionary::Day->new(
            'date'          => $sunday,
            'lectionary'    => $self->tradition,
            'includeFeasts' => 'no',
        )->name
    );

    if ( $self->type eq 'liturgical' ) {
        if ($fixedHolyDay) {
            $self->_setReadings( _buildReadingsLiturgical( "Fixed Holy Days", $self->date->fullmonth . " " . $self->date->mday, $self->lectionary ) );
        }
        else {
            $self->_setReadings( _buildReadingsLiturgical( $self->week, $self->date->fullday, $self->lectionary ) );
        }
    }
    elsif ( $self->type eq 'secular' ) {
        $self->_setReadings( _buildReadingsSecular( $self->week, $self->date, $self->lectionary ) );
    }

}

=head2 _buildType

Private method to determine if the daily lectionary follows the secular calendar or the liturgical calendar.

=cut

sub _buildType {
    my $lectionary = shift;

    if ( $lectionary eq 'acna-xian' ) {
        return 'liturgical';
    }
    if ( $lectionary eq 'acna-sec' ) {
        return 'secular';
    }

    return undef;
}

=head2 _buildTradition

Private method to determine the Sunday lectionary tradition of the daily lectionary selected. Used to determine the liturgical week the day falls within.

=cut

sub _buildTradition {
    my $lectionary = shift;

    if ( $lectionary eq 'acna-xian' || $lectionary eq 'acna-sec' ) {
        return 'acna';
    }

    return undef;
}

=head2 _parseLectDB

Private method to open and parse the lectionary XML to be used by other methods to XPATH queries.

=cut

sub _parseLectDB {
    my $lectionary = shift;

    my $parser = XML::LibXML->new();
    my $lectDB;

    try {
        my $data_location = dist_file( 'Date-Lectionary-Daily', $lectionary . '_lect_daily.xml' );
        $lectDB = $parser->parse_file($data_location);
    }
    catch {
        carp "The readings database for the $lectionary daily lectionary could not be found or parsed.";
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

    my $fixed_xpath;

    try {
        $fixed_xpath = XML::LibXML::XPathExpression->new("/daily-lectionary/week[\@name=\"Fixed Holy Days\"]/day[\@name=\"$searchDate\"]/lesson");
    }
    catch {
        carp "Could not compile the XPath Expression for $searchDate in the $lectionary lectionary.";
    };

    if ( $lectDB->exists($fixed_xpath) ) {
        return 1;
    }

    return 0;
}

=head2 _buildReadingsLiturgical

Private method that returns an ArrayRef of strings for the lectionary readings associated with the date according to the liturgical calendar.

=cut

sub _buildReadingsLiturgical {
    my $weekName   = shift;
    my $weekDay    = shift;
    my $lectionary = shift;

    my $readings = _parseLectDB($lectionary);

    my $morn1_xpath;
    my $morn2_xpath;
    my $eve1_xpath;
    my $eve2_xpath;
    try {
        $morn1_xpath = XML::LibXML::XPathExpression->new("/daily-lectionary/week[\@name=\"$weekName\"]/day[\@name=\"$weekDay\"]/lesson[\@service=\"morning\" and \@order=\"1\"]");
        $morn2_xpath = XML::LibXML::XPathExpression->new("/daily-lectionary/week[\@name=\"$weekName\"]/day[\@name=\"$weekDay\"]/lesson[\@service=\"morning\" and \@order=\"2\"]");
        $eve1_xpath  = XML::LibXML::XPathExpression->new("/daily-lectionary/week[\@name=\"$weekName\"]/day[\@name=\"$weekDay\"]/lesson[\@service=\"evening\" and \@order=\"1\"]");
        $eve2_xpath  = XML::LibXML::XPathExpression->new("/daily-lectionary/week[\@name=\"$weekName\"]/day[\@name=\"$weekDay\"]/lesson[\@service=\"evening\" and \@order=\"2\"]");
    }
    catch {
        carp "Could not compile the XPath Expression for $weekDay in $weekName in the $lectionary lectionary.";
    };

    my %readings;
    try {
        %readings = (
            morning => {
                1 => $readings->find($morn1_xpath)->string_value(),
                2 => $readings->find($morn2_xpath)->string_value()
            },
            evening => {
                1 => $readings->find($eve1_xpath)->string_value(),
                2 => $readings->find($eve2_xpath)->string_value()
            }
        );
    }
    catch {
        carp "The readings for $weekDay in $weekName in the $lectionary lectionary could not be found.";
    };

    return \%readings;
}

=head2 _buildReadingsSecular

Private method that returns an ArrayRef of strings for the lectionary readings associated with the date according to the secular calendar.

=cut

sub _buildReadingsSecular {
    my $weekName   = shift;
    my $date       = shift;
    my $lectionary = shift;

    my $readings = _parseLectDB($lectionary);

    my $seekDate = substr( $date->ymd, 5, 5 );

    my $morn1_xpath;
    my $morn2_xpath;
    my $eve1_xpath;
    my $eve2_xpath;
    try {
        $morn1_xpath = XML::LibXML::XPathExpression->new("/daily-lectionary/day[\@date=\"$seekDate\"]/lesson[\@service=\"morning\" and \@order=\"1\"]");
        $morn2_xpath = XML::LibXML::XPathExpression->new("/daily-lectionary/day[\@date=\"$seekDate\"]/lesson[\@service=\"morning\" and \@order=\"2\"]");
        $eve1_xpath  = XML::LibXML::XPathExpression->new("/daily-lectionary/day[\@date=\"$seekDate\"]/lesson[\@service=\"evening\" and \@order=\"1\"]");
        $eve2_xpath  = XML::LibXML::XPathExpression->new("/daily-lectionary/day[\@date=\"$seekDate\"]/lesson[\@service=\"evening\" and \@order=\"2\"]");
    }
    catch {
        carp "Could not compile the XPath Expression for $seekDate in $weekName in the $lectionary lectionary.";
    };

    my %readings;
    try {
        %readings = (
            morning => {
                1 => $readings->find($morn1_xpath)->string_value(),
                2 => $readings->find($morn2_xpath)->string_value()
            },
            evening => {
                1 => $readings->find($eve1_xpath)->string_value(),
                2 => $readings->find($eve2_xpath)->string_value()
            }
        );
    }
    catch {
        carp "The readings for $seekDate in $weekName in the $lectionary lectionary could not be found.";
    };

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

Many thanks to my beautiful wife, Jennifer, my amazing daughter, Rosemary, and my sweet  son, Oliver.  But, above all, SOLI DEO GLORIA!

=head1 LICENSE

Copyright 2017-2018 MICHAEL WAYNE ARNOLD

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__->meta->make_immutable;

1;    # End of Date::Lectionary::Daily
