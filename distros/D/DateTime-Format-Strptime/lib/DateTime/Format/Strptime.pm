package DateTime::Format::Strptime;

use strict;
use warnings;

our $VERSION = '1.79';

use Carp qw( carp croak );
use DateTime 1.00;
use DateTime::Locale 1.30;
use DateTime::Format::Strptime::Types;
use DateTime::TimeZone 2.09;
use Exporter ();
use Params::ValidationCompiler qw( validation_for );
use Try::Tiny;

our @EXPORT_OK = qw( strftime strptime );

## no critic (ValuesAndExpressions::ProhibitConstantPragma)
use constant PERL_58 => $] < 5.010;

# We previously used Package::DeprecationManager which allowed passing of
# "-api_version => X" on import. We don't want any such imports to blow up but
# we no longer have anything to deprecate.
sub import {
    my $class = shift;
    my @args;
    ## no critic (ControlStructures::ProhibitCStyleForLoops)
    for ( my $i = 0; $i < @_; $i++ ) {
        if ( $_[$i] eq '-api_version' ) {
            $i++;
        }
        else {
            push @args, $_[$i];
        }
    }
    @_ = ( $class, @args );
    goto &Exporter::import;
}

{
    my $en_locale = DateTime::Locale->load('en');

    my $validator = validation_for(
        params => {
            pattern   => { type => t('NonEmptyStr') },
            time_zone => {
                type     => t('TimeZone'),
                optional => 1,
            },
            zone_map => {
                type    => t('HashRef'),
                default => sub { {} },
            },
            locale => {
                type    => t('Locale'),
                default => sub {$en_locale},
            },
            on_error => {
                type    => t('OnError'),
                default => 'undef',
            },
            strict => {
                type    => t('Bool'),
                default => 0,
            },
            debug => {
                type    => t('Bool'),
                default => $ENV{DATETIME_FORMAT_STRPTIME_DEBUG},
            },
        },
    );

    sub new {
        my $class = shift;
        my %args  = $validator->(@_);

        my $self = bless {
            %args,
            zone_map => $class->_build_zone_map( $args{zone_map} ),
        }, $class;

        # Forces a check that the pattern is valid
        $self->_parser;

        if ( $self->{debug} ) {
            binmode STDERR, ':encoding(UTF-8)' or die $!;
        }

        return $self;
    }
}

