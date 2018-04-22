package Date::Lectionary::Day;

use v5.22;
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Aliases;
use Carp;
use Try::Catch;
use Time::Piece;
use Time::Seconds;
use Date::Advent;
use Date::Easter;
use Date::Lectionary::Time qw(nextSunday prevSunday closestSunday);
use namespace::autoclean;
use Moose::Util::TypeConstraints;
use File::Share ':all';
use XML::LibXML;

=head1 NAME

Date::Lectionary::Day - Determines the Day in the Christian Liturgical Year

=head1 VERSION

Version 1.20180422

=cut

use version; our $VERSION = version->declare("v1.20180422");

=head1 SYNOPSIS

A helper object for Date::Lectionary to determine the liturgical name(s) and type for the given day according to a given lectionary.

=cut

enum 'DayType',        [qw(fixedFeast moveableFeast Sunday noLect)];
enum 'LectionaryType', [qw(acna rcl)];
enum 'MultiLect',      [qw(yes no)];
enum 'IncludeFeasts',  [qw(yes no)];
no Moose::Util::TypeConstraints;

=head1 SUBROUTINES/METHODS/ATTRIBUTES

=head2 ATTRIBUTES

=head3 date

The Time::Piece object date given at object construction.

=head3 lectionary

An optional attribute given at object creation time.  Valid values are 'acna' for the Anglican Church of North America lectionary and 'rcl' for the Revised Common Lectionary.  This attribute defaults to 'acna' if no value is given.

=head3 type

Stores the type of liturgical day. 'fixedFeast' is returned for non-moveable feast days such as Christmas Day. 'moveableFeast' is returned for moveable feast days.  Moveable feasts move to a Monday when they occure on a Sunday. 'Sunday' is returned for non-fixed feast Sundays of the liturgical year.  'noLect' is returned for days with no feast day or Sunday readings.

=head3 name

The name of the day in the lectionary.  For noLect days a String representation of the day is returned as the name.

=head3 alt

The alternative name --- if one is given --- of the day in the lectionary.  If there is no alternative name for the day, then the empty string will be returned.

=head3 multiLect

Returns 'yes' if the day has multiple services with readings associated with it.  (E.g. Christmas Day, Easter, etc.)  Returns 'no' if the day is a normal lectioanry day with only one service and one set of readings.

=head3 subLects

An ArrayRef of the names of the multiple services that occur on a multiLect day.

=head3 includeFeasts

If this is set to 'yes' --- the default value --- the module will include fixed and moveable feasts in its determination of which liturgical Sunday it is.

If set to 'no', it will exclude fixed and moveable feasts.  Excluding feasts is useful when using Date::Lectionary::Day in combination with a daily lectionary such as Date::Lectioary::Daily where a fixed feast such as The Transfiguration can conflict with determining the Sunday to use for the daily lectionary.

=cut

has 'date' => (
    is       => 'ro',
    isa      => 'Time::Piece',
    required => 1,
);

has 'type' => (
    is       => 'ro',
    isa      => 'DayType',
    writer   => '_setType',
    init_arg => undef,
);

has 'lectionary' => (
    is      => 'ro',
    isa     => 'LectionaryType',
    default => 'acna',
);

has 'displayName' => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_setDisplayName',
    init_arg => undef,
    alias    => 'name',
);

has 'altName' => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_setAltName',
    init_arg => undef,
    alias    => 'alt',
);

has 'commonName' => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_setCommonName',
    init_arg => undef,
);

has 'multiLect' => (
    is       => 'ro',
    isa      => 'MultiLect',
    writer   => '_setMultiLect',
    init_arg => undef,
);

has 'subLects' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    writer   => '_setSubLects',
    init_arg => undef,
);

has 'includeFeasts' => (
    is      => 'ro',
    isa     => 'IncludeFeasts',
    default => 'yes',
);

=head2 BUILD

Constructor for the Date::Lectionary object.  Takes a Time::Piect object, C<date>, to create the object.

=cut

