#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG );
    use utf8;
    use version;
    use Test::More;
    use DBD::SQLite;
    if( version->parse( $DBD::SQLite::sqlite_version ) < version->parse( '3.6.19' ) )
    {
        plan skip_all => 'SQLite driver version 3.6.19 or higher is required. You have version ' . $DBD::SQLite::sqlite_version;
    }
    use DateTime;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'DateTime::Format::Unicode' ) || BAIL_OUT( 'Unable to load DateTime::Format::Unicode' );
};

use strict;
use warnings;
use utf8;


my $tests = 
[
    # NOTE: hour
    {
        locale => 'en',
        name => 'hour',
        tests => [
            {
                d1 => { year => 2024, month => 1, day => 1, hour => 22, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'Bh',
                expects => '10 – 11 at night',
            },
        ],
    },
    {
        locale => 'ja',
        name => 'hour',
        tests => [
            {
                d1 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 1, hour => 5, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'Bh',
                expects => '夜中4時～朝5時',
            },
        ],
    },
    {
        locale => 'ko',
        name => 'hour',
        tests => [
            {
                d1 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 1, hour => 5, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'Bh',
                expects => '아침 4시~5시',
            },
        ],
    },
    # NOTE: minute
    {
        locale => 'en',
        name => 'minute',
        tests => [
            {
                d1 => { year => 2024, month => 1, day => 1, hour => 14, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 1, hour => 14, minute => 10, second => 0, time_zone => 'UTC' },
                pattern => 'Bhm',
                expects => '2:00 – 2:10 in the afternoon',
            },
        ],
    },
    {
        locale => 'ja',
        name => 'minute',
        tests => [
            {
                d1 => { year => 2024, month => 1, day => 1, hour => 14, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 1, hour => 14, minute => 10, second => 0, time_zone => 'UTC' },
                pattern => 'Bhm',
                expects => '昼2:00～2:10',
            },
        ],
    },
    {
        locale => 'ko',
        name => 'minute',
        tests => [
            {
                d1 => { year => 2024, month => 1, day => 1, hour => 14, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 1, hour => 14, minute => 10, second => 0, time_zone => 'UTC' },
                pattern => 'Bhm',
                expects => '오후 2:00 ~ 2:10',
            },
        ],
    },
    # NOTE: era
    {
        locale => 'en',
        name => 'era',
        tests => [
            {
                d1 => { year => -2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'GyMEd',
                expects => 'Thu, 1/1/-2024 BC – Mon, 1/1/2024 AD',
            },
        ],
    },
    {
        locale => 'ja',
        name => 'era',
        tests => [
            {
                d1 => { year => -2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'GyMEd',
                expects => '紀元前-2024/01/01(木)～西暦2024/01/01(月)',
            },
        ],
    },
    {
        locale => 'ko',
        name => 'era',
        tests => [
            {
                d1 => { year => -2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'GyMEd',
                expects => 'BC -2024년 1월 1일 목요일 ~ AD 2024년 1월 1일 월요일',
            },
        ],
    },
    # NOTE: year
    {
        locale => 'en',
        name => 'year',
        tests => [
            {
                d1 => { year => 2023, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'GyMEd',
                expects => 'Sun, 1/1/2023 – Mon, 1/1/2024 AD',
            },
        ],
    },
    {
        locale => 'ja',
        name => 'year',
        tests => [
            {
                d1 => { year => 2023, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'GyMMMEd',
                expects => '西暦2023年1月1日(日)～2024年1月1日(月)',
            },
        ],
    },
    {
        locale => 'ko',
        name => 'year',
        tests => [
            {
                d1 => { year => 2023, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'GyMMMEd',
                expects => 'AD 2023년 1월 1일 일요일 ~ 2024년 1월 1일 월요일',
            },
        ],
    },
    # NOTE: month
    {
        locale => 'en',
        name => 'month',
        tests => [
            {
                d1 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 2, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'GyMEd',
                expects => 'Mon, 1/1/2024 – Thu, 2/1/2024 AD',
            },
        ],
    },
    {
        locale => 'ja',
        name => 'month',
        tests => [
            {
                d1 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 2, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'MMMEd',
                expects => '1月1日(月)～2月1日(木)',
            },
        ],
    },
    {
        locale => 'ko',
        name => 'month',
        tests => [
            {
                d1 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 2, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'MMMEd',
                expects => '1월 1일 (월) ~ 2월 1일 (목)',
            },
        ],
    },
    # NOTE: day
    {
        locale => 'en',
        name => 'day',
        tests => [
            {
                d1 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 10, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'GyMEd',
                expects => 'Mon, 1/1/2024 – Wed, 1/10/2024 AD',
            },
        ],
    },
    {
        locale => 'ja',
        name => 'day',
        tests => [
            {
                d1 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 10, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'd',
                expects => '1日～10日',
            },
        ],
    },
    {
        locale => 'ko',
        name => 'day',
        tests => [
            {
                d1 => { year => 2024, month => 1, day => 1, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                d2 => { year => 2024, month => 1, day => 10, hour => 4, minute => 0, second => 0, time_zone => 'UTC' },
                pattern => 'd',
                expects => '1일~10일',
            },
        ],
    },
];

foreach my $test ( @$tests )
{
    subtest 'interval for ' . $test->{name} . ' with locale ' . $test->{locale} => sub
    {
        my $fmt = DateTime::Format::Unicode->new( locale => $test->{locale} ) ||
            diag( "Error instantiating a new DateTime::Format::Unicode object: ", DateTime::Format::Unicode->error );
        isa_ok( $fmt => 'DateTime::Format::Unicode' );
        local $@;
        foreach my $def ( @{$test->{tests}} )
        {
            # try-catch
            my $dt1 = eval{ DateTime->new( %{$def->{d1}} ); };
            if( $@ )
            {
                diag( "Error instantiating the 1st DateTime object: $@" );
            }
            my $dt2 = eval{ DateTime->new( %{$def->{d2}} ); };
            if( $@ )
            {
                diag( "Error instantiating the 2nd DateTime object: $@" );
            }
            isa_ok( $dt1 => 'DateTime' );
            isa_ok( $dt2 => 'DateTime' );
            # $fmt->pattern( $def->{pattern} );
            my $str = $fmt->format_interval( $dt1, $dt2, pattern => $def->{pattern} );
            if( !defined( $str ) )
            {
                diag( "Error calling format_interval() with datetime1 ", $dt1->iso8601, " and datetime2 ", $dt2->iso8601, ": ", $fmt->error );
            }
            is( $str => $def->{expects}, "[$test->{locale} / $def->{pattern} ($test->{name} interval)] format_datetime( " . $dt1->iso8601 . ", " . $dt2->iso8601 . " ) " . ' with time zone ' . $dt1->time_zone_long_name . " -> '" . ( $def->{expects} // 'undef' ) . "'" );
        }
    };
}

done_testing();

__END__