{
    my %zone_map = (
        'A'      => '+0100', 'ACDT'   => '+1030', 'ACST'   => '+0930',
        'ADT'    => undef,   'AEDT'   => '+1100', 'AES'    => '+1000',
        'AEST'   => '+1000', 'AFT'    => '+0430', 'AHDT'   => '-0900',
        'AHST'   => '-1000', 'AKDT'   => '-0800', 'AKST'   => '-0900',
        'AMST'   => '+0400', 'AMT'    => '+0400', 'ANAST'  => '+1300',
        'ANAT'   => '+1200', 'ART'    => '-0300', 'AST'    => undef,
        'AT'     => '-0100', 'AWST'   => '+0800', 'AZOST'  => '+0000',
        'AZOT'   => '-0100', 'AZST'   => '+0500', 'AZT'    => '+0400',
        'B'      => '+0200', 'BADT'   => '+0400', 'BAT'    => '+0600',
        'BDST'   => '+0200', 'BDT'    => '+0600', 'BET'    => '-1100',
        'BNT'    => '+0800', 'BORT'   => '+0800', 'BOT'    => '-0400',
        'BRA'    => '-0300', 'BST'    => undef,   'BT'     => undef,
        'BTT'    => '+0600', 'C'      => '+0300', 'CAST'   => '+0930',
        'CAT'    => undef,   'CCT'    => undef,   'CDT'    => undef,
        'CEST'   => '+0200', 'CET'    => '+0100', 'CETDST' => '+0200',
        'CHADT'  => '+1345', 'CHAST'  => '+1245', 'CKT'    => '-1000',
        'CLST'   => '-0300', 'CLT'    => '-0400', 'COT'    => '-0500',
        'CST'    => undef,   'CSuT'   => '+1030', 'CUT'    => '+0000',
        'CVT'    => '-0100', 'CXT'    => '+0700', 'ChST'   => '+1000',
        'D'      => '+0400', 'DAVT'   => '+0700', 'DDUT'   => '+1000',
        'DNT'    => '+0100', 'DST'    => '+0200', 'E'      => '+0500',
        'EASST'  => '-0500', 'EAST'   => undef,   'EAT'    => '+0300',
        'ECT'    => undef,   'EDT'    => undef,   'EEST'   => '+0300',
        'EET'    => '+0200', 'EETDST' => '+0300', 'EGST'   => '+0000',
        'EGT'    => '-0100', 'EMT'    => '+0100', 'EST'    => undef,
        'ESuT'   => '+1100', 'F'      => '+0600', 'FDT'    => undef,
        'FJST'   => '+1300', 'FJT'    => '+1200', 'FKST'   => '-0300',
        'FKT'    => '-0400', 'FST'    => undef,   'FWT'    => '+0100',
        'G'      => '+0700', 'GALT'   => '-0600', 'GAMT'   => '-0900',
        'GEST'   => '+0500', 'GET'    => '+0400', 'GFT'    => '-0300',
        'GILT'   => '+1200', 'GMT'    => '+0000', 'GST'    => undef,
        'GT'     => '+0000', 'GYT'    => '-0400', 'GZ'     => '+0000',
        'H'      => '+0800', 'HAA'    => '-0300', 'HAC'    => '-0500',
        'HAE'    => '-0400', 'HAP'    => '-0700', 'HAR'    => '-0600',
        'HAT'    => '-0230', 'HAY'    => '-0800', 'HDT'    => '-0930',
        'HFE'    => '+0200', 'HFH'    => '+0100', 'HG'     => '+0000',
        'HKT'    => '+0800', 'HL'     => 'local', 'HNA'    => '-0400',
        'HNC'    => '-0600', 'HNE'    => '-0500', 'HNP'    => '-0800',
        'HNR'    => '-0700', 'HNT'    => '-0330', 'HNY'    => '-0900',
        'HOE'    => '+0100', 'HST'    => '-1000', 'I'      => '+0900',
        'ICT'    => '+0700', 'IDLE'   => '+1200', 'IDLW'   => '-1200',
        'IDT'    => undef,   'IOT'    => '+0500', 'IRDT'   => '+0430',
        'IRKST'  => '+0900', 'IRKT'   => '+0800', 'IRST'   => '+0430',
        'IRT'    => '+0330', 'IST'    => undef,   'IT'     => '+0330',
        'ITA'    => '+0100', 'JAVT'   => '+0700', 'JAYT'   => '+0900',
        'JST'    => '+0900', 'JT'     => '+0700', 'K'      => '+1000',
        'KDT'    => '+1000', 'KGST'   => '+0600', 'KGT'    => '+0500',
        'KOST'   => '+1200', 'KRAST'  => '+0800', 'KRAT'   => '+0700',
        'KST'    => '+0900', 'L'      => '+1100', 'LHDT'   => '+1100',
        'LHST'   => '+1030', 'LIGT'   => '+1000', 'LINT'   => '+1400',
        'LKT'    => '+0600', 'LST'    => 'local', 'LT'     => 'local',
        'M'      => '+1200', 'MAGST'  => '+1200', 'MAGT'   => '+1100',
        'MAL'    => '+0800', 'MART'   => '-0930', 'MAT'    => '+0300',
        'MAWT'   => '+0600', 'MDT'    => '-0600', 'MED'    => '+0200',
        'MEDST'  => '+0200', 'MEST'   => '+0200', 'MESZ'   => '+0200',
        'MET'    => undef,   'MEWT'   => '+0100', 'MEX'    => '-0600',
        'MEZ'    => '+0100', 'MHT'    => '+1200', 'MMT'    => '+0630',
        'MPT'    => '+1000', 'MSD'    => '+0400', 'MSK'    => '+0300',
        'MSKS'   => '+0400', 'MST'    => '-0700', 'MT'     => '+0830',
        'MUT'    => '+0400', 'MVT'    => '+0500', 'MYT'    => '+0800',
        'N'      => '-0100', 'NCT'    => '+1100', 'NDT'    => '-0230',
        'NFT'    => undef,   'NOR'    => '+0100', 'NOVST'  => '+0700',
        'NOVT'   => '+0600', 'NPT'    => '+0545', 'NRT'    => '+1200',
        'NST'    => undef,   'NSUT'   => '+0630', 'NT'     => '-1100',
        'NUT'    => '-1100', 'NZDT'   => '+1300', 'NZST'   => '+1200',
        'NZT'    => '+1200', 'O'      => '-0200', 'OESZ'   => '+0300',
        'OEZ'    => '+0200', 'OMSST'  => '+0700', 'OMST'   => '+0600',
        'OZ'     => 'local', 'P'      => '-0300', 'PDT'    => '-0700',
        'PET'    => '-0500', 'PETST'  => '+1300', 'PETT'   => '+1200',
        'PGT'    => '+1000', 'PHOT'   => '+1300', 'PHT'    => '+0800',
        'PKT'    => '+0500', 'PMDT'   => '-0200', 'PMT'    => '-0300',
        'PNT'    => '-0830', 'PONT'   => '+1100', 'PST'    => undef,
        'PWT'    => '+0900', 'PYST'   => '-0300', 'PYT'    => '-0400',
        'Q'      => '-0400', 'R'      => '-0500', 'R1T'    => '+0200',
        'R2T'    => '+0300', 'RET'    => '+0400', 'ROK'    => '+0900',
        'S'      => '-0600', 'SADT'   => '+1030', 'SAST'   => undef,
        'SBT'    => '+1100', 'SCT'    => '+0400', 'SET'    => '+0100',
        'SGT'    => '+0800', 'SRT'    => '-0300', 'SST'    => undef,
        'SWT'    => '+0100', 'T'      => '-0700', 'TFT'    => '+0500',
        'THA'    => '+0700', 'THAT'   => '-1000', 'TJT'    => '+0500',
        'TKT'    => '-1000', 'TMT'    => '+0500', 'TOT'    => '+1300',
        'TRUT'   => '+1000', 'TST'    => '+0300', 'TUC '   => '+0000',
        'TVT'    => '+1200', 'U'      => '-0800', 'ULAST'  => '+0900',
        'ULAT'   => '+0800', 'USZ1'   => '+0200', 'USZ1S'  => '+0300',
        'USZ3'   => '+0400', 'USZ3S'  => '+0500', 'USZ4'   => '+0500',
        'USZ4S'  => '+0600', 'USZ5'   => '+0600', 'USZ5S'  => '+0700',
        'USZ6'   => '+0700', 'USZ6S'  => '+0800', 'USZ7'   => '+0800',
        'USZ7S'  => '+0900', 'USZ8'   => '+0900', 'USZ8S'  => '+1000',
        'USZ9'   => '+1000', 'USZ9S'  => '+1100', 'UTZ'    => '-0300',
        'UYT'    => '-0300', 'UZ10'   => '+1100', 'UZ10S'  => '+1200',
        'UZ11'   => '+1200', 'UZ11S'  => '+1300', 'UZ12'   => '+1200',
        'UZ12S'  => '+1300', 'UZT'    => '+0500', 'V'      => '-0900',
        'VET'    => '-0400', 'VLAST'  => '+1100', 'VLAT'   => '+1000',
        'VTZ'    => '-0200', 'VUT'    => '+1100', 'W'      => '-1000',
        'WAKT'   => '+1200', 'WAST'   => undef,   'WAT'    => '+0100',
        'WEST'   => '+0100', 'WESZ'   => '+0100', 'WET'    => '+0000',
        'WETDST' => '+0100', 'WEZ'    => '+0000', 'WFT'    => '+1200',
        'WGST'   => '-0200', 'WGT'    => '-0300', 'WIB'    => '+0700',
        'WIT'    => '+0900', 'WITA'   => '+0800', 'WST'    => undef,
        'WTZ'    => '-0100', 'WUT'    => '+0100', 'X'      => '-1100',
        'Y'      => '-1200', 'YAKST'  => '+1000', 'YAKT'   => '+0900',
        'YAPT'   => '+1000', 'YDT'    => '-0800', 'YEKST'  => '+0600',
        'YEKT'   => '+0500', 'YST'    => '-0900', 'Z'      => '+0000',
        'UTC'    => '+0000',
    );

    for my $i ( map { sprintf( '%02d', $_ ) } 1 .. 12 ) {
        $zone_map{ '-' . $i } = '-' . $i . '00';
        $zone_map{ '+' . $i } = '+' . $i . '00';
    }

    sub _build_zone_map {
        return {
            %zone_map,
            %{ $_[1] },
        };
    }
}

