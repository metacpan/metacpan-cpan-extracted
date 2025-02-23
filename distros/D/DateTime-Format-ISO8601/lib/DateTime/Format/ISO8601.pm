# Copyright (C) 2003-2012  Joshua Hoblitt
package DateTime::Format::ISO8601;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.17';

use Carp qw( croak );
use DateTime 1.45;
use DateTime::Format::Builder 0.77;
use DateTime::Format::ISO8601::Types;
use Params::ValidationCompiler 0.26 qw( validation_for );

{
    my $validator = validation_for(
        name             => 'DefaultLegacyYear',
        name_is_optional => 1,
        params           => [ { type => t('Bool') } ],
    );

    my $default_legacy_year;

    sub DefaultLegacyYear {
        shift;
        ($default_legacy_year) = $validator->(@_)
            if @_;

        return $default_legacy_year;
    }
}

__PACKAGE__->DefaultLegacyYear(1);

{
    my $validator = validation_for(
        name             => 'DefaultCutOffYear',
        name_is_optional => 1,
        params           => [ { type => t('CutOffYear') } ],
    );

    my $default_cut_off_year;

    sub DefaultCutOffYear {
        shift;
        ($default_cut_off_year) = $validator->(@_)
            if @_;

        return $default_cut_off_year;
    }
}

# the same default value as DT::F::Mail
__PACKAGE__->DefaultCutOffYear(49);

{
    my $validator = validation_for(
        name             => '_check_new_params',
        name_is_optional => 1,
        params           => {
            base_datetime => {
                type     => t('DateTimeIsh'),
                optional => 1,
            },
            legacy_year => {
                type     => t('Bool'),
                optional => 1,
            },
            cut_off_year => {
                type     => t('CutOffYear'),
                optional => 1,
            },
        },
    );

    sub new {
        my ($class) = shift;
        my %args = $validator->(@_);

        $args{legacy_year} = $class->DefaultLegacyYear
            unless exists $args{legacy_year};
        $args{cut_off_year} = $class->DefaultCutOffYear
            unless exists $args{cut_off_year};

        $class = ref($class) || $class;

        my $self = bless( \%args, $class );

        if ( $args{base_datetime} ) {
            $self->set_base_datetime( object => $args{base_datetime} );
        }

        return ($self);
    }
}

# lifted from DateTime
sub clone { bless { %{ $_[0] } }, ref $_[0] }

sub base_datetime { $_[0]->{base_datetime} }

{
    my $validator = validation_for(
        name             => 'set_base_datetime',
        name_is_optional => 1,
        params           => {
            object => { type => t('DateTimeIsh') },
        },
    );

    sub set_base_datetime {
        my $self = shift;

        my %args = $validator->(@_);

        # ISO8601 only allows years 0 to 9999
        # this implementation ignores the needs of expanded formats
        my $dt          = DateTime->from_object( object => $args{object} );
        my $lower_bound = DateTime->new( year => 0 );
        my $upper_bound = DateTime->new( year => 10000 );

        if ( $dt < $lower_bound ) {
            croak 'base_datetime must be greater then or equal to ',
                $lower_bound->iso8601;
        }
        if ( $dt >= $upper_bound ) {
            croak 'base_datetime must be less then ', $upper_bound->iso8601;
        }

        $self->{base_datetime} = $dt;

        return $self;
    }
}

sub legacy_year { $_[0]->{legacy_year} }

{
    my $validator = validation_for(
        name             => 'set_legacy_year',
        name_is_optional => 1,
        params           => [ { type => t('Bool') } ],
    );

    sub set_legacy_year {
        my $self = shift;

        ( $self->{legacy_year} ) = $validator->(@_);

        return $self;
    }
}

sub cut_off_year { $_[0]->{cut_off_year} }

{
    my $validator = validation_for(
        name             => 'set_cut_off_year',
        name_is_optional => 1,
        params           => [ { type => t('CutOffYear') } ],
    );

    sub set_cut_off_year {
        my $self = shift;

        ( $self->{cut_off_year} ) = $validator->(@_);

        return $self;
    }
}

{
    my $validator = validation_for(
        name             => 'format_datetime',
        name_is_optional => 1,
        params           => [ { type => t('DateTime') } ],
    );

    sub format_datetime {
        my $self = shift;
        my ($dt) = $validator->(@_);

        my $cldr
            = $dt->nanosecond % 1000000 ? 'yyyy-MM-ddTHH:mm:ss.SSSSSSSSS'
            : $dt->nanosecond           ? 'yyyy-MM-ddTHH:mm:ss.SSS'
            :                             'yyyy-MM-ddTHH:mm:ss';

        my $tz;
        if ( $dt->time_zone->is_utc ) {
            $tz = 'Z';
        }
        else {
            $tz = q{};
            $cldr .= 'ZZZZZ';
        }

        return $dt->format_cldr($cldr) . $tz;
    }
}