sub BUILD {
    my $self = shift;

    my $advent = _determineAdvent( $self->date );
    my $easter = _determineEaster( $advent->firstSunday->year + 1 );

    my %commonNameInfo = _determineDay( $self->date, $self->lectionary, $self->includeFeasts, $advent, $easter );
    $self->_setCommonName( $commonNameInfo{commonName} );
    $self->_setDisplayName( _determineDisplayName( $self->lectionary, $commonNameInfo{commonName} ) );
    $self->_setAltName( _determineAltName( $self->lectionary, $commonNameInfo{commonName} ) );

    $self->_setType( $commonNameInfo{type} );

    my %multiLectInfo = _determineMultiLect( $self->lectionary, $commonNameInfo{commonName} );
    $self->_setMultiLect( $multiLectInfo{multiLect} );
    $self->_setSubLects( $multiLectInfo{multiNames} );
}

=head2 _determineMultiLect

Private method to determine if the day has multiple lectionary services and readings for the day.

=cut

sub _determineMultiLect {
    my $tradition  = shift;
    my $commonName = shift;

    my $parser = XML::LibXML->new();
    my $data_location;
    my $lectionary;

    try {
        $data_location = dist_file( 'Date-Lectionary', 'date_lectionary_xref.xml' );
        $lectionary = $parser->parse_file($data_location);
    }
    catch {
        confess "The lectionary cross reference file could not be found or parsed.";
    };

    my $compiled_xpath;

    try {
        $compiled_xpath = XML::LibXML::XPathExpression->new("/xref/day[\@multi=\"$commonName\"]/alt[\@type='$tradition']");
    }
    catch {
        confess "The XPATH expression to to query the cross reference database could not be compiled.";
    };

    my @multiNames;

    try {
        if ( $lectionary->exists($compiled_xpath) ) {
            my @nodes = $lectionary->findnodes($compiled_xpath);
            foreach my $node (@nodes) {
                push( @multiNames, $node->textContent );
            }
            return ( multiLect => 'yes', multiNames => \@multiNames );
        }
        else {
            return ( multiLect => 'no', multiNames => \@multiNames );
        }
    }
    catch {
        confess "An unpected error occured while querying the cross reference database.";
    };
}

=head2 _determineDisplayName

Private method to determine the unique display name for the day.

=cut

sub _determineDisplayName {
    my $tradition  = shift;
    my $commonName = shift;

    my $parser = XML::LibXML->new();
    my $data_location;
    my $lectionary;

    try {
        $data_location = dist_file( 'Date-Lectionary', 'date_lectionary_xref.xml' );
        $lectionary = $parser->parse_file($data_location);
    }
    catch {
        confess "The lectionary cross reference file could not be found or parsed.";
    };

    my $compiled_xpath;
    my $multi_xpath;

    try {
        $compiled_xpath = XML::LibXML::XPathExpression->new("/xref/day[\@name=\"$commonName\"]/alt[\@type='$tradition']");
        $multi_xpath    = XML::LibXML::XPathExpression->new("/xref/day[\@multi=\"$commonName\"]");
    }
    catch {
        confess "The XPATH expression to to query the cross reference database could not be compiled.";
    };

    my $displayName;

    try {
        $displayName = $lectionary->findvalue($compiled_xpath);

        if ( $lectionary->exists($multi_xpath) ) {
            return $commonName;
        }
        elsif ( $displayName eq '' ) {
            return $commonName;
        }
        else {
            return $displayName;
        }
    }
    catch {
        confess "An unpected error occured while querying the cross reference database.";
    };

}

=head2 _determineAltName

Private method to determine if the day has any alternative names for the day.

=cut

