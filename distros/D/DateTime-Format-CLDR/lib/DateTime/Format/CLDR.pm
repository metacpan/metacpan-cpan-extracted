# ============================================================================
package DateTime::Format::CLDR;
# ============================================================================
use strict;
use warnings;
use utf8;

use DateTime;
use DateTime::Locale 0.4000;
use DateTime::TimeZone;
use Params::Validate qw( validate_pos validate SCALAR BOOLEAN OBJECT CODEREF );
use Exporter;
use Carp qw(croak carp);

# Export functions
use base qw(Exporter);
our @EXPORT_OK = qw( cldr_format cldr_parse );

# CPAN data
our $AUTHORITY = 'cpan:MAROS';
our $VERSION = '1.19';

# Default format if none is set
our $DEFAULT_FORMAT = 'date_format_medium';

# Simple regexp blocks
our %PARTS = (
    year_long   => qr/(-?\d{1,4})/o,
    year_short  => qr/(-?\d{2})/o,
    day_week    => qr/([1-7])/o,
    day_month   => qr/(3[01]|[12]\d|0?[1-9])/o,
    day_year    => qr/([1-3]\d\d|0?[1-9]\d|(?:00)?[1-9])/o,
    month       => qr/(1[0-2]|0?[1-9])/o,
    hour_23     => qr/(00|2[0-4]|1\d|0?\d)/o,
    hour_24     => qr/(2[0-4]|1\d|0?[1-9])/o,
    hour_12     => qr/(1[0-2]|0?[1-9])/o,
    hour_11     => qr/(00|1[01]|0?\d)/o,
    minute      => qr/([0-5]?\d)/o,
    second      => qr/(6[01]|[0-5]?\d)/o,
    quarter     => qr/([1-4])/o,
    week_year   => qr/(5[0-3]|[1-4]\d|0?[1-9])/o,
    week_month  => qr/(\d)/o,
    #timezone    => qr/[+-](1[0-4]|0?\d)(00|15|30|45)/o,
    number      => qr/(\d+)/o,
    timezone2   => qr/([+-]?[A-Z0-9a-z]+)([+-](?:1[0-4]|0\d)(?:00|15|30|45))/o,
);