sub parse_datetime {
    my $self   = shift;
    my $string = shift;

    my $parser = $self->_parser;
    if ( $self->{debug} ) {
        warn "Regex for $self->{pattern}: $parser->{regex}\n";
        warn "Fields: @{$parser->{fields}}\n";
    }

    my @matches = ( $string =~ $parser->{regex} );
    unless (@matches) {
        my $msg = 'Your datetime does not match your pattern';
        if ( $self->{debug} ) {
            $msg .= qq{ - string = "$string" - regex = $parser->{regex}};
        }
        $msg .= q{.};
        $self->_our_croak($msg);
        return;
    }

    my %args;
    my $i = 0;
    for my $f ( @{ $parser->{fields} } ) {
        unless ( defined $matches[$i] ) {
            die
                "Something horrible happened - the string matched $parser->{regex}"
                . " but did not return the expected fields: [@{$parser->{fields}}]";
        }
        $args{$f} = $matches[ $i++ ];
    }

    # We need to copy the %args here because _munge_args will delete keys in
    # order to turn this into something that can be passed to a DateTime
    # constructor.
    my ( $constructor, $args, $post_construct )
        = $self->_munge_args( {%args} );
    return unless $constructor && $args;

    my $dt = try { DateTime->$constructor($args) };
    $self->_our_croak('Parsed values did not produce a valid date')
        unless $dt;
    if ($post_construct) {
        $post_construct->($dt);
    }
    return unless $dt && $self->_check_dt( $dt, \%args );

    $dt->set_time_zone( $self->{time_zone} )
        if $self->{time_zone};

    return $dt;
}

sub _parser {
    my $self = shift;

    return $self->{parser} ||= $self->_build_parser;
}

sub _build_parser {
    my $self = shift;

    my (
        $replacement_tokens_re,
        $replacements,
        $pattern_tokens_re,
        $patterns,
    ) = $self->_parser_pieces;

    my $pattern = $self->{pattern};

    # When the first replacement is a glibc pattern, the first round of
    # replacements may simply replace one replacement token (like %X) with
    # another replacement token (like %I).
    $pattern =~ s/%($replacement_tokens_re)/$replacements->{$1}/g for 1 .. 2;

    if ( $self->{debug} && $pattern ne $self->{pattern} ) {
        warn "Pattern after replacement substitution: $pattern\n";
    }

    my $regex = q{};
    my @fields;

    while (
        $pattern =~ /
            \G
            %($pattern_tokens_re)
            |
            %([1-9]?)(N)
            |
            (%[0-9]*[a-zA-Z])
            |
            ([^%]+)
                    /xg
    ) {
        # Using \G in the regex match fails for some reason on Perl 5.8, so we
        # do this hack instead.
        substr( $pattern, 0, pos $pattern, q{} )
            if PERL_58;
        if ($1) {
            my $p = $patterns->{$1}
                or croak
                "Unidentified token in pattern: $1 in $self->{pattern}";
            if ( $p->{field} ) {
                $regex .= qr/($p->{regex})/;
                push @fields, $p->{field};
            }
            else {
                $regex .= qr/$p->{regex}/;
            }
        }
        elsif ($3) {
            $regex .= $2 ? qr/([0-9]{$2})/ : qr/([0-9]+)/;
            push @fields, 'nanosecond';
        }
        elsif ($4) {
            croak qq{Pattern contained an unrecognized strptime token, "$4"};
        }
        else {
            $regex .= qr/\Q$5/;
        }
    }

    return {
        regex =>
            ( $self->{strict} ? qr/(?:\A|\b)$regex(?:\b|\Z)/ : qr/$regex/ ),
        fields => \@fields,
    };
}

