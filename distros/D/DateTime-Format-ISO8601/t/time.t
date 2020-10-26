use strict;
use warnings;

use Test2::V0;

use DateTime::Format::ISO8601;

my $base_year  = 2000;
my $base_month = '01';
my $base_dt    = DateTime->new( year => $base_year, month => $base_month );
my $default_expect_time = '23:20:50';

my %tests = (

    # These formats are unambiguous and are parsed as times by parse_datetime
    parse_datetime => [
        [qw( hh:mm:ss 23:20:50 )],
        [qw( hh:mm 23:20 23:20:00 )],
        [ 'hhmmss,ss',   '232050,5',   { nanosecond => 500_000_000 } ],
        [ 'hh:mm:ss,ss', '23:20:50,5', { nanosecond => 500_000_000 } ],
        [ 'hhmm,mm',     '2320,8',     '23:20:48' ],
        [ 'hh:mm,mm',    '23:20,8',    '23:20:48' ],
        [ 'hh,hh',       '23,3',       '23:18:00' ],
        [qw( -mm:ss -20:50 00:20:50 )],
        [ '-mmss,s',  '-2050,5',  '00:20:50', { nanosecond => 500_000_000 } ],
        [ '-mm:ss,s', '-20:50,5', '00:20:50', { nanosecond => 500_000_000 } ],
        [ '-mm,m',    '-20,8',    '00:20:48' ],
        [ '--ss,s',   '--50,5',   '00:00:50', { nanosecond => 500_000_000 } ],
        [ qw( hhmmssZ 232050Z ), { time_zone => 'UTC' } ],
        [
            qw( hhmmss.ssZ 232050.5Z ),
            {
                nanosecond => 500_000_000,
                time_zone  => 'UTC',
            }
        ],
        [qw( hh:mm:ssZ 23:20:50Z )],
        [
            qw( hhmmssZ 23:20:50.5Z ),
            {
                nanosecond => 500_000_000,
                time_zone  => 'UTC',
            }
        ],
        [ qw( hhmmZ 2320Z 23:20:00 ),   { time_zone => 'UTC' } ],
        [ qw( hh:mmZ 23:20Z 23:20:00 ), { time_zone => 'UTC' } ],
        [ qw( hhZ 23Z 23:00:00 ),       { time_zone => 'UTC' } ],
        [
            qw( hhmmss[+/-]hhmm 152746+0100 15:27:46 ),
            { time_zone => '+0100' }
        ],
        [
            qw( hhmmss[+/-]hhmm 152746-0500 15:27:46 ),
            { time_zone => '-0500' }
        ],
        [
            qw( hh:mm:ss[+/-]hhmm 15:27:46+01:00 15:27:46 ),
            { time_zone => '+0100' }
        ],
        [
            qw( hh:mm:ss[+/-]hhmm 15:27:46-05:00 15:27:46 ),
            { time_zone => '-0500' }
        ],
        [ qw( hhmmss[+/-]hh 152746+01 15:27:46 ), { time_zone => '+0100' } ],
        [ qw( hhmmss[+/-]hh 152746-05 15:27:46 ), { time_zone => '-0500' } ],
        [
            qw( hh:mm:ss[+/-]hh 15:27:46+01 15:27:46 ),
            { time_zone => '+0100' }
        ],
        [
            qw( hh:mm:ss[+/-]hh 15:27:46-05 15:27:46 ),
            { time_zone => '-0500' }
        ],
        [
            qw( hhmmss.ss[+/-]hhmm 152746.5+0100 15:27:46 ),
            {
                nano_second => 500_000_000,
                time_zone   => '+0100',
            }
        ],
        [
            qw( hhmmss.ss[+/-]hhmm 152746.5-0500 15:27:46 ),
            {
                nano_second => 500_000_000,
                time_zone   => '-0500',
            }
        ],
        [
            qw( hh:mm:ss.ss[+/-]hh:mm 15:27:46.5+01:00 15:27:46 ),
            {
                nano_second => 500_000_000,
                time_zone   => '+0100',
            }
        ],
        [
            qw( hh:mm:ss.ss[+/-]hh:mm 15:27:46.5-05:00 15:27:46 ),
            {
                nano_second => 500_000_000,
                time_zone   => '-0500',
            }
        ],
    ],

    # These formats are ambiguous and would be parsed as dates by parse_datetime.
    parse_time => [
        [qw( hhmmss 232050 )],
        [qw( hhmm 2320 23:20:00 )],
        [qw( hh 23 23:00:00 )],
        [qw( -mmss -2050 00:20:50 )],
        [qw( -mm -20 00:20:00 )],
        [qw( --ss --50 00:00:50 )],
    ],
);

subtest(
    'time formats with base_datetime' => sub {
        my $iso8601
            = DateTime::Format::ISO8601->new( base_datetime => $base_dt );
        for my $method ( sort keys %tests ) {
            for my $t ( @{ $tests{$method} } ) {
                my @copy   = @{$t};
                my $format = shift @copy;
                subtest(
                    $format => sub {
                        _test_time( $iso8601, $method, @copy );
                    }
                );
            }
        }
    }
);

subtest(
    'time formats without base_datetime' => sub {
        my $epoch
            = DateTime->new( year => 2000, month => 1, time_zone => 'UTC' )
            ->epoch;

        no warnings 'redefine';
        ## no critic (Variables::ProtectPrivateVars)
        local *DateTime::_core_time = sub {$epoch};

        my $iso8601 = DateTime::Format::ISO8601->new;
        for my $parser ( $iso8601, 'DateTime::Format::ISO8601' ) {
            my $st = 'parse with ' . ( ref $parser ? 'object' : 'class' );
            subtest(
                $st,
                sub {
                    for my $method ( sort keys %tests ) {
                        for my $t ( @{ $tests{$method} } ) {
                            my @copy   = @{$t};
                            my $format = shift @copy;
                            subtest(
                                $format => sub {
                                    _test_time( $iso8601, $method, @copy );
                                }
                            );
                        }
                    }
                }
            );
        }
    }
);

sub _test_time {
    my $parser   = shift;
    my $method   = shift;
    my $to_parse = shift;
    my @rest     = @_;

    my $expect = $default_expect_time;
    if ( @rest && !ref $rest[0] ) {
        $expect = shift @rest;
    }
    my $extra = shift @rest;

    my $dt = $parser->$method($to_parse);

    is(
        $dt->hms,
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