DateTime::Format::Builder->create_class(
    parsers => {
        parse_datetime => [
            {
                #YYYYMMDD 19850412
                length => 8,
                regex  => qr/^ (\d{4}) (\d\d) (\d\d) $/x,
                params => [qw( year month day )],
            },
            {
                # uncombined with above because
                #regex => qr/^ (\d{4}) -??  (\d\d) -?? (\d\d) $/x,
                # was matching 152746-05

                #YYYY-MM-DD 1985-04-12
                length => 10,
                regex  => qr/^ (\d{4}) - (\d\d) - (\d\d) $/x,
                params => [qw( year month day )],
            },
            {
                #YYYY-MM 1985-04
                length => 7,
                regex  => qr/^ (\d{4}) - (\d\d) $/x,
                params => [qw( year month )],
            },
            {
                #YYYY 1985
                length => 4,
                regex  => qr/^ (\d{4}) $/x,
                params => [qw( year )],
            },
            {
                #YY 19 (century)
                length      => 2,
                regex       => qr/^ (\d\d) $/x,
                params      => [qw( year )],
                postprocess => \&_normalize_century,
            },
            {
                #YYMMDD 850412
                #YY-MM-DD 85-04-12
                length      => [qw( 6 8 )],
                regex       => qr/^ (\d\d) -??  (\d\d) -?? (\d\d) $/x,
                params      => [qw( year month day )],
                postprocess => \&_fix_2_digit_year,
            },
            {
                #-YYMM -8504
                #-YY-MM -85-04
                length      => [qw( 5 6 )],
                regex       => qr/^ - (\d\d) -??  (\d\d) $/x,
                params      => [qw( year month )],
                postprocess => \&_fix_2_digit_year,
            },
            {
                #-YY -85
                length      => 3,
                regex       => qr/^ - (\d\d) $/x,
                params      => [qw( year )],
                postprocess => \&_fix_2_digit_year,
            },
            {
                #--MMDD --0412
                #--MM-DD --04-12
                length      => [qw( 6 7 )],
                regex       => qr/^ -- (\d\d) -??  (\d\d) $/x,
                params      => [qw( month day )],
                postprocess => \&_add_year,
            },
            {
                #--MM --04
                length      => 4,
                regex       => qr/^ -- (\d\d) $/x,
                params      => [qw( month )],
                postprocess => \&_add_year,
            },
            {
                #---DD ---12
                length      => 5,
                regex       => qr/^ --- (\d\d) $/x,
                params      => [qw( day )],
                postprocess => [ \&_add_year, \&_add_month ],
            },
            {
                #+[YY]YYYYMMDD +0019850412
                #+[YY]YYYY-MM-DD +001985-04-12
                length => [qw( 11 13 )],
                regex  => qr/^ \+ (\d{6}) -?? (\d\d) -?? (\d\d)  $/x,
                params => [qw( year month day )],
            },
            {
                #+[YY]YYYY-MM +001985-04
                length => 10,
                regex  => qr/^ \+ (\d{6}) - (\d\d)  $/x,
                params => [qw( year month )],
            },
            {
                #+[YY]YYYY +001985
                length => 7,
                regex  => qr/^ \+ (\d{6}) $/x,
                params => [qw( year )],
            },
            {
                #+[YY]YY +0019 (century)
                length      => 5,
                regex       => qr/^ \+ (\d{4}) $/x,
                params      => [qw( year )],
                postprocess => \&_normalize_century,
            },
            {
                #YYYYDDD 1985102
                #YYYY-DDD 1985-102
                length      => [qw( 7 8 )],
                regex       => qr/^ (\d{4}) -?? (\d{3}) $/x,
                params      => [qw( year day_of_year )],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #YYDDD 85102
                #YY-DDD 85-102
                length      => [qw( 5 6 )],
                regex       => qr/^ (\d\d) -?? (\d{3}) $/x,
                params      => [qw( year day_of_year )],
                postprocess => [ \&_fix_2_digit_year ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #-DDD -102
                length      => 4,
                regex       => qr/^ - (\d{3}) $/x,
                params      => [qw( day_of_year )],
                postprocess => [ \&_add_year ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #+[YY]YYYYDDD +001985102
                #+[YY]YYYY-DDD +001985-102
                length      => [qw( 10 11 )],
                regex       => qr/^ \+ (\d{6}) -?? (\d{3}) $/x,
                params      => [qw( year day_of_year )],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #YYYYWwwD 1985W155
                #YYYY-Www-D 1985-W15-5
                length      => [qw( 8 10 )],
                regex       => qr/^ (\d{4}) -?? W (\d\d) -?? (\d) $/x,
                params      => [qw( year week day_of_week )],
                postprocess => [ \&_normalize_week ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #YYYYWww 1985W15
                #YYYY-Www 1985-W15
                length      => [qw( 7 8 )],
                regex       => qr/^ (\d{4}) -?? W (\d\d) $/x,
                params      => [qw( year week )],
                postprocess => [ \&_normalize_week ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #YYWwwD 85W155
                #YY-Www-D 85-W15-5
                length      => [qw( 6 8 )],
                regex       => qr/^ (\d\d) -?? W (\d\d) -?? (\d) $/x,
                params      => [qw( year week day_of_week )],
                postprocess => [ \&_fix_2_digit_year, \&_normalize_week ],
                constructor => [ 'DateTime',          'from_day_of_year' ],
            },
            {
                #YYWww 85W15
                #YY-Www 85-W15
                length      => [qw( 5 6 )],
                regex       => qr/^ (\d\d) -?? W (\d\d) $/x,
                params      => [qw( year week )],
                postprocess => [ \&_fix_2_digit_year, \&_normalize_week ],
                constructor => [ 'DateTime',          'from_day_of_year' ],
            },
            {
                #-YWwwD -5W155
                #-Y-Www-D -5-W15-5
                length      => [qw( 6 8 )],
                regex       => qr/^ - (\d) -?? W (\d\d) -?? (\d) $/x,
                params      => [qw( year week day_of_week )],
                postprocess => [ \&_fix_1_digit_year, \&_normalize_week ],
                constructor => [ 'DateTime',          'from_day_of_year' ],
            },
            {
                #-YWww -5W15
                #-Y-Www -5-W15
                length      => [qw( 5 6 )],
                regex       => qr/^ - (\d) -?? W (\d\d) $/x,
                params      => [qw( year week )],
                postprocess => [ \&_fix_1_digit_year, \&_normalize_week ],
                constructor => [ 'DateTime',          'from_day_of_year' ],
            },
            {
                #-WwwD -W155
                #-Www-D -W15-5
                length      => [qw( 5 6 )],
                regex       => qr/^ - W (\d\d) -?? (\d) $/x,
                params      => [qw( week day_of_week )],
                postprocess => [ \&_add_year, \&_normalize_week ],
                constructor => [ 'DateTime',  'from_day_of_year' ],
            },
            {
                #-Www -W15
                length      => 4,
                regex       => qr/^ - W (\d\d) $/x,
                params      => [qw( week )],
                postprocess => [ \&_add_year, \&_normalize_week ],
                constructor => [ 'DateTime',  'from_day_of_year' ],
            },
            {
                #-W-D -W-5
                length      => 4,
                regex       => qr/^ - W - (\d) $/x,
                params      => [qw( day_of_week )],
                postprocess => [
                    \&_add_year,
                    \&_add_week,
                    \&_normalize_week,
                ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #+[YY]YYYYWwwD +001985W155
                #+[YY]YYYY-Www-D +001985-W15-5
                length      => [qw( 11 13 )],
                regex       => qr/^ \+ (\d{6}) -?? W (\d\d) -?? (\d) $/x,
                params      => [qw( year week day_of_week )],
                postprocess => [ \&_normalize_week ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #+[YY]YYYYWww +001985W15
                #+[YY]YYYY-Www +001985-W15
                length      => [qw( 10 11 )],
                regex       => qr/^ \+ (\d{6}) -?? W (\d\d) $/x,
                params      => [qw( year week )],
                postprocess => [ \&_normalize_week ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #hhmmss 232050 - skipped
                #hh:mm:ss 23:20:50
                length      => [qw( 8 9 )],
                regex       => qr/^ T?? (\d\d) : (\d\d) : (\d\d) $/x,
                params      => [qw( hour minute second)],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day
                ],
            },

            #hhmm 2320 - skipped
            #hh 23 -skipped
            {
                #hh:mm 23:20
                length      => [qw( 4 5 6 )],
                regex       => qr/^ T?? (\d\d) :?? (\d\d) $/x,
                params      => [qw( hour minute )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day
                ],
            },
            {
                #hhmmss,ss 232050,5
                #hh:mm:ss,ss 23:20:50,5
                regex =>
                    qr/^ T?? (\d\d) :?? (\d\d) :?? (\d\d) [\.,] (\d+) $/x,
                params      => [qw( hour minute second nanosecond)],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_fractional_second
                ],
            },
            {
                #hhmm,mm 2320,8
                #hh:mm,mm 23:20,8
                regex       => qr/^ T?? (\d\d) :?? (\d\d) [\.,] (\d+) $/x,
                params      => [qw( hour minute second )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_fractional_minute
                ],
            },
            {
                #hh,hh 23,3
                regex       => qr/^ T?? (\d\d) [\.,] (\d+) $/x,
                params      => [qw( hour minute )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_fractional_hour
                ],
            },
            {
                #-mmss -2050 - skipped
                #-mm:ss -20:50
                length      => 6,
                regex       => qr/^ - (\d\d) : (\d\d) $/x,
                params      => [qw( minute second )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour
                ],
            },

            #-mm -20 - skipped
            #--ss --50 - skipped
            {
                #-mmss,s -2050,5
                #-mm:ss,s -20:50,5
                regex       => qr/^ - (\d\d) :?? (\d\d) [\.,] (\d+) $/x,
                params      => [qw( minute second nanosecond )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour,
                    \&_fractional_second
                ],
            },
            {
                #-mm,m -20,8
                regex       => qr/^ - (\d\d) [\.,] (\d+) $/x,
                params      => [qw( minute second )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour,
                    \&_fractional_minute
                ],
            },
            {
                #--ss,s --50,5
                regex       => qr/^ -- (\d\d) [\.,] (\d+) $/x,
                params      => [qw( second nanosecond)],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour,
                    \&_add_minute,
                    \&_fractional_second,
                ],
            },
            {
                #hhmmssZ 232030Z
                #hh:mm:ssZ 23:20:30Z
                length      => [qw( 7 8 9 10 )],
                regex       => qr/^ T?? (\d\d) :?? (\d\d) :?? (\d\d) Z $/x,
                params      => [qw( hour minute second )],
                extra       => { time_zone => 'UTC' },
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                ],
            },

            {
                #hhmmss.ssZ 232030.5Z
                #hh:mm:ss.ssZ 23:20:30.5Z
                regex =>
                    qr/^ T?? (\d\d) :?? (\d\d) :?? (\d\d) [\.,] (\d+) Z $/x,
                params      => [qw( hour minute second nanosecond)],
                extra       => { time_zone => 'UTC' },
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_fractional_second
                ],
            },

            {
                #hhmmZ 2320Z
                #hh:mmZ 23:20Z
                length      => [qw( 5 6 7 )],
                regex       => qr/^ T?? (\d\d) :?? (\d\d) Z $/x,
                params      => [qw( hour minute )],
                extra       => { time_zone => 'UTC' },
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                ],
            },
            {
                #hhZ 23Z
                length      => [qw( 3 4 )],
                regex       => qr/^ T?? (\d\d) Z $/x,
                params      => [qw( hour )],
                extra       => { time_zone => 'UTC' },
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                ],
            },
            {
                #hhmmss[+-]hhmm 152746+0100 152746-0500
                #hh:mm:ss[+-]hh:mm 15:27:46+01:00 15:27:46-05:00
                length => [qw( 11 12 14 15 )],
                regex  => qr/^ T?? (\d\d) :?? (\d\d) :?? (\d\d)
                            ([+-] \d\d :?? \d\d) $/x,
                params      => [qw( hour minute second time_zone )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_normalize_offset,
                ],
            },
            {
                #hhmmss.ss[+-]hhmm 152746.5+0100 152746.5-0500
                #hh:mm:ss.ss[+-]hh:mm 15:27:46.5+01:00 15:27:46.5-05:00
                regex => qr/^ T?? (\d\d) :?? (\d\d) :?? (\d\d) [\.,] (\d+)
                            ([+-] \d\d :?? \d\d) $/x,
                params => [qw( hour minute second nanosecond time_zone )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_fractional_second,
                    \&_normalize_offset,
                ],
            },

            {
                #hhmmss[+-]hh 152746+01 152746-05
                #hh:mm:ss[+-]hh 15:27:46+01 15:27:46-05
                length => [qw( 9 10 11 12 )],
                regex  => qr/^ T?? (\d\d) :?? (\d\d) :?? (\d\d)
                            ([+-] \d\d) $/x,
                params      => [qw( hour minute second time_zone )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_normalize_offset,
                ],
            },
            {
                #YYYYMMDDThhmmss 19850412T101530
                #YYYY-MM-DDThh:mm:ss 1985-04-12T10:15:30
                length => [qw( 15 19 )],
                regex  => qr/^ (\d{4}) -??  (\d\d) -?? (\d\d)
                            T (\d\d) :?? (\d\d) :?? (\d\d) $/x,
                params => [qw( year month day hour minute second )],
                extra  => { time_zone => 'floating' },
            },
            {
                #YYYYMMDDThhmmss.ss 19850412T101530.123
                #YYYY-MM-DDThh:mm:ss.ss 1985-04-12T10:15:30.123
                regex => qr/^ (\d{4}) -??  (\d\d) -?? (\d\d)
                            T (\d\d) :?? (\d\d) :?? (\d\d) [\.,] (\d+) $/x,
                params =>
                    [qw( year month day hour minute second nanosecond )],
                extra       => { time_zone => 'floating' },
                postprocess => [
                    \&_fractional_second,
                ],
            },
            {
                #YYYYMMDDThhmmssZ 19850412T101530Z
                #YYYY-MM-DDThh:mm:ssZ 1985-04-12T10:15:30Z
                length => [qw( 16 20 )],
                regex  => qr/^ (\d{4}) -??  (\d\d) -?? (\d\d)
                            T (\d\d) :?? (\d\d) :?? (\d\d) Z $/x,
                params => [qw( year month day hour minute second )],
                extra  => { time_zone => 'UTC' },
            },
            {
                #YYYYMMDDThhmmss.ssZ 19850412T101530.5Z 20041020T101530.5Z
                #YYYY-MM-DDThh:mm:ss.ssZ 1985-04-12T10:15:30.5Z 1985-04-12T10:15:30.5Z
                regex => qr/^ (\d{4}) -??  (\d\d) -?? (\d\d)
                            T?? (\d\d) :?? (\d\d) :?? (\d\d) [\.,] (\d+)
                            Z$/x,
                params =>
                    [qw( year month day hour minute second nanosecond )],
                extra       => { time_zone => 'UTC' },
                postprocess => [
                    \&_fractional_second,
                ],
            },
            {
                #YYYYMMDDThhmm[+-]hhmm 19850412T1015+0400
                #YYYY-MM-DDThh:mm[+-]hh:mm 1985-04-12T10:15+04:00
                length => [qw( 18 22 )],
                regex  => qr/^ (\d{4}) -??  (\d\d) -?? (\d\d)
                             T (\d\d) :?? (\d\d) ([+-] \d\d :?? \d\d) $/x,
                params      => [qw( year month day hour minute time_zone )],
                postprocess => \&_normalize_offset,
            },
            {
                #YYYYMMDDThhmmss[+-]hhmm 19850412T101530+0400
                #YYYY-MM-DDThh:mm:ss[+-]hh:mm 1985-04-12T10:15:30+04:00
                length => [qw( 20 24 25 )],
                regex  => qr/^ (\d{4}) -??  (\d\d) -?? (\d\d)
                            T (\d\d) :?? (\d\d) :?? (\d\d) ([+-] \d\d :?? \d\d) $/x,
                params => [qw( year month day hour minute second time_zone )],
                postprocess => \&_normalize_offset,
            },
            {
                #YYYYMMDDThhmmss.ss[+-]hhmm 19850412T101530.5+0100 20041020T101530.5-0500
                regex => qr/^ (\d{4}) (\d\d) (\d\d)
                            T?? (\d\d) (\d\d) (\d\d) [\.,] (\d+)
                            ([+-] \d\d \d\d) $/x,
                params => [
                    qw( year month day hour minute second nanosecond time_zone )
                ],
                postprocess => [
                    \&_fractional_second,
                    \&_normalize_offset,
                ],
            },
            {
                #YYYY-MM-DDThh:mm:ss.ss[+-]hh 1985-04-12T10:15:30.5+01 1985-04-12T10:15:30.5-05
                regex => qr/^ (\d{4}) -  (\d\d) - (\d\d)
                            T?? (\d\d) : (\d\d) : (\d\d) [\.,] (\d+)
                            ([+-] \d\d ) $/x,
                params => [
                    qw( year month day hour minute second nanosecond time_zone )
                ],
                postprocess => [
                    \&_fractional_second,
                    \&_normalize_offset,
                ],
            },
            {
                #YYYYMMDDThhmmss.ss[+-]hh 19850412T101530.5+01 20041020T101530.5-05
                regex => qr/^ (\d{4}) (\d\d) (\d\d)
                            T?? (\d\d) (\d\d) (\d\d) [\.,] (\d+)
                            ([+-] \d\d ) $/x,
                params => [
                    qw( year month day hour minute second nanosecond time_zone )
                ],
                postprocess => [
                    \&_fractional_second,
                    \&_normalize_offset,
                ],
            },
            {
                #YYYY-MM-DDThh:mm:ss.ss[+-]hh:mm 1985-04-12T10:15:30.5+01:00 1985-04-12T10:15:30.5-05:00
                regex => qr/^ (\d{4}) -  (\d\d) - (\d\d)
                            T?? (\d\d) : (\d\d) : (\d\d) [\.,] (\d+)
                            ([+-] \d\d : \d\d) $/x,
                params => [
                    qw( year month day hour minute second nanosecond time_zone )
                ],
                postprocess => [
                    \&_fractional_second,
                    \&_normalize_offset,
                ],
            },

            {
                #YYYYMMDDThhmmss[+-]hh 19850412T101530+04
                #YYYY-MM-DDThh:mm:ss[+-]hh 1985-04-12T10:15:30+04
                length => [qw( 18 22 )],
                regex  => qr/^ (\d{4}) -??  (\d\d) -?? (\d\d)
                            T (\d\d) :?? (\d\d) :?? (\d\d) ([+-] \d\d) $/x,
                params => [qw( year month day hour minute second time_zone )],
                postprocess => \&_normalize_offset,
            },
            {
                #YYYYMMDDThhmm 19850412T1015
                #YYYY-MM-DDThh:mm 1985-04-12T10:15
                length => [qw( 13 16 )],
                regex  => qr/^ (\d{4}) -??  (\d\d) -?? (\d\d)
                            T (\d\d) :?? (\d\d) $/x,
                params => [qw( year month day hour minute )],
                extra  => { time_zone => 'floating' },
            },
            {
                #YYYYMMDDThhmmZ 19850412T1015
                #YYYY-MM-DDThh:mmZ 1985-04-12T10:15
                length => [qw( 14 17 )],
                regex  => qr/^ (\d{4}) -??  (\d\d) -?? (\d\d)
                            T (\d\d) :?? (\d\d) Z $/x,
                params => [qw( year month day hour minute )],
                extra  => { time_zone => 'UTC' },
            },
            {
                #YYYYDDDThhmm 1985102T1015
                #YYYY-DDDThh:mm 1985-102T10:15
                length => [qw( 12 14 )],
                regex  => qr/^ (\d{4}) -??  (\d{3}) T
                            (\d\d) :?? (\d\d) $/x,
                params      => [qw( year day_of_year hour minute )],
                extra       => { time_zone => 'floating' },
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #YYYYDDDThhmmZ 1985102T1015Z
                #YYYY-DDDThh:mmZ 1985-102T10:15Z
                length => [qw( 13 15 )],
                regex  => qr/^ (\d{4}) -??  (\d{3}) T
                            (\d\d) :?? (\d\d) Z $/x,
                params      => [qw( year day_of_year hour minute )],
                extra       => { time_zone => 'UTC' },
                constructor => [ 'DateTime', 'from_day_of_year' ],

            },
            {
                #YYYYWwwDThhmm[+-]hhmm 1985W155T1015+0400
                #YYYY-Www-DThh:mm[+-]hh 1985-W15-5T10:15+04
                length => [qw( 18 19 )],
                regex  => qr/^ (\d{4}) -?? W (\d\d) -?? (\d)
                            T (\d\d) :?? (\d\d) ([+-] \d{2,4}) $/x,
                params => [qw( year week day_of_week hour minute time_zone)],
                postprocess => [ \&_normalize_week, \&_normalize_offset ],
                constructor => [ 'DateTime',        'from_day_of_year' ],
            },
        ],
        parse_time => [
            {
                #hhmmss 232050
                length      => [qw( 6 7 )],
                regex       => qr/^ T?? (\d\d) (\d\d) (\d\d) $/x,
                params      => [qw( hour minute second )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                ],
            },
            {
                #hhmm 2320
                length      => [qw( 4 5 )],
                regex       => qr/^ T?? (\d\d) (\d\d) $/x,
                params      => [qw( hour minute )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                ],
            },
            {
                #hh 23
                length      => [qw( 2 3 )],
                regex       => qr/^ T?? (\d\d) $/x,
                params      => [qw( hour )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                ],
            },
            {
                #-mmss -2050
                length      => 5,
                regex       => qr/^ - (\d\d) (\d\d) $/x,
                params      => [qw( minute second )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour,
                ],
            },
            {
                #-mm -20
                length      => 3,
                regex       => qr/^ - (\d\d) $/x,
                params      => [qw( minute )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour,
                ],
            },
            {
                #--ss --50
                length      => 4,
                regex       => qr/^ -- (\d\d) $/x,
                params      => [qw( second )],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour,
                    \&_add_minute,
                ],
            },
        ],
    }
);