sub _determineAltName {
    my $tradition  = shift;
    my $commonName = shift;

    my $parser = XML::LibXML->new();
    my $data_location;
    my $lectionary;

    try {
        $data_location = dist_file( 'Date-Lectionary', 'date_lectionary_xref.xml' );
        $lectionary = $parser->parse_file($data_location);
    }
    catch {
        confess "The lectionary cross reference file could not be found or parsed.";
    };

    my $compiled_xpath;
    my $multi_xpath;

    try {
        $compiled_xpath = XML::LibXML::XPathExpression->new("/xref/day[\@name=\"$commonName\"]/alt[\@type='$tradition-alt']");
    }
    catch {
        confess "The XPATH expression to to query the cross reference database could not be compiled.";
    };

    my $altName;

    try {
        $altName = $lectionary->findvalue($compiled_xpath);
        return $altName;
    }
    catch {
        confess "An unpected error occured while querying the cross reference database.";
    };

}

=head2 _determineAdvent

Private method that takes a Time::Piece date object to returns a Date::Advent object containing the dates for Advent of the current liturgical year.

=cut

sub _determineAdvent {
    my $date = shift;

    my $advent = undef;

    try {
        $advent = Date::Advent->new( date => $date );
        return $advent;
    }
    catch {
        confess "Could not calculate Advent for the given date [" . $date->ymd . "].";
    };
}

=head2 _determineEaster

Private method that takes a four-digit representation of a Common Era year and calculates the date for Easter as a Time::Piece object.

=cut

sub _determineEaster {
    my $easterYear = shift;

    my $easter = undef;

    try {
        my ( $easterMonth, $easterDay ) = easter($easterYear);
        $easter = Time::Piece->strptime( $easterYear . "-" . $easterMonth . "-" . $easterDay, "%Y-%m-%d" );
        return $easter;
    }
    catch {
        confess "Could not calculate Easter for the year [" . $easterYear . "]";
    };
}

=head2 _determineFeasts

Private method that takes the Time::Piece date given at construction and determines if the date is one of many feasts in the liturgical calendar.  Feasts are taken from the Anglican Church in North America's revision of the revised common lectionary.

=cut

sub _determineFeasts {
    my $date       = shift;
    my $lectionary = shift;

    my $yesterday = $date - ONE_DAY;

    my $yesterdayName;
    if ( $yesterday->wday == 1 ) {
        $yesterdayName = _buildMoveableDays( $yesterday, $lectionary );
    }

    if ($yesterdayName) {
        return ( commonName => $yesterdayName, type => 'moveableFeast' );
    }

    my $fixedDayName = _buildFixedDays( $date, $lectionary );
    if ($fixedDayName) {
        return ( commonName => $fixedDayName, type => 'fixedFeast' );
    }

    my $moveableDayName = _buildMoveableDays( $date, $lectionary );
    if ( $moveableDayName && $date->wday != 1 ) {
        return ( commonName => $moveableDayName, type => 'moveableFeast' );
    }

    return ( commonName => undef, type => undef );
}

=head2 _buildMoveableDays

Private method that takes the Time::Piece date given at construction and determines if the date is one of many moveable feasts in the liturgical calendar.  Feasts are taken from the Anglican Church in North America's revision of the revised common lectionary.

=cut