# Table for mapping abbreviated timezone names to offsets
our %ZONEMAP = (
     'A' => '+0100',       'ACDT' => '+1030',       'ACST' => '+0930',
   'ADT' => 'Ambiguous',   'AEDT' => '+1100',        'AES' => '+1000',
  'AEST' => '+1000',        'AFT' => '+0430',       'AHDT' => '-0900',
  'AHST' => '-1000',       'AKDT' => '-0800',       'AKST' => '-0900',
  'AMST' => '+0400',        'AMT' => '+0400',      'ANAST' => '+1300',
  'ANAT' => '+1200',        'ART' => '-0300',        'AST' => 'Ambiguous',
    'AT' => '-0100',       'AWST' => '+0800',      'AZOST' => '+0000',
  'AZOT' => '-0100',       'AZST' => '+0500',        'AZT' => '+0400',
     'B' => '+0200',       'BADT' => '+0400',        'BAT' => '+0600',
  'BDST' => '+0200',        'BDT' => '+0600',        'BET' => '-1100',
   'BNT' => '+0800',       'BORT' => '+0800',        'BOT' => '-0400',
   'BRA' => '-0300',        'BST' => 'Ambiguous',     'BT' => 'Ambiguous',
   'BTT' => '+0600',          'C' => '+0300',       'CAST' => '+0930',
   'CAT' => 'Ambiguous',    'CCT' => 'Ambiguous',    'CDT' => 'Ambiguous',
  'CEST' => '+0200',        'CET' => '+0100',     'CETDST' => '+0200',
 'CHADT' => '+1345',      'CHAST' => '+1245',        'CKT' => '-1000',
  'CLST' => '-0300',        'CLT' => '-0400',        'COT' => '-0500',
   'CST' => 'Ambiguous',   'CSuT' => '+1030',        'CUT' => '+0000',
   'CVT' => '-0100',        'CXT' => '+0700',       'ChST' => '+1000',
     'D' => '+0400',       'DAVT' => '+0700',       'DDUT' => '+1000',
   'DNT' => '+0100',        'DST' => '+0200',          'E' => '+0500',
 'EASST' => '-0500',       'EAST' => 'Ambiguous',    'EAT' => '+0300',
   'ECT' => 'Ambiguous',    'EDT' => 'Ambiguous',   'EEST' => '+0300',
   'EET' => '+0200',     'EETDST' => '+0300',       'EGST' => '+0000',
   'EGT' => '-0100',        'EMT' => '+0100',        'EST' => 'Ambiguous',
  'ESuT' => '+1100',          'F' => '+0600',        'FDT' => 'Ambiguous',
  'FJST' => '+1300',        'FJT' => '+1200',       'FKST' => '-0300',
   'FKT' => '-0400',        'FST' => 'Ambiguous',    'FWT' => '+0100',
     'G' => '+0700',       'GALT' => '-0600',       'GAMT' => '-0900',
  'GEST' => '+0500',        'GET' => '+0400',        'GFT' => '-0300',
  'GILT' => '+1200',        'GMT' => '+0000',        'GST' => 'Ambiguous',
    'GT' => '+0000',        'GYT' => '-0400',         'GZ' => '+0000',
     'H' => '+0800',        'HAA' => '-0300',        'HAC' => '-0500',
   'HAE' => '-0400',        'HAP' => '-0700',        'HAR' => '-0600',
   'HAT' => '-0230',        'HAY' => '-0800',        'HDT' => '-0930',
   'HFE' => '+0200',        'HFH' => '+0100',         'HG' => '+0000',
   'HKT' => '+0800',         'HL' => 'local',        'HNA' => '-0400',
   'HNC' => '-0600',        'HNE' => '-0500',        'HNP' => '-0800',
   'HNR' => '-0700',        'HNT' => '-0330',        'HNY' => '-0900',
   'HOE' => '+0100',        'HST' => '-1000',          'I' => '+0900',
   'ICT' => '+0700',       'IDLE' => '+1200',       'IDLW' => '-1200',
   'IDT' => 'Ambiguous',    'IOT' => '+0500',       'IRDT' => '+0430',
 'IRKST' => '+0900',       'IRKT' => '+0800',       'IRST' => '+0430',
   'IRT' => '+0330',        'IST' => 'Ambiguous',     'IT' => '+0330',
   'ITA' => '+0100',       'JAVT' => '+0700',       'JAYT' => '+0900',
   'JST' => '+0900',         'JT' => '+0700',          'K' => '+1000',
   'KDT' => '+1000',       'KGST' => '+0600',        'KGT' => '+0500',
  'KOST' => '+1200',      'KRAST' => '+0800',       'KRAT' => '+0700',
   'KST' => '+0900',          'L' => '+1100',       'LHDT' => '+1100',
  'LHST' => '+1030',       'LIGT' => '+1000',       'LINT' => '+1400',
   'LKT' => '+0600',        'LST' => 'local',         'LT' => 'local',
     'M' => '+1200',      'MAGST' => '+1200',       'MAGT' => '+1100',
   'MAL' => '+0800',       'MART' => '-0930',        'MAT' => '+0300',
  'MAWT' => '+0600',        'MDT' => '-0600',        'MED' => '+0200',
 'MEDST' => '+0200',       'MEST' => '+0200',       'MESZ' => '+0200',
   'MET' => 'Ambiguous',   'MEWT' => '+0100',        'MEX' => '-0600',
   'MEZ' => '+0100',        'MHT' => '+1200',        'MMT' => '+0630',
   'MPT' => '+1000',        'MSD' => '+0400',        'MSK' => '+0300',
  'MSKS' => '+0400',        'MST' => '-0700',         'MT' => '+0830',
   'MUT' => '+0400',        'MVT' => '+0500',        'MYT' => '+0800',
     'N' => '-0100',        'NCT' => '+1100',        'NDT' => '-0230',
   'NFT' => 'Ambiguous',    'NOR' => '+0100',      'NOVST' => '+0700',
  'NOVT' => '+0600',        'NPT' => '+0545',        'NRT' => '+1200',
   'NST' => 'Ambiguous',   'NSUT' => '+0630',         'NT' => '-1100',
   'NUT' => '-1100',       'NZDT' => '+1300',       'NZST' => '+1200',
   'NZT' => '+1200',          'O' => '-0200',       'OESZ' => '+0300',
   'OEZ' => '+0200',      'OMSST' => '+0700',       'OMST' => '+0600',
    'OZ' => 'local',          'P' => '-0300',        'PDT' => '-0700',
   'PET' => '-0500',      'PETST' => '+1300',       'PETT' => '+1200',
   'PGT' => '+1000',       'PHOT' => '+1300',        'PHT' => '+0800',
   'PKT' => '+0500',       'PMDT' => '-0200',        'PMT' => '-0300',
   'PNT' => '-0830',       'PONT' => '+1100',        'PST' => 'Ambiguous',
   'PWT' => '+0900',       'PYST' => '-0300',        'PYT' => '-0400',
     'Q' => '-0400',          'R' => '-0500',        'R1T' => '+0200',
   'R2T' => '+0300',        'RET' => '+0400',        'ROK' => '+0900',
     'S' => '-0600',       'SADT' => '+1030',       'SAST' => 'Ambiguous',
   'SBT' => '+1100',        'SCT' => '+0400',        'SET' => '+0100',
   'SGT' => '+0800',        'SRT' => '-0300',        'SST' => 'Ambiguous',
   'SWT' => '+0100',          'T' => '-0700',        'TFT' => '+0500',
   'THA' => '+0700',       'THAT' => '-1000',        'TJT' => '+0500',
   'TKT' => '-1000',        'TMT' => '+0500',        'TOT' => '+1300',
  'TRUT' => '+1000',        'TST' => '+0300',        'TUC' => '+0000',
   'TVT' => '+1200',          'U' => '-0800',      'ULAST' => '+0900',
  'ULAT' => '+0800',       'USZ1' => '+0200',      'USZ1S' => '+0300',
  'USZ3' => '+0400',      'USZ3S' => '+0500',       'USZ4' => '+0500',
 'USZ4S' => '+0600',       'USZ5' => '+0600',      'USZ5S' => '+0700',
  'USZ6' => '+0700',      'USZ6S' => '+0800',       'USZ7' => '+0800',
 'USZ7S' => '+0900',       'USZ8' => '+0900',      'USZ8S' => '+1000',
  'USZ9' => '+1000',      'USZ9S' => '+1100',        'UTZ' => '-0300',
   'UYT' => '-0300',       'UZ10' => '+1100',      'UZ10S' => '+1200',
  'UZ11' => '+1200',      'UZ11S' => '+1300',       'UZ12' => '+1200',
 'UZ12S' => '+1300',        'UZT' => '+0500',          'V' => '-0900',
   'VET' => '-0400',      'VLAST' => '+1100',       'VLAT' => '+1000',
   'VTZ' => '-0200',        'VUT' => '+1100',          'W' => '-1000',
  'WAKT' => '+1200',       'WAST' => 'Ambiguous',    'WAT' => '+0100',
  'WEST' => '+0100',       'WESZ' => '+0100',        'WET' => '+0000',
'WETDST' => '+0100',        'WEZ' => '+0000',        'WFT' => '+1200',
  'WGST' => '-0200',        'WGT' => '-0300',        'WIB' => '+0700',
   'WIT' => '+0900',       'WITA' => '+0800',        'WST' => 'Ambiguous',
   'WTZ' => '-0100',        'WUT' => '+0100',          'X' => '-1100',
     'Y' => '-1200',      'YAKST' => '+1000',       'YAKT' => '+0900',
  'YAPT' => '+1000',        'YDT' => '-0800',      'YEKST' => '+0600',
  'YEKT' => '+0500',        'YST' => '-0900',          'Z' => '+0000',
);