sub _fix_1_digit_year {
    my %p = @_;

    my $year = _base_dt( $p{self} )->year;

    $year =~ s/.$//;
    $p{parsed}{year} = $year . $p{parsed}{year};

    return 1;
}

sub _fix_2_digit_year {
    my %p = @_;

    # this is a mess because of the need to support parse_* being called
    # as a class method
    if ( ref $p{self} && exists $p{self}{legacy_year} ) {
        if ( $p{self}{legacy_year} ) {
            my $cutoff
                = exists $p{self}{cut_off_year}
                ? $p{self}{cut_off_year}
                : $p{self}->DefaultCutOffYear;
            $p{parsed}{year} += $p{parsed}{year} > $cutoff ? 1900 : 2000;
        }
        else {
            my $century = ( $p{self}{base_datetime} || DateTime->now )
                ->strftime('%C');
            $p{parsed}{year} += $century * 100;
        }
    }
    else {
        my $cutoff
            = ref $p{self} && exists $p{self}{cut_off_year}
            ? $p{self}{cut_off_year}
            : $p{self}->DefaultCutOffYear;
        $p{parsed}{year} += $p{parsed}{year} > $cutoff ? 1900 : 2000;
    }

    return 1;
}

sub _add_minute {
    my %p = @_;

    $p{parsed}{minute} = _base_dt( $p{self} )->minute;

    return 1;
}