{
    my $digit             = qr/(?:[0-9])/;
    my $one_or_two_digits = qr/[0-9 ]?$digit/;

    # These patterns are all locale-independent. There are a few that depend
    # on the locale, and must be re-calculated for each new parser object.
    my %universal_patterns = (
        '%' => {
            regex => qr/%/,
        },
        C => {
            regex => $one_or_two_digits,
            field => 'century',
        },
        d => {
            regex => $one_or_two_digits,
            field => 'day',
        },
        g => {
            regex => $one_or_two_digits,
            field => 'iso_week_year_100',
        },
        G => {
            regex => qr/$digit{4}/,
            field => 'iso_week_year',
        },
        H => {
            regex => $one_or_two_digits,
            field => 'hour',
        },
        I => {
            regex => $one_or_two_digits,
            field => 'hour_12',
        },
        j => {
            regex => qr/$digit{1,3}/,
            field => 'day_of_year',
        },
        m => {
            regex => $one_or_two_digits,
            field => 'month',
        },
        M => {
            regex => $one_or_two_digits,
            field => 'minute',
        },
        n => {
            regex => qr/\s+/,
        },
        O => {
            regex => qr{[a-zA-Z_]+(?:/[a-zA-Z_]+(?:/[a-zA-Z_]+)?)?},
            field => 'time_zone_name',
        },
        s => {
            regex => qr/$digit+/,
            field => 'epoch',
        },
        S => {
            regex => $one_or_two_digits,
            field => 'second',
        },
        U => {
            regex => $one_or_two_digits,
            field => 'week_sun_0',
        },
        u => {
            regex => $one_or_two_digits,
            field => 'day_of_week',
        },
        w => {
            regex => $one_or_two_digits,
            field => 'day_of_week_sun_0',
        },
        W => {
            regex => $one_or_two_digits,
            field => 'week_mon_1',
        },
        y => {
            regex => $one_or_two_digits,
            field => 'year_100',
        },
        Y => {
            regex => qr/$digit{4}/,
            field => 'year',
        },
        z => {
            regex => qr/(?:Z|[+-]$digit{2}(?:[:]?$digit{2})?)/,
            field => 'time_zone_offset',
        },
        Z => {
            regex => qr/[a-zA-Z]{1,6}|[\-\+]$digit{2}/,
            field => 'time_zone_abbreviation',
        },
    );

    $universal_patterns{e} = $universal_patterns{d};
    $universal_patterns{k} = $universal_patterns{H};
    $universal_patterns{l} = $universal_patterns{I};
    $universal_patterns{t} = $universal_patterns{n};

    my %universal_replacements = (
        D => '%m/%d/%y',
        F => '%Y-%m-%d',
        r => '%I:%M:%S %p',
        R => '%H:%M',
        T => '%H:%M:%S',
    );

    sub _parser_pieces {
        my $self = shift;

        my %replacements = %universal_replacements;
        $replacements{c} = $self->{locale}->glibc_datetime_format;
        $replacements{x} = $self->{locale}->glibc_date_format;
        $replacements{X} = $self->{locale}->glibc_time_format;

        my %patterns = %universal_patterns;
        $patterns{a} = $patterns{A} = {
            regex => do {
                my $days = join '|', map {quotemeta}
                    sort { ( length $b <=> length $a ) or ( $a cmp $b ) }
                    keys %{ $self->_locale_days };
                qr/$days/i;
            },
            field => 'day_name',
        };

        $patterns{b} = $patterns{B} = $patterns{h} = {
            regex => do {
                my $months = join '|', map {quotemeta}
                    sort { ( length $b <=> length $a ) or ( $a cmp $b ) }
                    keys %{ $self->_locale_months };
                qr/$months/i;
            },
            field => 'month_name',
        };

        $patterns{p} = $patterns{P} = {
            regex => do {
                my $am_pm = join '|',
                    map  {quotemeta}
                    sort { ( length $b <=> length $a ) or ( $a cmp $b ) }
                    @{ $self->{locale}->am_pm_abbreviated };
                qr/$am_pm/i;
            },
            field => 'am_pm',
        };

        return (
            $self->_token_re_for( keys %replacements ),
            \%replacements,
            $self->_token_re_for( keys %patterns ),
            \%patterns,
        );
    }
}

sub _locale_days {
    my $self = shift;

    return $self->{locale_days} if $self->{locale_days};

    my $wide = $self->{locale}->day_format_wide;
    my $abbr = $self->{locale}->day_format_abbreviated;

    my %locale_days;
    for my $i ( 0 .. 6 ) {
        $locale_days{ lc $wide->[$i] } = $i;
        $locale_days{ lc $abbr->[$i] } = $i;
    }

    return $self->{locale_days} ||= \%locale_days;
}

sub _locale_months {
    my $self = shift;

    return $self->{locale_months} if $self->{locale_months};

    my $wide = $self->{locale}->month_format_wide;
    my $abbr = $self->{locale}->month_format_abbreviated;

    my %locale_months;
    for my $i ( 0 .. 11 ) {
        $locale_months{ lc $wide->[$i] } = $i + 1;
        $locale_months{ lc $abbr->[$i] } = $i + 1;
    }

    return $self->{locale_months} ||= \%locale_months;
}

sub _token_re_for {
    shift;
    my $t = join '|',
        sort { ( length $b <=> length $a ) or ( $a cmp $b ) } @_;

    return qr/$t/;
}