sub _buildMoveableDays {
    my $date       = shift;
    my $lectionary = shift;

    #Moveable holidays in January
    if ( $date->mon == 1 ) {
        if ( $date->mday == 18 && $lectionary eq 'acna' ) {
            return "Confession of St. Peter";
        }
        if ( $date->mday == 25 && $lectionary eq 'acna' ) {
            return "Conversion of St. Paul";
        }
    }

    #Moveable holidays in February
    elsif ( $date->mon == 2 ) {
        if ( $date->mday == 2 ) {
            return "The Presentation of Christ in the Temple";
        }
        if ( $date->mday == 24 && $lectionary eq 'acna' ) {
            return "St. Matthias";
        }
    }

    #Moveable holidays in March
    elsif ( $date->mon == 3 ) {
        if ( $date->mday == 19 && $lectionary eq 'acna' ) {
            return "St. Joseph";
        }
        if ( $date->mday == 25 ) {
            return "The Annunciation";
        }
    }

    #Moveable holidays in April
    elsif ( $date->mon == 4 ) {
        if ( $date->mday == 25 && $lectionary eq 'acna' ) {
            return "St. Mark";
        }
    }

    #Moveable holidays in May
    elsif ( $date->mon == 5 ) {
        if ( $date->mday == 1 && $lectionary eq 'acna' ) {
            return "St. Philip & St. James";
        }
        if ( $date->mday == 31 ) {
            return "The Visitation";
        }
    }

    #Moveable holidays in June
    elsif ( $date->mon == 6 ) {
        if ( $date->mday == 11 && $lectionary eq 'acna' ) {
            return "St. Barnabas";
        }
        if ( $date->mday == 24 && $lectionary eq 'acna' ) {
            return "Nativity of St. John the Baptist";
        }
        if ( $date->mday == 29 && $lectionary eq 'acna' ) {
            return "St. Peter & St. Paul";
        }
    }

    #Moveable holidays in July
    elsif ( $date->mon == 7 ) {
        if ( $date->mday == 22 && $lectionary eq 'acna' ) {
            return "St. Mary Magdalene";
        }
        if ( $date->mday == 25 && $lectionary eq 'acna' ) {
            return "St. James";
        }
    }

    #Moveable holidays in August
    elsif ( $date->mon == 8 ) {
        if ( $date->mday == 15 && $lectionary eq 'acna' ) {
            return "St. Mary the Virgin";
        }
        if ( $date->mday == 24 && $lectionary eq 'acna' ) {
            return "St. Bartholomew";
        }
    }

    #Moveable holidays in September
    elsif ( $date->mon == 9 ) {
        if ( $date->mday == 14 ) {
            return "Holy Cross Day";
        }
        if ( $date->mday == 21 && $lectionary eq 'acna' ) {
            return "St. Matthew";
        }
        if ( $date->mday == 29 && $lectionary eq 'acna' ) {
            return "Holy Michael & All Angels";
        }
    }

    #Moveable holidays in October
    elsif ( $date->mon == 10 ) {
        if ( $date->mday == 18 && $lectionary eq 'acna' ) {
            return "St. Luke";
        }
        if ( $date->mday == 28 && $lectionary eq 'acna' ) {
            return "St. Simon & St. Jude";
        }
    }

    #Moveable holidays in November
    elsif ( $date->mon == 11 ) {
        if ( $date->mday == 30 && $lectionary eq 'acna' ) {
            return "St. Andrew";
        }
    }

    #Moveable holidays in December
    elsif ( $date->mon == 12 ) {
        if ( $date->mday == 21 && $lectionary eq 'acna' ) {
            return "St. Thomas";
        }
        if ( $date->mday == 26 && $lectionary eq 'acna' ) {
            return "St. Stephen";
        }
        if ( $date->mday == 27 && $lectionary eq 'acna' ) {
            return "St. John";
        }
        if ( $date->mday == 28 && $lectionary eq 'acna' ) {
            return "Holy Innocents";
        }
    }
    else {
        confess "Date [" . $date->ymd . "] is not a known or valid date.";
    }
}

=head2 _buildFixedDays

Private method that takes the Time::Piece date given at construction and determines if the date is one of many fixed (non-moveable) feasts in the liturgical calendar.  Fixed feasts are taken from the Anglican Church in North America's revision of the revised common lectionary.

=cut