sub _add_hour {
    my %p = @_;

    $p{parsed}{hour} = _base_dt( $p{self} )->hour;

    return 1;
}

sub _add_day {
    my %p = @_;

    $p{parsed}{day} = _base_dt( $p{self} )->day;

    return 1;
}

sub _add_week {
    my %p = @_;

    $p{parsed}{week} = _base_dt( $p{self} )->week;

    return 1;
}

sub _add_month {
    my %p = @_;

    $p{parsed}{month} = _base_dt( $p{self} )->month;

    return 1;
}

sub _add_year {
    my %p = @_;

    $p{parsed}{year} = _base_dt( $p{self} )->year;

    return 1;
}

sub _base_dt {
    return $_[0]{base_datetime} if ref $_[0] && $_[0]{base_datetime};
    return DateTime->now;
}

sub _fractional_second {
    my %p = @_;

    ## no critic (ValuesAndExpressions::ProhibitMismatchedOperators)
    $p{parsed}{nanosecond} = int( ".$p{ parsed }{ nanosecond }" * 10**9 );

    return 1;
}

sub _fractional_minute {
    my %p = @_;

    ## no critic (ValuesAndExpressions::ProhibitMismatchedOperators)
    $p{parsed}{second} = ".$p{ parsed }{ second }" * 60;

    return 1;
}