# Map of CLDR commands to values
# Value might be
# - Regular expression: usually taken from %PART
# - String: DateTime::Locale method names. Method must retun lists of valid values
# - Arrayref: List of valid values

our %PARSER = (
    G1      => 'era_abbreviated',
    G4      => 'era_wide',
    G5      => 'era_narrow',
    y1      => $PARTS{year_long},
    y2      => $PARTS{year_short},
    y3      => qr/(-?\d{3,4})/o,
    y4      => qr/(-?\d{4})/o,
    y5      => qr/(-?\d{5})/o,
    Y1      => $PARTS{year_long},
    u1      => $PARTS{year_long},
    Q1      => $PARTS{quarter},
    Q3      => 'quarter_format_abbreviated',
    Q4      => 'quarter_format_wide',
    q1      => $PARTS{quarter},
    q3      => 'quarter_stand_alone_abbreviated',
    q4      => 'quarter_stand_alone_wide',
    M1      => $PARTS{month},
    M3      => 'month_format_abbreviated',
    M4      => 'month_format_wide',
    M5      => 'month_format_narrow',
    L1      => $PARTS{month},
    L3      => 'month_stand_alone_abbreviated',
    L4      => 'month_stand_alone_wide',
    L5      => 'month_stand_alone_narrow',
    w1      => $PARTS{week_year},
    W1      => $PARTS{week_month},
    d1      => $PARTS{day_month},
    D1      => $PARTS{day_year},
    F1      => $PARTS{week_month},
    E1      => 'day_format_abbreviated',
    E4      => 'day_format_wide',
    E5      => 'day_format_narrow',
    e1      => $PARTS{day_week},
    e3      => 'day_format_abbreviated',
    e4      => 'day_format_wide',
    e5      => 'day_format_narrow',
    c1      => $PARTS{day_week},
    c3      => 'day_stand_alone_abbreviated',
    c4      => 'day_stand_alone_wide',
    c5      => 'day_stand_alone_narrow',
    a1      => 'am_pm_abbreviated',
    h1      => $PARTS{hour_12},
    H1      => $PARTS{hour_23},
    K1      => $PARTS{hour_11},
    k1      => $PARTS{hour_24},
   #j1      => Handled dyamically,
    m1      => $PARTS{minute},
    s1      => $PARTS{second},
    S1      => $PARTS{number}, #!
    Z1      => [ grep { $_ ne 'Ambiguous' } values %ZONEMAP ],
    Z4      => $PARTS{timezone2},
    Z5      => qr/([+-]\d\d:\d\d)/o,
    z1      => [ qr/[+-][0-9]{2,4}/, keys %ZONEMAP ],
    z4      => [ DateTime::TimeZone->all_names ],
);
$PARSER{v1} = $PARSER{V1} = $PARSER{z1};
$PARSER{v4} = $PARSER{V4} = $PARSER{z4};


=encoding utf8

=head1 NAME

DateTime::Format::CLDR - Parse and format CLDR time patterns

=head1 SYNOPSIS

    use DateTime::Format::CLDR;

    # 1. Basic example
    my $cldr1 = DateTime::Format::CLDR->new(
        pattern     => 'HH:mm:ss',
        locale      => 'de_AT',
        time_zone   => 'Europe/Vienna',
    );

    my $dt1 = $cldr1->parse_datetime('23:16:42');

    print $cldr1->format_datetime($dt1);
    # 23:16:42

    # 2. Get pattern from selected locale
    # pattern is taken from 'date_format_medium' in DateTime::Locale::de_AT
    my $cldr2 = DateTime::Format::CLDR->new(
        locale      => 'de_AT',
    );

    print $cldr2->parse_datetime('23.11.2007');
    # 2007-11-23T00:00:00

    # 3. Croak when things go wrong
    my $cldr3 = DateTime::Format::CLDR->new(
        locale      => 'de_AT',
        on_error    => 'croak',
    );

    $cldr3->parse_datetime('23.33.2007');
    # Croaks

    # 4. Use DateTime::Locale
    my $locale = DateTime::Locale->load('en_GB');
    my $cldr4 = DateTime::Format::CLDR->new(
        pattern     => $locale->datetime_format_medium,
        locale      => $locale,
    );

    print $cldr4->parse_datetime('22 Dec 1995 09:05:02');
    # 1995-12-22T09:05:02