sub _buildFixedDays {
    my $date       = shift;
    my $lectionary = shift;

    #Fixed holidays in January
    if ( $date->mon == 1 ) {
        if ( $date->mday == 1 ) {
            return "Holy Name";
        }
        if ( $date->mday == 6 ) {
            return "The Epiphany";
        }
    }

    #Fixed holidays in February
    elsif ( $date->mon == 2 ) {
    }

    #Fixed holidays in March
    elsif ( $date->mon == 3 ) {
    }

    #Fixed holidays in April
    elsif ( $date->mon == 4 ) {
    }

    #Fixed holidays in May
    elsif ( $date->mon == 5 ) {
    }

    #Fixed holidays in June
    elsif ( $date->mon == 6 ) {
    }

    #Fixed holidays in July
    elsif ( $date->mon == 7 ) {
    }

    #Fixed holidays in August
    elsif ( $date->mon == 8 ) {
        if ( $date->mday == 6 && $lectionary eq 'acna' ) {
            return "The Transfiguration";
        }
    }

    #Fixed holidays in September
    elsif ( $date->mon == 9 ) {
    }

    #Fixed holidays in October
    elsif ( $date->mon == 10 ) {
    }

    #Fixed holidays in November
    elsif ( $date->mon == 11 ) {
        if ( $date->mday == 1 ) {
            return "All Saints' Day";
        }
    }

    #Fixed holidays in December
    elsif ( $date->mon == 12 ) {
        if ( $date->mday == 25 ) {
            return "Christmas Day";
        }
    }
    else {
        confess "Date [" . $date->ymd . "] is not a known or valid date.";
    }
}

=head2 _determineAshWednesday

Private method that takes the Time::Piece date for Easter and determines the date for Ash Wednesday.  Ash Wednesday is the start of Lent.  It occurs 46 days before Easter for the given year.

=cut

sub _determineAshWednesday {
    my $easter = shift;

    my $ashWednesday = undef;

    try {
        my $secondsToSubtract = 46 * ONE_DAY;
        $ashWednesday = $easter - $secondsToSubtract;
        return $ashWednesday;
    }
    catch {
        confess "Could not calculate Ash Wednesday for Easter [" . $easter->ymd . "].";
    };
}

=head2 _determineAscension

Private method that takes the Time::Piece date for Easter and determines the date for Ascension.  Ascension is forty days (inclusive) after Easter.

=cut

sub _determineAscension {
    my $easter = shift;

    my $ascension = undef;

    try {
        my $secondsToAdd = 39 * ONE_DAY;
        $ascension = $easter + $secondsToAdd;
        return $ascension;
    }
    catch {
        confess "Could not calculate Ascension for Easter [" . $easter->ymd . "].";
    };
}

=head2 _determinePentecost

Private method the takes the Time::Piece date for Easter and determines the date for Pentecost.  Pentecost is fifty days (inclusive) after Easter.

=cut

sub _determinePentecost {
    my $easter = shift;

    my $pentecost = undef;

    try {
        my $secondsToAdd = 49 * ONE_DAY;
        $pentecost = $easter + $secondsToAdd;
        return $pentecost;
    }
    catch {
        confess "Could not calculate Pentecost for Easter [" . $easter->ymd . "].";
    };
}

=head2 _determineHolyWeek

Private method used to return the names of various days within Holy Week.  Takes the Time::Piece date given at construction and the Time::Piece date for Easter.  Returns undef if the date given at construction is not found in Holy Week.

=cut

sub _determineHolyWeek {
    my $date   = shift;
    my $easter = shift;

    my $dateMark = $easter - ONE_DAY;
    if ( $date == $dateMark ) {
        return "Holy Saturday";
    }

    $dateMark = $dateMark - ONE_DAY;
    if ( $date == $dateMark ) {
        return "Good Friday";
    }

    $dateMark = $dateMark - ONE_DAY;
    if ( $date == $dateMark ) {
        return "Maundy Thursday";
    }

    $dateMark = $dateMark - ONE_DAY;
    if ( $date == $dateMark ) {
        return "Wednesday in Holy Week";
    }

    $dateMark = $dateMark - ONE_DAY;
    if ( $date == $dateMark ) {
        return "Tuesday in Holy Week";
    }

    $dateMark = $dateMark - ONE_DAY;
    if ( $date == $dateMark ) {
        return "Monday in Holy Week";
    }

    $dateMark = $dateMark - ONE_DAY;
    if ( $date == $dateMark ) {
        return "Palm Sunday";
    }

    return undef;
}

=head2 _determineEasterWeek

Private method used to return the names of various days within Easter Week.  Takes the Time::Piece date given at construction and the Time::Piece date for Easter.  Returns undef if the date given at construction is not found in Easter Week.