sub _fractional_hour {
    my %p = @_;

    ## no critic (ValuesAndExpressions::ProhibitMismatchedOperators)
    $p{parsed}{minute} = ".$p{ parsed }{ minute }" * 60;

    return 1;
}

sub _normalize_offset {
    my %p = @_;

    $p{parsed}{time_zone} =~ s/://;

    if ( length $p{parsed}{time_zone} == 3 ) {
        $p{parsed}{time_zone} .= '00';
    }

    return 1;
}

sub _normalize_week {
    my %p = @_;

    # See
    # https://en.wikipedia.org/wiki/ISO_week_date#Calculating_an_ordinal_or_month_date_from_a_week_date
    # for the algorithm we're using here.
    my $od = $p{parsed}{week} * 7;
    $od += ( exists $p{parsed}{day_of_week} ? $p{parsed}{day_of_week} : 1 );
    $od -= DateTime->new(
        year  => $p{parsed}{year},
        month => 1,
        day   => 4,
    )->day_of_week + 3;

    my ( $year, $day_of_year );
    if ( $od < 1 ) {
        $year        = $p{parsed}{year} - 1;
        $day_of_year = DateTime->new( year => $year )->year_length + $od;
    }
    else {
        my $year_length
            = DateTime->new( year => $p{parsed}{year} )->year_length;
        if ( $od > $year_length ) {
            $year        = $p{parsed}{year} + 1;
            $day_of_year = $od - $year_length;
        }
        else {
            $year        = $p{parsed}{year};
            $day_of_year = $od;
        }
    }

    # We need to leave the references in $p{parsed} as is. We cannot create a
    # new reference.
    $p{parsed}{year}        = $year;
    $p{parsed}{day_of_year} = $day_of_year;

    delete $p{parsed}{week};
    delete $p{parsed}{day_of_week};

    return 1;
}