=head1 DESCRIPTION

This module provides a parser (and also a formater) for datetime strings
using patterns as defined by the Unicode CLDR Project
(Common Locale Data Repository). L<http://unicode.org/cldr/>.

CLDR format is supported by L<DateTime> and L<DateTime::Locale> starting with
version 0.40.

=head1 METHODS

=head2 Constructor

=head3 new

 DateTime::Format::CLDR->new(%PARAMS);

The following parameters are used by DateTime::Format::CLDR:

=over

=item * locale

Locale.

See L<locale> accessor.

=item * pattern (optional)

CLDR pattern. If you don't provide a pattern the C<date_format_medium>
pattern from L<DateTime::Local> for the selected locale will be used.

See L<pattern> accessor.

=item * time_zone (optional)

Timezone that should be used by default. If your pattern contains
timezone information this attribute will be ignored.

See L<time_zone> accessor.

=item * on_error (optional)

Set the error behaviour.

See L<on_error> accessor.

=item * incomplete (optional)

Set the behaviour how to handle incomplete date information.

See L<incomplete> accessor.

=back

=cut

sub new { ## no perlcritic(RequireArgUnpacking)
    my $class = shift;
    my %args = validate( @_, {
        locale          => { type => SCALAR | OBJECT, default => 'en' },
        pattern         => { type => SCALAR, optional => 1  },
        time_zone       => { type => SCALAR | OBJECT, optional => 1 },
        on_error        => { type => SCALAR | CODEREF, optional => 1, default => 'undef' },
        incomplete      => { type => SCALAR | CODEREF, optional => 1, default => 1 },
        }
    );

    my $self = bless \%args, $class;

    # Set default values
    $args{time_zone} ||= DateTime::TimeZone->new( name => 'floating' );

    # Pass on to accessors
    $self->time_zone($args{time_zone});
    $self->locale($args{locale});

    # Set default values
    unless (defined $args{pattern}) {
        if ($self->locale->can($DEFAULT_FORMAT)) {
            $args{pattern} = $self->locale->$DEFAULT_FORMAT;
        } else {
            croak("Method '$DEFAULT_FORMAT' not available in ".ref($self->loclale));
        }
    }

    $self->pattern($args{pattern});
    $self->on_error($args{on_error});
    $self->incomplete($args{incomplete});
    $self->{errmsg} = undef;

    return $self;
}

=head2 Accessors

=head3 pattern

Get/set CLDR pattern. See L<"CLDR PATTERNS"> or L<DateTime/"CLDR Patterns">
for details about patterns.

 $cldr->pattern('d MMM y HH:mm:ss');

It is possible to retrieve patterns from L<DateTime::Locale>

 $dl = DateTime::Locale->load('es_AR');
 $cldr->pattern($dl->datetime_format_full);

=cut

sub pattern {
    my ($self,$pattern) = @_;

    # Set pattern
    if (defined $pattern) {
        $self->{pattern} = $pattern;
        undef $self->{_built_pattern};
    }

    return $self->{pattern};
}

=head3 time_zone

Get/set time_zone. Returns a C<DateTime::TimeZone> object.

Accepts either a timezone name or a C<DateTime::TimeZone> object.

 $cldr->time_zone('America/Argentina/Mendoza');
 OR
 my $tz = DateTime::TimeZone->new(name => 'America/Argentina/Mendoza');
 $cldr->time_zone($tz);

=cut

sub time_zone {
    my ($self,$time_zone) = @_;

    # Set timezone
    if (defined $time_zone) {
        if (ref $time_zone
            && $time_zone->isa('DateTime::TimeZone')) {
            $self->{time_zone} = $time_zone;
        } else {
            $self->{time_zone} = DateTime::TimeZone->new( name => $time_zone )
                or croak("Could not create timezone from $time_zone");
        }
    }

    return $self->{time_zone};
}

=head3 locale

Get/set a locale. Returns a C<DateTime::Locale> object.

Accepts either a locale name or a C<DateTime::Locale::*> object.

 $cldr->locale('fr_CA');
 OR
 $dl = DateTime::Locale->load('fr_CA');
 $cldr->locale($dl);

=cut

sub locale {
    my ($self,$locale) = @_;

    # Set locale
    if (defined $locale) {
        unless (ref $locale
            && ($locale->isa('DateTime::Locale::Base') || $locale->isa('DateTime::Locale::FromData'))) {
            $self->{locale} = DateTime::Locale->load( $locale )
                or croak("Could not create locale from $locale");
        } else {
            $self->{locale} = $locale;
        }
        undef $self->{_built_pattern};
    }

    return $self->{locale};
}

=head3 on_error

Get/set the error behaviour.

Accepts the following values

=over

=item * 'undef' (Literal) (default)

Returns undef on error and sets L<errmsg>

=item * 'croak'

Croak on error

=item * CODEREF

Run the given coderef on error.