=cut

sub _determineEasterWeek {
    my $date   = shift;
    my $easter = shift;

    my $dateMark = $easter + ONE_DAY;
    if ( $date == $dateMark ) {
        return "Monday of Easter Week";
    }

    $dateMark = $dateMark + ONE_DAY;
    if ( $date == $dateMark ) {
        return "Tuesday of Easter Week";
    }

    $dateMark = $dateMark + ONE_DAY;
    if ( $date == $dateMark ) {
        return "Wednesday of Easter Week";
    }

    $dateMark = $dateMark + ONE_DAY;
    if ( $date == $dateMark ) {
        return "Thursday of Easter Week";
    }

    $dateMark = $dateMark + ONE_DAY;
    if ( $date == $dateMark ) {
        return "Friday of Easter Week";
    }

    $dateMark = $dateMark + ONE_DAY;
    if ( $date == $dateMark ) {
        return "Saturday of Easter Week";
    }

    return undef;
}

=head2 _hasChristmas2

Private method to determine if there is a second Sunday of Christmas in the current liturgical year.  Returns 1 when there is a second Sunday of Christmas and 0 otherwise.

=cut

sub _hasChristmas2 {
    my $advent   = shift;
    my $epiphany = shift;

    my $firstChristmas = nextSunday( $advent->fourthSunday );
    my $dateMarker     = nextSunday($firstChristmas);

    if ( $dateMarker < $epiphany ) {
        return 1;
    }
    else {
        return 0;
    }

    return 0;
}

=head2 _determineChristmasEpiphany

Private method that matches the date given at construction against the Sundays in Christmastide and Epiphany.  Returns a string representation of the name of the Sunday in the lectionary.

=cut

sub _determineChristmasEpiphany {
    my $date = shift;

    my $advent = shift;

    my $ashWednesday = shift;

    my $lectionary = shift;

    my $epiphany = Time::Piece->strptime( $date->year . "-01-06", "%Y-%m-%d" );

    my $christmas2 = _hasChristmas2( $advent, $epiphany );

    #Is the date in Christmastide?
    my $dateMarker = nextSunday( $advent->fourthSunday );
    if ( $date == $dateMarker ) {
        return "The First Sunday of Christmas";
    }

    $dateMarker = nextSunday($dateMarker);
    if ( $date == $dateMarker && $christmas2 == 1 ) {
        return "The Second Sunday of Christmas";
    }
    elsif ( $date == $dateMarker ) {
        return "The First Sunday of Epiphany";
    }

    my @epiphanySundays = ( "The First Sunday of Epiphany", "The Second Sunday of Epiphany", "The Third Sunday of Epiphany", "The Fourth Sunday of Epiphany", "The Fifth Sunday of Epiphany", "The Sixth Sunday of Epiphany", "The Seventh Sunday of Epiphany", "The Last Sunday after Epiphany" );

    #Is the date in Epiphany?
    my $sunCount = 0;
    foreach my $sunday (@epiphanySundays) {
        $dateMarker = nextSunday($dateMarker);
        if ( $date == $dateMarker && $date == prevSunday($ashWednesday) ) {
            return "The Last Sunday after Epiphany";
        }
        if ( $date == $dateMarker && $date == prevSunday( prevSunday($ashWednesday) ) && $lectionary eq 'acna' ) {
            return "The Second to Last Sunday after Epiphany";
        }

        if ( $date == $dateMarker && $christmas2 == 1 ) {
            return $epiphanySundays[$sunCount];
        }
        elsif ( $date == $dateMarker && $christmas2 == 0 ) {
            return $epiphanySundays[ $sunCount + 1 ];
        }

        $sunCount++;
    }

    confess "There are no further Sundays of Christmastide or Epiphany.";
}

=head2 _determineLent

Private method that matches the date given at construction against the Sundays in Lent.  Returns a string representation of the name of the Sunday in the lectionary.

=cut