{
    # These are fields we parse that cannot be passed to a DateTime
    # constructor
    my @non_dt_keys = qw(
        am_pm
        century
        day_name
        day_of_week
        day_of_week_sun_0
        hour_12
        iso_week_year
        iso_week_year_100
        month_name
        time_zone_abbreviation
        time_zone_name
        time_zone_offset
        week_mon_1
        week_sun_0
        year_100
    );

    ## no critic (Subroutines::ProhibitExcessComplexity)
    sub _munge_args {
        my $self = shift;
        my $args = shift;

        if ( defined $args->{month_name} ) {
            my $num = $self->_locale_months->{ lc $args->{month_name} }
                or die "We somehow parsed a month name ($args->{month_name})"
                . ' that does not correspond to any month in this locale!';

            $args->{month} = $num;
        }

        if ( defined $args->{am_pm} && defined $args->{hour_12} ) {
            my ( $am, $pm ) = @{ $self->{locale}->am_pm_abbreviated };
            $args->{hour} = $args->{hour_12};

            if ( lc $args->{am_pm} eq lc $am ) {
                $args->{hour} = 0 if $args->{hour} == 12;
            }
            else {
                $args->{hour} += 12 unless $args->{hour} == 12;
            }
        }
        elsif ( defined $args->{hour_12} ) {
            $self->_our_croak(
                      qq{Parsed a 12-hour based hour, "$args->{hour_12}",}
                    . ' but the pattern does not include an AM/PM specifier'
            );
            return;
        }

        if ( defined $args->{year_100} ) {
            if ( defined $args->{century} ) {
                $args->{year}
                    = $args->{year_100} + ( $args->{century} * 100 );
            }
            else {
                $args->{year} = $args->{year_100} + (
                    $args->{year_100} >= 69
                    ? 1900
                    : 2000
                );
            }
        }

        if ( $args->{time_zone_offset} ) {
            my $offset = $args->{time_zone_offset};

            if ( $offset eq 'Z' ) {
                $offset = '+0000';
            }
            elsif ( $offset =~ /^[+-][0-9]{2}$/ ) {
                $offset .= '00';
            }

            my $tz = try { DateTime::TimeZone->new( name => $offset ) };
            unless ($tz) {
                $self->_our_croak(
                    qq{The time zone name offset that was parsed does not appear to be valid, "$args->{time_zone_offset}"}
                );
                return;
            }

            $args->{time_zone} = $tz;
        }

        if ( defined $args->{time_zone_abbreviation} ) {
            my $abbr = $args->{time_zone_abbreviation};
            unless ( exists $self->{zone_map}{$abbr} ) {
                $self->_our_croak(
                    qq{Parsed an unrecognized time zone abbreviation, "$args->{time_zone_abbreviation}"}
                );
                return;
            }
            if ( !defined $self->{zone_map}{$abbr} ) {
                $self->_our_croak(
                    qq{The time zone abbreviation that was parsed is ambiguous, "$args->{time_zone_abbreviation}"}
                );
                return;
            }
            $args->{time_zone}
                = DateTime::TimeZone->new( name => $self->{zone_map}{$abbr} );
        }
        else {
            $args->{time_zone} ||= 'floating';
        }

        if ( $args->{time_zone_name} ) {
            my $name = $args->{time_zone_name};
            my $tz;
            unless ( $tz = try { DateTime::TimeZone->new( name => $name ) } )
            {
                $name = lc $name;
                $name =~ s{(^|[/_])(.)}{$1\U$2}g;
            }
            $tz = try { DateTime::TimeZone->new( name => $name ) };
            unless ($tz) {
                $self->_our_croak(
                    qq{The Olson time zone name that was parsed does not appear to be valid, "$args->{time_zone_name}"}
                );
                return;
            }
            $args->{time_zone} = $tz
                if $tz;
        }

        delete @{$args}{@non_dt_keys};
        $args->{locale} = $self->{locale};

        for my $k ( grep { defined $args->{$_} }
            qw( month day hour minute second nanosecond ) ) {
            $args->{$k} =~ s/^\s+//;
        }

        if ( defined $args->{nanosecond} ) {

            # If we parsed "12345" we treat it as "123450000" but if we parsed
            # "000123456" we treat it as 123,456 nanoseconds. This is all a bit
            # weird and confusing but it matches how this module has always
            # worked.
            $args->{nanosecond} *= 10**( 9 - length $args->{nanosecond} )
                if length $args->{nanosecond} != 9;

            # If we parsed 000000123 we want to turn this into a number.
            $args->{nanosecond} += 0;
        }

        for my $k (qw( year month day )) {
            $args->{$k} = 1 unless defined $args->{$k};
        }

        if ( defined $args->{epoch} ) {

            # We don't want to pass a non-integer epoch value since that gets
            # truncated as of DateTime 1.22. Instead, we'll set the nanosecond
            # to parsed value after constructing the object. This is a hack,
            # but it's the best I can come up with.
            my $post_construct;
            if ( my $nano = $args->{nanosecond} ) {
                $post_construct = sub { $_[0]->set( nanosecond => $nano ) };
            }

            delete @{$args}{
                qw( day_of_year year month day hour minute second nanosecond )
            };

            return ( 'from_epoch', $args, $post_construct );
        }
        elsif ( $args->{day_of_year} ) {
            delete @{$args}{qw( epoch month day )};
            return ( 'from_day_of_year', $args );
        }

        return ( 'new', $args );
    }
}