=back

=cut

sub on_error {
    my ($self,$on_error) = @_;

    # Set locale
    if (defined $on_error) {
        croak("The value supplied to on_error must be either 'croak', 'undef' or a code reference.")
            unless ref($on_error) eq 'CODE'
                or $on_error eq 'croak'
                or $on_error eq 'undef';
        return $self->{on_error};
    }
    return $self->{on_error};
}

=head3 incomplete

Set the behaviour how to handle incomplete Date information.

Accepts the following values

=over

=item * '1' (default)

Sets the missing values to '1'. Thus if you only parse a time sting you would
get '0001-01-01' as the date.

=item * 'incomplete'

Create a L<DateTime::Incomplete> object instead.

=item * CODEREF

Run the given coderef on incomplete values. The code reference will be
called with the C<DateTime::Format::CLDR> object and a hash of parsed values
as supplied to C<DateTime-E<gt>new>. It should return a modified hash which
will be passed to C<DateTime-E<gt>new>.

=back

=cut

sub incomplete {
    my ($self,$incomplete) = @_;

    # Set locale
    if (defined $incomplete) {
        croak("The value supplied to incomplete must be either 'incomplete', '1' or a code reference.")
            unless ref($incomplete) eq 'CODE'
                or $incomplete eq '1'
                or $incomplete eq 'incomplete';
        return $self->{incomplete};
    }
    return $self->{incomplete};
}

=head2 Public Methods

=head3 parse_datetime

 my $datetime = $cldr->parse_datetime($string);

Parses a string and returns a C<DateTime> object on success (If you provide
incomplete data and set the L<incomplete> attribute accordingly it will
return a C<DateTime::Incomplete> object). If the string cannot be parsed
an error will be thrown (depending on the C<on_error> attribute).

=cut