sub _determineLent {
    my $date         = shift;
    my $ashWednesday = shift;

    my $dateMarker = nextSunday($ashWednesday);
    if ( $date == $dateMarker ) {
        return "The First Sunday in Lent";
    }

    $dateMarker = nextSunday($dateMarker);
    if ( $date == $dateMarker ) {
        return "The Second Sunday in Lent";
    }

    $dateMarker = nextSunday($dateMarker);
    if ( $date == $dateMarker ) {
        return "The Third Sunday in Lent";
    }

    $dateMarker = nextSunday($dateMarker);
    if ( $date == $dateMarker ) {
        return "The Fourth Sunday in Lent";
    }

    $dateMarker = nextSunday($dateMarker);
    if ( $date == $dateMarker ) {
        return "The Fifth Sunday in Lent";
    }

    confess "There are no further Sundays in Lent";
}

=head2 _determineEasterSeason

Private method that matches the date given at construction against the Sundays in the Easter season.  Returns a string representation of the name of the Sunday in the lectionary.

=cut

sub _determineEasterSeason {
    my $date   = shift;
    my $easter = shift;

    my $dateMarker = nextSunday($easter);
    if ( $date == $dateMarker ) {
        return "The Second Sunday of Easter";
    }

    $dateMarker = nextSunday($dateMarker);
    if ( $date == $dateMarker ) {
        return "The Third Sunday of Easter";
    }

    $dateMarker = nextSunday($dateMarker);
    if ( $date == $dateMarker ) {
        return "The Fourth Sunday of Easter";
    }

    $dateMarker = nextSunday($dateMarker);
    if ( $date == $dateMarker ) {
        return "The Fifth Sunday of Easter";
    }

    $dateMarker = nextSunday($dateMarker);
    if ( $date == $dateMarker ) {
        return "The Sixth Sunday of Easter";
    }

    $dateMarker = nextSunday($dateMarker);
    if ( $date == $dateMarker ) {
        return "The Sunday after Ascension Day";
    }

    confess "There are no further Sundays of Easter for [" . $date->ymd . "].";
}

=head2 _determineOrdinary

Private method that matches the date given at construction against the Sundays in Ordinary time, e.g. Trinity Sunday and following Sundays.  Returns a string representation of the name of the Sunday in the lectionary.

=cut

sub _determineOrdinary {
    my $date      = shift;
    my $pentecost = shift;

    my $trinitySunday = nextSunday($pentecost);
    if ( $date == $trinitySunday ) {
        return "Trinity Sunday";
    }

    my $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-05-25", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 8";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-06-01", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 9";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-06-08", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 10";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-06-15", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 11";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-06-22", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 12";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-06-29", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 13";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-07-06", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 14";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-07-13", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 15";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-07-20", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 16";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-07-27", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 17";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-08-03", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 18";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-08-10", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 19";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-08-17", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 20";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-08-24", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 21";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-08-31", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 22";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-09-07", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 23";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-09-14", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 24";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-09-21", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 25";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-09-28", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 26";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-10-05", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 27";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-10-12", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 28";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-10-19", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 29";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-10-26", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 30";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-11-02", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 31";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-11-09", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 32";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-11-16", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Ordinary 33";
    }

    $dateMarker = closestSunday( Time::Piece->strptime( $pentecost->year . "-11-23", "%Y-%m-%d" ) );
    if ( $date == $dateMarker ) {
        return "Christ the King";
    }

    confess "There are no further Sundays of Ordinary Time.";
}

=head2 _determineDay

Private method that takes the Time::Piece data given at construction and, using other private methods, determines the name of the Feast Day or Sunday in the lectionary.  If the date given at construction is a fixed feast, that day will be returned.  If the date given is a special feast -- e.g. Easter, Ash Wednesday, etc. -- or a Sunday the name of that day will be returned.  If the date isn't a special feast or a Sunday the date represented as a string will be returned as the name with no associated readings.

=cut