## no critic (Subroutines::ProhibitExcessComplexity)
sub _check_dt {
    my $self = shift;
    my $dt   = shift;
    my $args = shift;

    my $is_am = defined $args->{am_pm}
        && lc $args->{am_pm} eq lc $self->{locale}->am_pm_abbreviated->[0];
    if ( defined $args->{hour} && defined $args->{hour_12} ) {
        unless ( ( $args->{hour} % 12 ) == $args->{hour_12} ) {
            $self->_our_croak(
                'Parsed an input with 24-hour and 12-hour time values that do not match'
                    . qq{ - "$args->{hour}" versus "$args->{hour_12}"} );
            return;
        }
    }

    if ( defined $args->{hour} && defined $args->{am_pm} ) {
        if (   ( $is_am && $args->{hour} >= 12 )
            || ( !$is_am && $args->{hour} < 12 ) ) {
            $self->_our_croak(
                'Parsed an input with 24-hour and AM/PM values that do not match'
                    . qq{ - "$args->{hour}" versus "$args->{am_pm}"} );
            return;
        }
    }

    if ( defined $args->{year} && defined $args->{century} ) {
        unless ( int( $args->{year} / 100 ) == $args->{century} ) {
            $self->_our_croak(
                'Parsed an input with year and century values that do not match'
                    . qq{ - "$args->{year}" versus "$args->{century}"} );
            return;
        }
    }

    if ( defined $args->{year} && defined $args->{year_100} ) {
        unless ( ( $args->{year} % 100 ) == $args->{year_100} ) {
            $self->_our_croak(
                'Parsed an input with year and year-within-century values that do not match'
                    . qq{ - "$args->{year}" versus "$args->{year_100}"} );
            return;
        }
    }

    if (   defined $args->{time_zone_abbreviation}
        && defined $args->{time_zone_offset} ) {
        unless ( $self->{zone_map}{ $args->{time_zone_abbreviation} }
            && $self->{zone_map}{ $args->{time_zone_abbreviation} } eq
            $args->{time_zone_offset} ) {

            $self->_our_croak(
                'Parsed an input with time zone abbreviation and time zone offset values that do not match'
                    . qq{ - "$args->{time_zone_abbreviation}" versus "$args->{time_zone_offset}"}
            );
            return;
        }
    }

    if ( defined $args->{epoch} ) {
        for my $key (
            qw( year month day minute hour second hour_12 day_of_year )) {
            if ( defined $args->{$key} && $dt->$key != $args->{$key} ) {
                my $print_key
                    = $key eq 'hour_12'     ? 'hour (1-12)'
                    : $key eq 'day_of_year' ? 'day of year'
                    :                         $key;
                $self->_our_croak(
                    "Parsed an input with epoch and $print_key values that do not match"
                        . qq{ - "$args->{epoch}" versus "$args->{$key}"} );
                return;
            }
        }
    }

    if ( defined $args->{month} && defined $args->{day_of_year} ) {
        unless ( $dt->month == $args->{month} ) {
            $self->_our_croak(
                'Parsed an input with month and day of year values that do not match'
                    . qq{ - "$args->{month}" versus "$args->{day_of_year}"} );
            return;
        }
    }

    if ( defined $args->{day_name} ) {
        my $dow = $self->_locale_days->{ lc $args->{day_name} };
        defined $dow
            or die "We somehow parsed a day name ($args->{day_name})"
            . ' that does not correspond to any day in this locale!';

        unless ( $dt->day_of_week_0 == $dow ) {
            $self->_our_croak(
                'Parsed an input where the day name does not match the date'
                    . qq{ - "$args->{day_name}" versus "}
                    . $dt->ymd
                    . q{"} );
            return;
        }
    }

    if ( defined $args->{day_of_week} ) {
        unless ( $dt->day_of_week == $args->{day_of_week} ) {
            $self->_our_croak(
                'Parsed an input where the day of week does not match the date'
                    . qq{ - "$args->{day_of_week}" versus "}
                    . $dt->ymd
                    . q{"} );
            return;
        }
    }

    if ( defined $args->{day_of_week_sun_0} ) {
        unless ( ( $dt->day_of_week % 7 ) == $args->{day_of_week_sun_0} ) {
            $self->_our_croak(
                'Parsed an input where the day of week (Sunday as 0) does not match the date'
                    . qq{ - "$args->{day_of_week_sun_0}" versus "}
                    . $dt->ymd
                    . q{"} );
            return;
        }
    }

    if ( defined $args->{iso_week_year} ) {
        unless ( $dt->week_year == $args->{iso_week_year} ) {
            $self->_our_croak(
                'Parsed an input where the ISO week year does not match the date'
                    . qq{ - "$args->{iso_week_year}" versus "}
                    . $dt->ymd
                    . q{"} );
            return;
        }
    }

    if ( defined $args->{iso_week_year_100} ) {
        unless ( ( 0 + substr( $dt->week_year, -2 ) )
            == $args->{iso_week_year_100} ) {
            $self->_our_croak(
                'Parsed an input where the ISO week year (without century) does not match the date'
                    . qq{ - "$args->{iso_week_year_100}" versus "}
                    . $dt->ymd
                    . q{"} );
            return;
        }
    }

    if ( defined $args->{week_mon_1} ) {
        unless ( ( 0 + $dt->strftime('%W') ) == $args->{week_mon_1} ) {
            $self->_our_croak(
                'Parsed an input where the ISO week number (Monday starts week) does not match the date'
                    . qq{ - "$args->{week_mon_1}" versus "}
                    . $dt->ymd
                    . q{"} );
            return;
        }
    }

    if ( defined $args->{week_sun_0} ) {
        unless ( ( 0 + $dt->strftime('%U') ) == $args->{week_sun_0} ) {
            $self->_our_croak(
                'Parsed an input where the ISO week number (Sunday starts week) does not match the date'
                    . qq{ - "$args->{week_sun_0}" versus "}
                    . $dt->ymd
                    . q{"} );
            return;
        }
    }

    return 1;
}
## use critic

sub pattern {
    my $self = shift;
    return $self->{pattern};
}

sub locale {
    my $self = shift;
    return $self->{locale}->can('code')
        ? $self->{locale}->code
        : $self->{locale}->id;
}

sub time_zone {
    my $self = shift;
    return $self->{time_zone}->name;
}

sub parse_duration {
    croak q{DateTime::Format::Strptime doesn't do durations.};
}

{
    my $validator = validation_for( params => [ { type => t('DateTime') } ] );

    sub format_datetime {
        my $self = shift;
        my ($dt) = $validator->(@_);

        my $pattern = $self->pattern;
        $pattern =~ s/%O/$dt->time_zone->name/eg;
        return $dt->clone->set_locale( $self->locale )->strftime($pattern);
    }

}

sub format_duration {
    croak q{DateTime::Format::Strptime doesn't do durations.};
}

sub _our_croak {
    my $self  = shift;
    my $error = shift;

    return $self->{on_error}->( $self, $error ) if ref $self->{on_error};
    croak $error if $self->{on_error} eq 'croak';
    $self->{errmsg} = $error;
    return;
}

sub errmsg {
    $_[0]->{errmsg};
}

# Exportable functions:

sub strftime {
    my ( $pattern, $dt ) = @_;
    return DateTime::Format::Strptime->new(
        pattern  => $pattern,
        on_error => 'croak'
    )->format_datetime($dt);
}

sub strptime {
    my ( $pattern, $time_string ) = @_;
    return DateTime::Format::Strptime->new(
        pattern  => $pattern,
        on_error => 'croak'
    )->parse_datetime($time_string);
}

1;

# ABSTRACT: Parse and format strp and strf time patterns

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::Strptime - Parse and format strp and strf time patterns

=head1 VERSION

version 1.79

=head1 SYNOPSIS

    use DateTime::Format::Strptime;

    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%T',
        locale    => 'en_AU',
        time_zone => 'Australia/Melbourne',
    );

    my $dt = $strp->parse_datetime('23:16:42');

    $strp->format_datetime($dt);

    # 23:16:42

    # Croak when things go wrong:
    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%T',
        locale    => 'en_AU',
        time_zone => 'Australia/Melbourne',
        on_error  => 'croak',
    );

    # Do something else when things go wrong:
    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%T',
        locale    => 'en_AU',
        time_zone => 'Australia/Melbourne',
        on_error  => \&phone_police,
    );

=head1 DESCRIPTION

This module implements most of C<strptime(3)>, the POSIX function that is the
reverse of C<strftime(3)>, for C<DateTime>. While C<strftime> takes a
C<DateTime> and a pattern and returns a string, C<strptime> takes a string and
a pattern and returns the C<DateTime> object associated.

=for Pod::Coverage parse_duration format_duration

=head1 METHODS

This class offers the following methods.

=head2 DateTime::Format::Strptime->new(%args)

This methods creates a new object. It accepts the following arguments:

=over 4

=item * pattern

This is the pattern to use for parsing. This is required.

=item * strict

This is a boolean which disables or enables strict matching mode.

By default, this module turns your pattern into a regex that will match
anywhere in a string. So given the pattern C<%Y%m%d%H%M%S> it will match a
string like C<20161214233712>. However, this also means that a this pattern
will match B<any> string that contains 14 or more numbers! This behavior can be
very surprising.

If you enable strict mode, then the generated regex is wrapped in boundary
checks of the form C</(?:\A|\b)...(?:\b|\z_/)>. These checks ensure that the
pattern will only match when at the beginning or end of a string, or when it is
separated by other text with a word boundary (C<\w> versus C<\W>).

By default, strict mode is off. This is done for backwards compatibility.
Future releases may turn it on by default, as it produces less surprising
behavior in many cases.

Because the default may change in the future, B<< you are strongly encouraged
to explicitly set this when constructing all C<DateTime::Format::Strptime>
objects >>.

=item * time_zone

The default time zone to use for objects returned from parsing.

=item * zone_map

Some time zone abbreviations are ambiguous (e.g. PST, EST, EDT). By default,
the parser will die when it parses an ambiguous abbreviation. You may specify a
C<zone_map> parameter as a hashref to map zone abbreviations however you like:

    zone_map => { PST => '-0800', EST => '-0600' }

Note that you can also override non-ambiguous mappings if you want to as well.

=item * locale

The locale to use for objects returned from parsing.

=item * on_error

This can be one of C<'undef'> (the string, not an C<undef>), 'croak', or a
subroutine reference.

=over 8

=item * 'undef'

This is the default behavior. The module will return C<undef> on errors. The
error can be accessed using the C<< $object->errmsg >> method. This is the
ideal behaviour for interactive use where a user might provide an illegal
pattern or a date that doesn't match the pattern.

=item * 'croak'

The module will croak with an error message on errors.

=item * sub{...} or \&subname

When given a code ref, the module will call that sub on errors. The sub
receives two parameters: the object and the error message.

If your sub does not die, then the formatter will continue on as if C<on_error>
was C<'undef'>.

=back

=back

=head2 $strptime->parse_datetime($string)

Given a string in the pattern specified in the constructor, this method will
return a new C<DateTime> object.

If given a string that doesn't match the pattern, the formatter will croak or
return undef, depending on the setting of C<on_error> in the constructor.

=head2 $strptime->format_datetime($datetime)

Given a C<DateTime> object, this methods returns a string formatted in the
object's format. This method is synonymous with C<DateTime>'s strftime method.

=head2 $strptime->locale

This method returns the locale passed to the object's constructor.

=head2 $strptime->pattern

This method returns the pattern passed to the object's constructor.

=head2 $strptime->time_zone

This method returns the time zone passed to the object's constructor.

=head2 $strptime->errmsg

If the on_error behavior of the object is 'undef', you can retrieve error
messages with this method so you can work out why things went wrong.

=head1 EXPORTS

These subs are available as optional exports.

=head2 strptime( $strptime_pattern, $string )

Given a pattern and a string this function will return a new C<DateTime>
object.

=head2 strftime( $strftime_pattern, $datetime )

Given a pattern and a C<DateTime> object this function will return a formatted
string.

=head1 STRPTIME PATTERN TOKENS

The following tokens are allowed in the pattern string for strptime
(parse_datetime):

=over 4

=item * %%

The % character.

=item * %a or %A

The weekday name according to the given locale, in abbreviated form or the full
name.

=item * %b or %B or %h

The month name according to the given locale, in abbreviated form or the full
name.

=item * %c

The datetime format according to the given locale.

Note that this format can change without warning in new versions of
L<DateTime::Locale>. You should not use this pattern unless the string you are
parsing was generated by using this pattern with L<DateTime> B<and> you are
sure that this string was generated with the same version of
L<DateTime::Locale> that the parser is using.

=item * %C

The century number (0-99).

=item * %d or %e

The day of month (01-31). This will parse single digit numbers as well.

=item * %D

Equivalent to %m/%d/%y. (This is the American style date, very confusing to
non-Americans, especially since %d/%m/%y is widely used in Europe. The ISO 8601
standard pattern is %F.)

=item * %F

Equivalent to %Y-%m-%d. (This is the ISO style date)

=item * %g

The year corresponding to the ISO week number, but without the century (0-99).

=item * %G

The 4-digit year corresponding to the ISO week number.

=item * %H

The hour (00-23). This will parse single digit numbers as well.

=item * %I

The hour on a 12-hour clock (1-12).

=item * %j

The day number in the year (1-366).

=item * %m

The month number (01-12). This will parse single digit numbers as well.

=item * %M

The minute (00-59). This will parse single digit numbers as well.

=item * %n

Arbitrary whitespace.

=item * %N

Nanoseconds. For other sub-second values use C<%[number]N>.

=item * %p or %P

The equivalent of AM or PM according to the locale in use. See
L<DateTime::Locale>.

=item * %r

Equivalent to %I:%M:%S %p.

=item * %R

Equivalent to %H:%M.

=item * %s

Number of seconds since the Epoch.

=item * %S

The second (0-60; 60 may occur for leap seconds. See L<DateTime::LeapSecond>).

=item * %t

Arbitrary whitespace.

=item * %T

Equivalent to %H:%M:%S.

=item * %U

The week number with Sunday the first day of the week (0-53). The first Sunday
of January is the first day of week 1.

=item * %u

The weekday number (1-7) with Monday = 1. This is the C<DateTime> standard.

=item * %w

The weekday number (0-6) with Sunday = 0.

=item * %W

The week number with Monday the first day of the week (0-53). The first Monday
of January is the first day of week 1.

=item * %x

The date format according to the given locale.

Note that this format can change without warning in new versions of
L<DateTime::Locale>. You should not use this pattern unless the string you are
parsing was generated by using this pattern with L<DateTime> B<and> you are
sure that this string was generated with the same version of
L<DateTime::Locale> that the parser is using.

=item * %X

The time format according to the given locale.

Note that this format can change without warning in new versions of
L<DateTime::Locale>. You should not use this pattern unless the string you are
parsing was generated by using this pattern with L<DateTime> B<and> you are
sure that this string was generated with the same version of
L<DateTime::Locale> that the parser is using.

=item * %y

The year within century (0-99). When a century is not otherwise specified (with
a value for %C), values in the range 69-99 refer to years in the twentieth
century (1969-1999); values in the range 00-68 refer to years in the
twenty-first century (2000-2068).

=item * %Y

A 4-digit year, including century (for example, 1991).

=item * %z

An RFC-822/ISO 8601 standard time zone specification. (For example +1100) [See
note below]

=item * %Z

The timezone name. (For example EST -- which is ambiguous) [See note below]

=item * %O

This extended token allows the use of Olson Time Zone names to appear in parsed
strings. B<NOTE>: This pattern cannot be passed to C<DateTime>'s C<strftime()>
method, but can be passed to C<format_datetime()>.

=back

=head1 AUTHOR EMERITUS

This module was created by Rick Measham.

=head1 SEE ALSO

C<datetime@perl.org> mailing list.

http://datetime.perl.org/

L<perl>, L<DateTime>, L<DateTime::TimeZone>, L<DateTime::Locale>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-datetime-format-strptime@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>. I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

Bugs may be submitted at L<https://github.com/houseabsolute/DateTime-Format-Strptime/issues>.

There is a mailing list available for users of this distribution,
L<mailto:datetime@perl.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for DateTime-Format-Strptime can be found at L<https://github.com/houseabsolute/DateTime-Format-Strptime>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<https://www.urth.org/fs-donation.html>.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Rick Measham <rickm@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Christian Hansen D. Ilmari Mannsåker gregor herrmann key-amb Mohammad S Anwar

=over 4

=item *

Christian Hansen <chansen@cpan.org>

=item *

D. Ilmari Mannsåker <ilmari.mannsaker@net-a-porter.com>

=item *

gregor herrmann <gregoa@debian.org>

=item *

key-amb <yasutake.kiyoshi@gmail.com>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 - 2021 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