sub parse_datetime { ## no perlcritic(RequireArgUnpacking)
    my ( $self, $string ) = validate_pos( @_, 1, { type => SCALAR  } );

    my $pattern = $self->_build_pattern();

    my $datetime_initial = $string;
    my %datetime_info = ();
    my %datetime_check = ();
    my $datetime_error = sub {
        my $occurence = shift;
        my $error = $datetime_initial;
        substr($error,(length($occurence) * -1),0," HERE-->");
        return $self->_local_croak("Could not get datetime for $datetime_initial (Error marked by 'HERE-->'): '$error'");
    };

    # Set default datetime values
    my %datetime = (
        hour        => 0,
        minute      => 0,
        second      => 0,
        time_zone   => $self->{time_zone},
        locale      => $self->{locale},
        nanosecond  => 0,
    );

    PART: foreach my $part (@{$pattern}) {

        #my $before = $string;

        # Pattern
        if (ref $part eq 'ARRAY') {
            my ($regexp,$command,$index) = @{$part};

            #print "TRY TO MATCH '$string' AGAINST '$regexp' WITH $command\n";

            # Match regexp part
            return $datetime_error->($string)
                unless ($string =~ s/^ \s* $regexp//ix);

            # Get capture
            my $capture = $1;

            # Pattern is a list: get index instead of value
            if (ref $PARSER{$command.$index} eq '') {
                my $function = $PARSER{$command.$index};
                my $count = 1;
                my $tmpcapture;
                foreach my $element (@{$self->{locale}->$function}) {
                    if (lc($element) eq lc($capture)) {
                        if (defined $tmpcapture) {
                            $self->_local_carp("Expression '$capture' is ambigous for pattern '$command$index' ");
                            next PART;
                        }
                        $tmpcapture = $count;
                    }
                    $count ++;
                }
                $capture = $tmpcapture;
            }

            # Run patterns
            if ($command eq 'G' ) {
                $datetime_info{era} = $capture;
            } elsif ($command eq 'y' && $index == 2) {
                $datetime{year} = $capture;
                if ($datetime{year} >= 70) {
                    $datetime{year} += 1900;
                } else {
                    $datetime{year} += 2000;
                }
            } elsif ($command eq 'y' ) {
                $datetime{year} = $capture;
            } elsif ($command eq 'Q' || $command eq 'q') {
                $datetime_check{quarter} = $capture;
            } elsif ($command eq 'M' || $command eq 'L') {
                $datetime{month} = $capture;
            } elsif ($command eq 'w') {
                $datetime_check{week_number} = $capture;
            } elsif ($command eq 'W') {
                $datetime_check{week_of_month} = $capture;
            } elsif ($command eq 'd') {
                $datetime{day} = $capture;
            } elsif ($command eq 'D') {
                $datetime_check{day_of_year} = $capture;
            } elsif ($command eq 'e'  && $index == 1) {
                my $fdow = $self->{locale}->first_day_of_week();
                $capture -= (8 - $fdow);
                $capture += 7 if $capture < 1;
                $datetime_check{day_of_week} = $capture;
            } elsif ($command eq 'E' || $command eq 'c' || $command eq 'e') {
                $datetime_check{day_of_week} = $capture;
            } elsif ($command eq 'F') {
                $datetime_check{weekday_of_month} = $capture;
            } elsif ($command eq 'a' ) {
                $datetime_info{ampm} = $capture;
            } elsif ($command eq 'h') { # 1-12
                $capture = 0 if $capture == 12;
                $datetime_info{hour12} = $capture;
            } elsif ($command eq 'K') { # 0-11
                $datetime_info{hour12} = $capture;
            } elsif ($command eq 'H') { # 0-23
                $datetime{hour} = $capture;
            } elsif ($command eq 'k') { # 1-24
                $datetime_info{hour24} = $capture;
            } elsif ($command eq 'm') {
                $datetime{minute} = $capture;
            } elsif ($command eq 's') {
                $datetime{second} = $capture;
            } elsif ($command eq 'S' ) {
                $datetime{nanosecond} = int("0.$capture" * 1000000000);
            } elsif ($command eq 'Z') {
                if ($index == 4) {
                    $capture = $2;
                }
                $datetime{time_zone} = DateTime::TimeZone->new( name => $capture );
            } elsif (($command eq 'z' || $command eq 'v' || $command eq 'V') && $index == 1) {
                if ($capture =~ m/^[+-]\d\d(\d\d)?/) {
                    $capture .= '00'
                        if ! defined $1;
                    $datetime{time_zone} = DateTime::TimeZone->new(name => $capture);
                } elsif (! defined $ZONEMAP{$capture}
                    || $ZONEMAP{$capture} eq 'Ambiguous') {
                    $self->_local_carp("Ambiguous timezone: $capture $command");
                } else {
                    $datetime{time_zone} = DateTime::TimeZone->new(name => $ZONEMAP{$capture});
                }
            } elsif ($command eq 'z' || $command eq 'v' || $command eq 'V') {
                $datetime{time_zone} = DateTime::TimeZone->new(name => $capture);
            } else {
                return $self->_local_croak("Could not get datetime for '$datetime_initial': Unknown pattern $command$index");
            }

        # String
        } elsif ($string !~ s/^ \s* $part//ix) {
            return $datetime_error->($string);
        }
        #print "BEFORE: '$before' AFTER: '$string' PATTERN: '$part'\n";
    }

    return $datetime_error->($string)
        if $string ne '';

    # Handle 12 hour time notations
    if (defined $datetime_info{hour12}
        && defined $datetime_info{ampm}) {
        $datetime{hour} = $datetime_info{hour12};
        $datetime{hour} += 12
            if $datetime_info{ampm} == 2 && $datetime{hour} < 12;
    }
    if (defined $datetime_info{hour24}) {
        $datetime{hour} = $datetime_info{hour24};
        if ($datetime{hour} == 24) {
            $datetime{hour} = 0;
        }
    }

    # Handle 24:00:00 time notations
    if ($datetime{hour} == 24) {
        if ($datetime{minute} == 0
            && $datetime{second} == 0
            && $datetime{nanosecond} == 0) {
            $datetime{hour} = 0;
            $datetime_info{dayadd} = 1;
        } else {
            return $self->_local_croak("Could not get datetime for $datetime_initial: Invalid 24-hour notation")
        }
    }

    # Handle era
    if (defined $datetime_info{era}
        && $datetime_info{era} == 0
        && defined $datetime{year}) {
        $datetime{year} *= -1;
    }

    # Handle incomplete datetime information
    unless (defined $datetime{year}
        && defined $datetime{month}
        && defined $datetime{day}) {

        # I want given/when in 5.8
        if (ref $self->{incomplete} eq 'CODE') {
            %datetime = &{$self->{incomplete}}($self,%datetime);
        } elsif ($self->{incomplete} eq '1') {
            $datetime{day} ||= 1;
            $datetime{month} ||= 1;
            $datetime{year} ||= 1;
        } elsif ($self->{incomplete} eq 'incomplete') {
            require DateTime::Incomplete;
            my $dt = eval {
                return DateTime::Incomplete->new(%datetime);
            };
            return $self->_local_croak("Could not get datetime for $datetime_initial: $@")
                if $@ || ref $dt ne 'DateTime::Incomplete';
            return $dt;
        } else {
            return $self->_local_croak("Could not get datetime for $datetime_initial: Invalid incomplete setting");
        }
    }

    # Build datetime
    my $dt = eval {
        return DateTime->new(%datetime);
    };
    return $self->_local_croak("Could not get datetime for $datetime_initial: $@")
        if $@ || ref $dt ne 'DateTime';

    # Postprocessing
    if ($datetime_info{dayadd}) {
        $dt->add( days => 1 );
    }

    # Perform checks
    foreach my $check ( keys %datetime_check ) {
        unless ($dt->$check == $datetime_check{$check}) {
            return $self->_local_croak("Datetime '$check' does not match ('$datetime_check{$check}' vs. '".$dt->$check."') for '$datetime_initial'");
        }
    }

    return $dt;
}

=head3 format_datetime

 my $string = $cldr->format_datetime($datetime);

Formats a C<DateTime> object using the set locale and pattern. (not the
time_zone)

=cut

sub format_datetime {
    my ( $self, $dt ) = @_;

    $dt = DateTime->now
        unless defined $dt && ref $dt && $dt->isa('DateTime');

    #see http://rt.cpan.org/Public/Bug/Display.html?id=49605
    #my ( $self, $dt ) = validate_pos( @_, 1, { default => DateTime->now, type => OBJECT } );
    $dt = $dt->clone;
    $dt->set_locale($self->{locale});

    return $dt->format_cldr($self->{pattern});
}


=head3 errmsg

 my $string = $cldr->errmsg();

Stores the last error message. Especially useful if the on_error behavior of the
object is 'undef', so you can work out why things went wrong.

=cut

sub errmsg {
    return $_[0]->{errmsg};
}


=head2 Exportable functions

There are no methods exported by default, however the following are available:

=head3 cldr_format

 use DateTime::Format::CLDR qw(cldr_format);
 &cldr_format($pattern,$datetime);

=cut

sub cldr_format {
    my ($pattern, $datetime) = @_;

    return $datetime->format_cldr($pattern);
}

=head3 cldr_parse

 use DateTime::Format::CLDR qw(cldr_parse);
 &cldr_parse($pattern,$string);
 OR
 &cldr_parse($pattern,$string,$locale);

Default locale is 'en'.

=cut

sub cldr_parse {
    my ($pattern, $string, $locale) = @_;

    $locale ||= 'en';
    return DateTime::Format::CLDR->new(
        pattern => $pattern,
        locale  => $locale,
        on_error=>'croak',
    )->parse_datetime($string);
}


# ---------------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------------

# Parse the pattern and return a data sctructure that can be easily used
# by parse_datetime

sub _build_pattern {
    my ($self) = @_;

    # Return cached pattern
    return $self->{_built_pattern}
        if defined $self->{_built_pattern};

    $self->{_built_pattern} = [];

    # Try to parse pattern one element each time
    while ($self->{pattern} =~ m/\G
        (?:
            '((?:[^']|'')*)' # quote escaped bit of text
                           # it needs to end with one
                           # quote not followed by
                           # another
            |
            (([a-zA-Z])\3*)  # could be a pattern
            |
            (.)              # anything else
        )
        /sxg) {
        my ($string,$pattern,$rest) = ($1,$2,$4);


        # Found quoted string
        if ($string) {
            $string =~ s/\'\'/\'/g;
            push @{$self->{_built_pattern}}, _quotestring($string);

        # Found pattern
        } elsif ($pattern) {
            # Get length and command
            my $length = length $pattern;
            my $command = substr $pattern,0,1;
            my ($rule,$regexp,$index);

            # Inflate 'j' pattern depending on locale
            if ($command eq 'j') {
                $command = ($self->{locale}->prefers_24_hour_time()) ? 'H':'h';
            }

            # Find most appropriate command
            for (my $count = $length; $count > 0; $count --) {
                if (defined $PARSER{$command.$count}) {
                    $rule = $PARSER{$command.$count};
                    $index = $count;
                    last;
                }
            }

            return $self->_local_croak("Broken pattern: $command $length")
                unless $rule;

            # Pattern definition is regular expression
            if (ref $rule eq 'Regexp') {
                #$regexp =  '0*'.$rule; # Match leading zeros
                $regexp =  $rule;

            # Pattern definition is array of possible values
            } elsif (ref $rule eq 'ARRAY') {

                $regexp = _quoteslist($rule);
                # Try to find matching element (long elements first)

            # Pattern definition is DateTime::Locale method (returning an array)
            } else {
                $regexp = _quoteslist($self->{locale}->$rule());
            }

            push @{$self->{_built_pattern}},[$regexp,$command,$index];

        # Found unqoted string
        } elsif ($rest) {
            push @{$self->{_built_pattern}}, _quotestring($rest);
        }
    }

    #use Data::Dumper;
    #print STDERR Data::Dumper::Dumper($self->{_built_pattern})."\n";

    return $self->{_built_pattern};
}