sub _determineDay {
    my $date          = shift;
    my $lectionary    = shift;
    my $includeFeasts = shift;

    my $advent = shift;
    my $easter = shift;

    #Is the date in Advent?
    if ( $date == $advent->firstSunday ) {
        return ( commonName => "The First Sunday in Advent", type => 'Sunday' );
    }
    elsif ( $date == $advent->secondSunday ) {
        return (
            commonName => "The Second Sunday in Advent",
            type       => 'Sunday'
        );
    }
    elsif ( $date == $advent->thirdSunday ) {
        return ( commonName => "The Third Sunday in Advent", type => 'Sunday' );
    }
    elsif ( $date == $advent->fourthSunday ) {
        return (
            commonName => "The Fourth Sunday in Advent",
            type       => 'Sunday'
        );
    }

    #Is the date Easter Sunday?
    if ( $date == $easter ) {
        return ( commonName => "Easter Day", type => 'fixedFeast' );
    }

    #Determine when Ash Wednesday is
    my $ashWednesday = _determineAshWednesday($easter);
    if ( $date == $ashWednesday ) {
        return ( commonName => "Ash Wednesday", type => 'fixedFeast' );
    }

    #Holy Week
    my $holyWeekDay = _determineHolyWeek( $date, $easter );
    if ($holyWeekDay) {
        return ( commonName => $holyWeekDay, type => 'fixedFeast' );
    }

    #Easter Week
    my $easterWeekDay = _determineEasterWeek( $date, $easter );
    if ($easterWeekDay) {
        return ( commonName => $easterWeekDay, type => 'fixedFeast' );
    }

    #Ascension is 40 days after Easter
    my $ascension = _determineAscension($easter);
    if ( $date == $ascension ) {
        return ( commonName => "Ascension Day", type => 'fixedFeast' );
    }

    #Pentecost is 50 days after Easter
    my $pentecost = _determinePentecost($easter);
    if ( $date == $pentecost ) {
        return ( commonName => "Pentecost", type => 'fixedFeast' );
    }

    #Feast Day Celebrations
    if ( $includeFeasts eq 'yes' ) {
        my %feastDay = _determineFeasts( $date, $lectionary );
        if ( $feastDay{commonName} ) {
            return ( commonName => $feastDay{commonName}, type => $feastDay{type} );
        }
    }

    #If the date isn't a Sunday and we've determined it is not a fixed holiday
    #then there are no readings for that day.
    if ( $date->wday != 1 ) {
        return (
            commonName => $date->fullday . ', ' . $date->fullmonth . ' ' . $date->mday . ', ' . $date->year,
            type       => 'noLect'
        );
    }

    #Sundays of the Liturgical Year
    if ( $date < $ashWednesday ) {
        return (
            commonName => _determineChristmasEpiphany( $date, $advent, $ashWednesday, $lectionary ),
            type       => 'Sunday'
        );
    }

    if ( $date < $easter ) {
        return (
            commonName => _determineLent( $date, $ashWednesday ),
            type       => 'Sunday'
        );
    }

    if ( $date > $easter && $date < $pentecost ) {
        return (
            commonName => _determineEasterSeason( $date, $easter ),
            type       => 'Sunday'
        );
    }

    if ( $date > $pentecost ) {
        return (
            commonName => _determineOrdinary( $date, $pentecost ),
            type       => 'Sunday'
        );
    }
}

=head1 AUTHOR

Michael Wayne Arnold, C<< <michael at rnold.info> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-date-lectionary at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Lectionary-Day>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Lectionary::Day


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Lectionary-Day>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Lectionary-Day>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Lectionary-Day>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Lectionary-Day/>

=back

=head1 ACKNOWLEDGEMENTS

Many thanks to my beautiful wife, Jennifer, my amazing daughter, Rosemary, and my sweet son, Oliver.  But, above all, SOLI DEO GLORIA!

=head1 LICENSE

Copyright 2016-2018 MICHAEL WAYNE ARNOLD

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__->meta->make_immutable;

1;    # End of Date::Lectionary::Day
