use strict;
use warnings;

use Test2::V0;

use DateTime::Format::ISO8601;

my $base_year  = 2000;
my $base_month = '01';
my $base_dt    = DateTime->new( year => $base_year, month => $base_month );
my $default_expect_datetime = '1985-04-12T10:15:30';

my @tests = (
    [qw( YYYYMMDDThhmmss 19850412T101530 )],
    [qw( YYYY-MM-DDThh:mm:ss 1985-04-12T10:15:30 )],
    [
        qw( YYYYMMDDThhmmss.ss 19850412T101530.5 ),
        { nanosecond => 500_000_000 }
    ],
    [
        qw( YYYY-MM-DDThh:mm:ss.ss 1985-04-12T10:15:30.5 ),
        { nanosecond => 500_000_000 }
    ],
    [ qw ( YYYYMMDDThhmmssZ 19850412T101530Z ), { time_zone => 'UTC' } ],
    [
        qw( YYYY-MM-DDThh:mm:ssZ 1985-04-12T10:15:30Z ),
        { time_zone => 'UTC' }
    ],
    [
        qw( YYYYMMDDThhmmss.ssZ 19850412T101530.5Z ),
        {
            nanosecond => 500_000_000,
            time_zone  => 'UTC',
        }
    ],
    [
        qw(  YYYY-MM-DDThh:mm:ss.ssZ 1985-04-12T10:15:30.5Z ),
        {
            nanosecond => 500_000_000,
            time_zone  => 'UTC',
        }
    ],
    [
        qw( YYYYMMDDThhmmss+hhmm 19850412T101530+0400 ),
        { time_zone => '+0400' }
    ],
    [
        qw( YYYY-MM-DDThh:mm+hh:mm 1985-04-12T10:15+04:00 1985-04-12T10:15:00 ),
        { time_zone => '+0400' }
    ],
    [
        qw( YYYY-MM-DDThh:mm+hh:mm 1985-04-12T10:15-04:00 1985-04-12T10:15:00 ),
        { time_zone => '-0400' }
    ],
    [
        qw( YYYYMMDDThhmm+hhmm 19850412T1015+0400 1985-04-12T10:15:00 ),
        { time_zone => '+0400' }
    ],
    [
        qw( YYYYMMDDThhmm+hhmm 19850412T1015-0400 1985-04-12T10:15:00 ),
        { time_zone => '-0400' }
    ],
    [
        qw( YYYY-MM-DDThh:mm:ss+hh:mm 1985-04-12T10:15:30+04:00 ),
        { time_zone => '+0400' }
    ],
    [
        qw( YYYY-MM-DDThh:mm:ss.ss+hh 1985-04-12T10:15:30.5+04 ),
        {
            nanosecond => 500_000_000,
            time_zone  => '+0400',
        }
    ],
    [
        qw( YYYYMMDDThhmmss.ss+hh 19850412T101530.5+04 ),
        {
            nanosecond => 500_000_000,
            time_zone  => '+0400',
        }
    ],
    [
        qw( YYYYMMDDThhmmss.ss+hhmm 19850412T101530.5+0400 ),
        {
            nanosecond => 500_000_000,
            time_zone  => '+0400',
        }
    ],
    [
        qw( YYYY-MM-DDThh:mm:ss.ss+hh:mm 1985-04-12T10:15:30.5+04:00 ),
        {
            nanosecond => 500_000_000,
            time_zone  => '+0400',
        }
    ],
    [ qw( YYYYMMDDThhmmss+hh 19850412T101530+04 ), { time_zone => '+0400' } ],
    [
        qw( YYYY-MM-DDThh:mm:ss+hh 1985-04-12T10:15:30+04 ),
        { time_zone => '+0400' }
    ],
    [qw( YYYYMMDDThhmm 19850412T1015 1985-04-12T10:15:00 )],
    [qw( YYYY-MM-DDThh:mm 1985-04-12T10:15 1985-04-12T10:15:00 )],
    [qw( YYYYMMDDThhmmZ 19850412T1015Z 1985-04-12T10:15:00 )],
    [qw( YYYY-MM-DDThh:mmZ 1985-04-12T10:15Z 1985-04-12T10:15:00 )],
    [qw( YYYYDDDThhmm 1985102T1015Z 1985-04-12T10:15:00 )],
    [qw( YYYY-DDDThh:mm 1985-102T10:15Z 1985-04-12T10:15:00 )],
    [
        qw( YYYYDDDThhmmZ 1985102T1015Z 1985-04-12T10:15:00 ),
        { time_zone => 'UTC' }
    ],
    [
        qw( YYYY-DDDThh:mmZ 1985-102T10:15Z 1985-04-12T10:15:00 ),
        { time_zone => 'UTC' }
    ],
    [
        qw( YYYYWwwDThhmm+hhmm 1985W155T1015+0400 1985-04-12T10:15:00 ),
        { time_zone => '+0400' }
    ],
    [
        qw( YYYY-Www-DThh:mm+hh 1985-W15-5T10:15+04 1985-04-12T10:15:00 ),
        { time_zone => '+0400' }
    ],
);

subtest(
    'datetime formats with base_datetime' => sub {
        my $iso8601
            = DateTime::Format::ISO8601->new( base_datetime => $base_dt );
        for my $t (@tests) {
            my @copy   = @{$t};
            my $format = shift @copy;
            subtest(
                $format => sub {
                    _test_time( $iso8601, @copy );
                }
            );
        }
    }
);

subtest(
    'datetime formats without base_datetime' => sub {
        my $epoch
            = DateTime->new( year => 2000, month => 1, time_zone => 'UTC' )
            ->epoch;

        ## no critic (Variables::ProtectPrivateVars)
        no warnings 'redefine';
        local *DateTime::_core_time = sub {$epoch};

        my $iso8601 = DateTime::Format::ISO8601->new;
        for my $parser ( $iso8601, 'DateTime::Format::ISO8601' ) {
            my $st = 'parse with ' . ( ref $parser ? 'object' : 'class' );
            subtest(
                $st,
                sub {
                    for my $t (@tests) {
                        my @copy   = @{$t};
                        my $format = shift @copy;
                        subtest(
                            $format => sub {
                                _test_time( $iso8601, @copy );
                            }
                        );
                    }
                }
            );
        }
    }
);

sub _test_time {
    my $parser   = shift;
    my $to_parse = shift;
    my @rest     = @_;

    my $expect = $default_expect_datetime;
    if ( @rest && !ref $rest[0] ) {
        $expect = shift @rest;
    }
    my $extra = shift @rest;

    my $dt = $parser->parse_datetime($to_parse);

    is(
        $dt->datetime,
        $expect,
        "$to_parse = $expect",
    );
    return unless $extra;

    if ( $extra->{nanosecond} ) {
        is(
            $dt->nanosecond,
            $extra->{nanosecond},
            "nanosecond = $extra->{nanosecond}",
        );
    }
    if ( $extra->{time_zone} ) {
        is(
            $dt->time_zone->name, $extra->{time_zone},
            "tz = $extra->{time_zone}"
        );
    }
}

done_testing();