# Turn array into regexp

sub _quoteslist {
    my ($list) = @_;

    return
        '('.
        (join
            '|',
            map { _quotestring($_) }
            sort { length $b <=> length $a } @{$list}
        ).
        ')';
}

# Quote regexp

sub _quotestring {
    my ($quote) = @_;
    return $quote
        if ref($quote) eq 'Regexp';

    $quote =~ s/([^[:alnum:][:space:]])/\\$1/g;
    $quote =~ s/\s+/\\s+/g;
    return $quote;
}

# Error

sub _local_croak {
    my ($self,$message) = @_;

    $self->{errmsg} = $message;

    return &{$self->{on_error}}($self,$message,@_)
        if ref($self->{on_error}) eq 'CODE';

    croak($message)
        if $self->{on_error} eq 'croak';

    return undef
        if ($self->{on_error} eq 'undef');

    return;
}

# Warning

sub _local_carp {
    my ($self,$message) = @_;

    $self->{errmsg} = $message;

    return &{$self->{on_error}}($self,$message,@_)
        if ref($self->{on_error}) eq 'CODE';

    carp($message)
        if $self->{on_error} eq 'croak';

    return undef
        if ($self->{on_error} eq 'undef');

    return;
}




1;

=head1 CLDR PATTERNS

=head2 Parsing

Some patterns like day of week, quarter, ect. cannot be used to construct
a date. However these patterns can be parsed, and a warning will be
issued if they do not match the parsed date.

Ambigous patterns (eg. narrow day of week formats for many locales) will
be parsed but ignored in datetime calculation.

=head2 Supported CLDR Patterns

See L<DateTime/"CLDR Patterns">.

CLDR provides the following patterns:

=over 4

=item * G{1,3}

The abbreviated era (BC, AD).

=item * GGGG

The wide era (Before Christ, Anno Domini).

=item * GGGGG