sub _normalize_century {
    my %p = @_;

    $p{parsed}{year} .= '01';

    return 1;
}

1;

# ABSTRACT: Parses ISO8601 formats

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::ISO8601 - Parses ISO8601 formats

=head1 VERSION

version 0.17

=head1 SYNOPSIS

    use DateTime::Format::ISO8601;

    my $datetime_str = '2020-07-25T11:32:31';
    my $dt = DateTime::Format::ISO8601->parse_datetime($datetime_str);
    say $dt;

    # This format is ambiguous and could be either a date or time, so use the
    # parse_time method.
    my $time_str = '113231';
    $dt = DateTime::Format::ISO8601->parse_time($time_str);
    say $dt;

    # or

    my $iso8601 = DateTime::Format::ISO8601->new;
    $dt = $iso8601->parse_datetime($datetime_str);
    say $dt;

    $dt = $iso8601->parse_time($time_str);
    say $dt;

    say DateTime::Format::ISO8601->format_datetime($dt);

=head1 DESCRIPTION

Parses almost all ISO8601 date and time formats. ISO8601 time-intervals will be
supported in a later release.

=head1 METHODS

This class provides the following methods:

=head2 Constructors

=head3 DateTime::Format::ISO8601->new( ... )

Accepts an optional hash.

    my $iso8601 = DateTime::Format::ISO8601->new(
        base_datetime => $dt,
        cut_off_year  => 42,
        legacy_year   => 1,
    );

=over 4

=item * base_datetime

A C<DateTime> object that will be used to fill in missing information from
incomplete date/time formats.

This key is optional.

=item * cut_off_year

A integer representing the cut-off point between interpreting 2-digits years as
19xx or 20xx.

    2-digit years <  cut_off_year will be interpreted as 20xx
    2-digit years >= cut_off_year will be untreated as 19xx

This key defaults to the value of C<DefaultCutOffYear>.

=item * legacy_year

A boolean value controlling if a 2-digit year is interpreted as being in the
current century (unless a C<base_datetime> is set) or if C<cut_off_year> should
be used to place the year in either 20xx or 19xx.

If this is true, then the C<cut_off_year> is used. If this is false, then the
year is always interpreted as being in the current century.

This key defaults to the value of C<DefaultLegacyYear>.

=back

=head3 $iso8601->clone

Returns a replica of the given object.

=head2 Object Methods

=head3 $iso8601->base_datetime

Returns a C<DateTime> object if a C<base_datetime> has been set.

=head3 $iso8601->set_base_datetime( object => $object )

Accepts a C<DateTime> object that will be used to fill in missing information
from incomplete date/time formats.

=head3 $iso8601->cut_off_year

Returns a integer representing the cut-off point between interpreting 2-digits
years as 19xx or 20xx.

=head3 $iso8601->set_cut_off_year($int)

Accepts a integer representing the cut-off point between interpreting 2-digits
years as 19xx or 20xx.

    2-digit years <  legacy_year will be interpreted as 20xx
    2-digit years >= legacy_year will be interpreted as 19xx

=head3 $iso8601->legacy_year

Returns a boolean value indicating the 2-digit year handling behavior.

=head3 $iso8601->set_legacy_year($bool)

Accepts a boolean value controlling if a 2-digit year is interpreted as being
in the current century (unless a C<base_datetime> is set) or if C<cut_off_year>
should be used to place the year in either 20xx or 19xx.

=head2 Class Methods

=head3 DateTime::Format::ISO8601->DefaultCutOffYear($int)

Accepts a integer representing the cut-off point for 2-digit years when calling
C<parse_*> as class methods and the default value for C<cut_off_year> when
creating objects. If called with no parameters this method will return the
default value for C<cut_off_year>.

=head3 DateTime::Format::ISO8601->DefaultLegacyYear($bool)

Accepts a boolean value controlling the legacy year behavior when calling
C<parse_*> as class methods and the default value for C<legacy_year> when
creating objects. If called with no parameters this method will return the
default value for C<legacy_year>.

=head2 Parser(s)

These methods may be called as either class or object methods.

=head3 parse_datetime

=head3 parse_time

Please see the L</FORMATS> section.

=head2 Formatter

This may be called as either class or object method.

=head3 format_datetime($dt)

Formats the datetime in an ISO8601-compatible format. This differs from
L<DateTime/iso8601> by including nanoseconds/milliseconds and the correct
timezone offset.

=head1 FORMATS

There are 6 strings that can match against date only or time only formats. The
C<parse_datetime> method will attempt to match these ambiguous strings against
date only formats. If you want to match against the time only formats use the
C<parse_time> method.

=head2 Conventions

=over 4

=item * Expanded ISO8601

These formats are supported with exactly 6 digits for the year. Support for a
variable number of digits will be in a later release.

=item * Precision

If a format doesn't include a year all larger time unit up to and including the
year are filled in using the current date/time or [if set] the C<base_datetime>
object.

=item * Fractional time

There is no limit on the expressed precision.

=back

=head2 Supported via parse_datetime

The supported formats are listed by the section of ISO 8601:2000(E) in which
they appear.

=head3 5.2 Dates

=over 4

=item * 5.2.1.1

=over 8

=item YYYYMMDD

=item YYYY-MM-DD

=back

=item * 5.2.1.2

=over 8

=item YYYY-MM

=item YYYY

=item YY

=back

=item * 5.2.1.3

=over 8

=item YYMMDD

=item YY-MM-DD

=item -YYMM

=item -YY-MM

=item -YY

=item --MMDD

=item --MM-DD

=item --MM

=item ---DD

=back

=item * 5.2.1.4

=over 8

=item +[YY]YYYYMMDD

=item +[YY]YYYY-MM-DD

=item +[YY]YYYY-MM

=item +[YY]YYYY

=item +[YY]YY

=back

=item * 5.2.2.1

=over 8

=item YYYYDDD

=item YYYY-DDD

=back

=item * 5.2.2.2

=over 8

=item YYDDD

=item YY-DDD

=item -DDD

=back

=item * 5.2.2.3

=over 8

=item +[YY]YYYYDDD

=item +[YY]YYYY-DDD

=back

=item * 5.2.3.1

=over 8

=item YYYYWwwD

=item YYYY-Www-D

=back

=item * 5.2.3.2

=over 8

=item YYYYWww

=item YYYY-Www

=item YYWwwD

=item YY-Www-D

=item YYWww

=item YY-Www

=item -YWwwD

=item -Y-Www-D

=item -YWww

=item -Y-Www

=item -WwwD

=item -Www-D