The narrow era, if it exists (and it mostly doesn't).

Not used to construct a date.

=item * y and y{3,}

The year, zero-prefixed as needed.

=item * yy

This is a special case. It always produces a two-digit year, so "1976"
becomes "76".

=item * Y{1,}

The week of the year, from C<< $dt->week_year() >>.

=item * u{1,}

Same as "y" except that "uu" is not a special case.

=item * Q{1,2}

The quarter as a number (1..4).

Not used to construct a date.

=item * QQQ

The abbreviated format form for the quarter.

Not used to construct a date.

=item * QQQQ

The wide format form for the quarter.

Not used to construct a date.

=item * q{1,2}

The quarter as a number (1..4).

Not used to construct a date.

=item * qqq

The abbreviated stand-alone form for the quarter.

Not used to construct a date.

=item * qqqq

The wide stand-alone form for the quarter.

Not used to construct a date.

=item * M{1,2}

The numerical month.

=item * MMM

The abbreviated format form for the month.

=item * MMMM

The wide format form for the month.

=item * MMMMM

The narrow format form for the month.

=item * L{1,2}

The numerical month.

=item * LLL

The abbreviated stand-alone form for the month.

=item * LLLL

The wide stand-alone form for the month.

=item * LLLLL

The narrow stand-alone form for the month.

=item * w{1,2}

The week of the year, from C<< $dt->week_number() >>.

Not used to construct a date.

=item * W

The week of the month, from C<< $dt->week_of_month() >>.

Not used to construct a date.

=item * d{1,2}

The numeric day of of the month.

=item * D{1,3}

The numeric day of of the year.

Not used to construct a date.

=item * F

The day of the week in the month, from C<< $dt->weekday_of_month() >>.

Not used to construct a date.

=item * g{1,}

The modified Julian day, from C<< $dt->mjd() >>.

Not supported by DateTime::Format::CLDR

=item * E{1,3}

The abbreviated format form for the day of the week.

Not used to construct a date.

=item * EEEE

The wide format form for the day of the week.

Not used to construct a date.

=item * EEEEE

The narrow format form for the day of the week.

Not used to construct a date.

=item * e{1,2}

The I<local> day of the week, from 1 to 7. This number depends on what
day is considered the first day of the week, which varies by
locale. For example, in the US, Sunday is the first day of the week,
so this returns 2 for Monday.

Not used to construct a date.

=item * eee

The abbreviated format form for the day of the week.

Not used to construct a date.

=item * eeee

The wide format form for the day of the week.

Not used to construct a date.

=item * eeeee

The narrow format form for the day of the week.

Not used to construct a date.

=item * c

The numeric day of the week (not localized).

Not used to construct a date.

=item * ccc

The abbreviated stand-alone form for the day of the week.

Not used to construct a date.

=item * cccc

The wide stand-alone form for the day of the week.

Not used to construct a date.

=item * ccccc

The narrow format form for the day of the week.

Not used to construct a date.

=item * a

The localized form of AM or PM for the time.

=item * h{1,2}

The hour from 1-12.

=item * H{1,2}

The hour from 0-23.

=item * K{1,2}

The hour from 0-11.

=item * k{1,2}

The hour from 1-24. Note that hour 24 is equivalent to midnight on the date
being parsed, not midnight of the next day.

=item * j{1,2}

The hour, in 12 or 24 hour form, based on the preferred form for the
locale. In other words, this is equivalent to either "h{1,2}" or
"H{1,2}".

=item * m{1,2}

The minute.

=item * s{1,2}

The second.

=item * S{1,}

The fractional portion of the seconds, rounded based on the length of the
specifier. This returned without a leading decimal point, but may have
leading or trailing zeroes.

=item * A{1,}

The millisecond of the day, based on the current time. In other words, if it
is 12:00:00.00, this returns 43200000.

Not supported by DateTime::Format::CLDR

=item * z{1,3}

The time zone short name.

=item * zzzz

The time zone long name.

=item * Z{1,3}

The time zone offset.

=item * ZZZZ

The time zone short name and the offset as one string, so something like
"CDT-0500".

=item * v{1,3}

The time zone short name.

=item * vvvv

The time zone long name.

=item * V{1,3}

The time zone short name.

=item * VVVV

The time zone long name.

=back

=head1 CAVEATS

Patterns without separators (like 'dMy' or 'yMd') are ambigous for some
dates and might fail.

Quote from the Author of C<DateTime::Format::Strptime> which also applies to
this module:

 "If your module uses this module to parse a known format: stop it. This module
 is clunky and slow because it can parse almost anything. Parsing a known
 format is not so difficult, is it? You'll make your module faster if you do.
 And you're not left at the whim of my potentially broken code."

=head1 SUPPORT

Please report any bugs or feature requests to
C<datetime-format-cldr@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=DateTime::Format::CLDR>.
I will be notified and then you'll automatically be notified of the progress
on your report as I make changes.

=head1 SEE ALSO

datetime@perl.org mailing list

L<http://datetime.perl.org/>

L<DateTime>, L<DateTime::Locale>, L<DateTime::TimeZone>
and L<DateTime::Format::Strptime>

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com

    http://www.k-1.com

=head1 COPYRIGHT

DateTime::Format::CLDR is Copyright (c) 2008-2012 Maroš Kollár
- L<http://www.k-1.com>

=head1 LICENCE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