=item -Www

=item -W-D

=back

=item * 5.2.3.4

=over 8

=item +[YY]YYYYWwwD

=item +[YY]YYYY-Www-D

=item +[YY]YYYYWww

=item +[YY]YYYY-Www

=back

=back

=head3 5.3 Time of Day

=over 4

=item * 5.3.1.1 - 5.3.1.3

Values can optionally be prefixed with 'T'.

=item * 5.3.1.1

=over 8

=item hh:mm:ss

=back

=item * 5.3.1.2

=over 8

=item hh:mm

=back

=item * 5.3.1.3 - 5.3.1.4

fractional (decimal) separator maybe either ',' or '.'

=item * 5.3.1.3

=over 8

=item hhmmss,ss

=item hh:mm:ss,ss

=item hhmm,mm

=item hh:mm,mm

=item hh,hh

=back

=item * 5.3.1.4

=over 8

=item -mm:ss

=item -mmss,s

=item -mm:ss,s

=item -mm,m

=item --ss,s

=back

=item * 5.3.3 - 5.3.4.2

Values can optionally be prefixed with 'T'.

=item * 5.3.3

=over 8

=item hhmmssZ

=item hh:mm:ssZ

=item hhmmZ

=item hh:mmZ

=item hhZ

=item hhmmss.ssZ

=item hh:mm:ss.ssZ

=back

=item * 5.3.4.2

=over 8

=item hhmmss[+-]hhmm

=item hh:mm:ss[+-]hh:mm

=item hhmmss[+-]hh

=item hh:mm:ss[+-]hh

=item hhmmss.ss[+-]hhmm

=item hh:mm:ss.ss[+-]hh:mm

=back

=back

=head3 5.4 Combinations of date and time of day

=over 4

=item * 5.4.1

=over 8

=item YYYYMMDDThhmmss

=item YYYY-MM-DDThh:mm:ss

=item YYYYMMDDThhmmssZ

=item YYYY-MM-DDThh:mm:ssZ

=item YYYYMMDDThhmmss[+-]hhmm

=item YYYY-MM-DDThh:mm:ss[+-]hh:mm

=item YYYYMMDDThhmmss[+-]hh

=item YYYY-MM-DDThh:mm:ss[+-]hh

=back

=item * 5.4.2

=over 8

=item YYYYMMDDThhmmss.ss

=item YYYY-MM-DDThh:mm:ss.ss

=item YYYYMMDDThhmmss.ss[+-]hh

=item YYYY-MM-DDThh:mm:ss.ss[+-]hh

=item YYYYMMDDThhmmss.ss[+-]hhmm

=item YYYY-MM-DDThh:mm:ss.ss[+-]hh:mm

=back

=item * 5.4.3

Support for this section is not complete.

=over 8

=item YYYYMMDDThhmm

=item YYYY-MM-DDThh:mm

=item YYYYMMDDThhmmZ

=item YYYY-MM-DDThh:mmZ

=item YYYYDDDThhmm

=item YYYY-DDDThh:mm

=item YYYYDDDThhmmZ

=item YYYY-DDDThh:mmZ

=item YYYYWwwDThhmm[+-]hhmm

=item YYYY-Www-DThh:mm[+-]hh

=back

=back

=head3 5.5 Time-Intervals

These are not currently supported

=head2 Supported via parse_time

=head3 5.3.1.1 - 5.3.1.3

Values can optionally be prefixed with 'T'.

=over 4

=item * 5.3.1.1

=over 8

=item hhmmss

=back

=item * 5.3.1.2

=over 8

=item hhmm

=item hh

=back

=item * 5.3.1.4

=over 8

=item -mmss

=item -mm

=item --ss

=back

=back

=head1 STANDARDS DOCUMENT

=head2 Title

    ISO8601:2000(E)
    Data elements and interchange formats - information exchange -
    Representation of dates and times
    Second edition 2000-12-15

=head2 Reference Number

    ISO/TC 154 N 362

=head1 CREDITS

Iain 'Spoon' Truskett (SPOON) who wrote L<DateTime::Format::Builder>. That has
grown into I<The Vacuum Energy Powered C<Swiss Army> Katana> of date and time
parsing. This module was inspired by and conceived in honor of Iain's work.

Tom Phoenix (PHOENIX) and PDX.pm for helping me solve the ISO week conversion
bug. Not by fixing the code but motivation me to fix it so I could participate
in a game of C<Zendo>.

Jonathan Leffler (JOHNL) for reporting a test bug.

Kelly McCauley for a patch to add 8 missing formats.

Alasdair Allan (AALLAN) for complaining about excessive test execution time.

Everyone at the DateTime C<Asylum>.

=head1 SEE ALSO

=over 4

=item *

L<DateTime>

=item *

L<DateTime::Format::Builder>

=back

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/DateTime-Format-ISO8601/issues>.

=head1 SOURCE

The source code repository for DateTime-Format-ISO8601 can be found at L<https://github.com/houseabsolute/DateTime-Format-ISO8601>.

=head1 AUTHORS

=over 4

=item *

Joshua Hoblitt <josh@hoblitt.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 CONTRIBUTORS

=for stopwords Doug Bell joe Liam Widdowson Thomas Klausner William Ricker

=over 4

=item *

Doug Bell <doug@preaction.me>

=item *

joe <draxil@gmail.com>

=item *

Liam Widdowson <lbw@telstra.com>

=item *

Thomas Klausner <domm@plix.at>

=item *

William Ricker <bill.n1vux@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Joshua Hoblitt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
