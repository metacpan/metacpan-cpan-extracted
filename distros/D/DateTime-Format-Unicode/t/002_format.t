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
    # NOTE: a (AM/PM)
    {
        locale => 'en',
        name => 'AM/PM',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'a',
                expects => 'AM',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aa',
                expects => 'AM',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaa',
                expects => 'AM',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaaa',
                expects => 'AM',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaaaa',
                expects => 'a',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'a',
                expects => 'PM',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aa',
                expects => 'PM',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaa',
                expects => 'PM',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaaa',
                expects => 'PM',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaaaa',
                expects => 'p',
            },
        ],
    },
    {
        locale => 'en-CA',
        name => 'AM/PM',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'a',
                expects => 'a.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aa',
                expects => 'a.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaa',
                expects => 'a.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaaa',
                expects => 'a.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaaaa',
                expects => 'am',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'a',
                expects => 'p.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aa',
                expects => 'p.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaa',
                expects => 'p.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaaa',
                expects => 'p.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaaaa',
                expects => 'pm',
            },
        ],
    },
    {
        locale => 'fr-CA',
        name => 'AM/PM',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'a',
                expects => 'a.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aa',
                expects => 'a.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaa',
                expects => 'a.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaaa',
                expects => 'a.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaaaa',
                expects => 'a',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'a',
                expects => 'p.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aa',
                expects => 'p.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaa',
                expects => 'p.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaaa',
                expects => 'p.m.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'aaaaa',
                expects => 'p',
            },
        ],
    },
    {
        locale => 'fr',
        name => 'AM/PM',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'a',
                expects => '',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 16, minute => 10, second => 10, time_zone => 'GMT' },
                pattern => 'a',
                expects => '',
            },
        ],
    },
    # NOTE: A (day seconds)
    {
        locale => 'en',
        name => 'day seconds',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 4, minute => 10, second => 10, nanosecond => 69540000, time_zone => 'GMT' },
                pattern => 'A',
                expects => '15010069',
            },
        ],
    },
    # NOTE: b (period stand-alone)
    {
        locale => 'en',
        name => 'period stand-alone',
        tests => [
            # Abbreviated
            # midnight
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'b',
                expects => 'midnight',
            },
            # night1
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'b',
                expects => 'night',
            },
            # morning1
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'b',
                expects => 'morning',
            },
            # noon
            {
                data => { year => 2024, month => 1, day => 1, hour => 12, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'b',
                expects => 'noon',
            },
            # afternoon1
            {
                data => { year => 2024, month => 1, day => 1, hour => 14, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'b',
                expects => 'afternoon',
            },
            # evening1
            {
                data => { year => 2024, month => 1, day => 1, hour => 19, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'b',
                expects => 'evening',
            },
            # Wide
            # midnight
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'bbbb',
                expects => 'midnight',
            },
            # night1
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'bbbb',
                expects => 'night',
            },
            # morning1
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'bbbb',
                expects => 'morning',
            },
            # noon
            {
                data => { year => 2024, month => 1, day => 1, hour => 12, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'bbbb',
                expects => 'noon',
            },
            # afternoon1
            {
                data => { year => 2024, month => 1, day => 1, hour => 14, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'bbbb',
                expects => 'afternoon',
            },
            # evening1
            {
                data => { year => 2024, month => 1, day => 1, hour => 19, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'bbbb',
                expects => 'evening',
            },
            # Narrow
            # midnight
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'bbbbb',
                expects => 'midnight',
            },
            # night1
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'bbbbb',
                expects => 'night',
            },
            # morning1
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'bbbbb',
                expects => 'morning',
            },
            # noon
            {
                data => { year => 2024, month => 1, day => 1, hour => 12, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'bbbbb',
                expects => 'noon',
            },
            # afternoon1
            {
                data => { year => 2024, month => 1, day => 1, hour => 14, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'bbbbb',
                expects => 'afternoon',
            },
            # evening1
            {
                data => { year => 2024, month => 1, day => 1, hour => 19, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'bbbbb',
                expects => 'evening',
            },
        ],
    },
    # NOTE: B (period format)
    {
        locale => 'en',
        name => 'period format',
        tests => [
            # Abbreviated
            # midnight
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => 'midnight',
            },
            # night1
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => 'at night',
            },
            # morning1
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => 'in the morning',
            },
            # noon
            {
                data => { year => 2024, month => 1, day => 1, hour => 12, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => 'noon',
            },
            # afternoon1
            {
                data => { year => 2024, month => 1, day => 1, hour => 14, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => 'in the afternoon',
            },
            # evening1
            {
                data => { year => 2024, month => 1, day => 1, hour => 19, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => 'in the evening',
            },
            # Wide
            # midnight
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'BBBB',
                expects => 'midnight',
            },
            # night1
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'BBBB',
                expects => 'at night',
            },
            # morning1
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'BBBB',
                expects => 'in the morning',
            },
            # noon
            {
                data => { year => 2024, month => 1, day => 1, hour => 12, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'BBBB',
                expects => 'noon',
            },
            # afternoon1
            {
                data => { year => 2024, month => 1, day => 1, hour => 14, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'BBBB',
                expects => 'in the afternoon',
            },
            # evening1
            {
                data => { year => 2024, month => 1, day => 1, hour => 19, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'BBBB',
                expects => 'in the evening',
            },
            # Narrow
            # midnight
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'BBBBB',
                expects => 'mi',
            },
            # night1
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'BBBBB',
                expects => 'at night',
            },
            # morning1
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'BBBBB',
                expects => 'in the morning',
            },
            # noon
            {
                data => { year => 2024, month => 1, day => 1, hour => 12, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'BBBBB',
                expects => 'n',
            },
            # afternoon1
            {
                data => { year => 2024, month => 1, day => 1, hour => 14, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'BBBBB',
                expects => 'in the afternoon',
            },
            # evening1
            {
                data => { year => 2024, month => 1, day => 1, hour => 19, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'BBBBB',
                expects => 'in the evening',
            },
        ],
    },
    {
        locale => 'ja',
        name => 'period format',
        tests => [
            # Abbreviated
            # midnight
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '真夜中',
            },
            # night1
            {
                data => { year => 2024, month => 1, day => 1, hour => 22, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '夜',
            },
            # night2
            {
                data => { year => 2024, month => 1, day => 1, hour => 3, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '夜中',
            },
            # morning1
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '朝',
            },
            # noon
            {
                data => { year => 2024, month => 1, day => 1, hour => 12, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '正午',
            },
            # afternoon1
            {
                data => { year => 2024, month => 1, day => 1, hour => 14, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '昼',
            },
            # evening1
            {
                data => { year => 2024, month => 1, day => 1, hour => 18, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '夕方',
            },
            # Wide (same as abbreviated)
            # midnight
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '真夜中',
            },
            # night1
            {
                data => { year => 2024, month => 1, day => 1, hour => 22, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '夜',
            },
            # night2
            {
                data => { year => 2024, month => 1, day => 1, hour => 3, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '夜中',
            },
            # morning1
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '朝',
            },
            # noon
            {
                data => { year => 2024, month => 1, day => 1, hour => 12, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '正午',
            },
            # afternoon1
            {
                data => { year => 2024, month => 1, day => 1, hour => 14, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '昼',
            },
            # evening1
            {
                data => { year => 2024, month => 1, day => 1, hour => 18, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '夕方',
            },
            # Narrow (same as abbreviated)
            # midnight
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '真夜中',
            },
            # night1
            {
                data => { year => 2024, month => 1, day => 1, hour => 22, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '夜',
            },
            # night2
            {
                data => { year => 2024, month => 1, day => 1, hour => 3, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '夜中',
            },
            # morning1
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '朝',
            },
            # noon
            {
                data => { year => 2024, month => 1, day => 1, hour => 12, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '正午',
            },
            # afternoon1
            {
                data => { year => 2024, month => 1, day => 1, hour => 14, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '昼',
            },
            # evening1
            {
                data => { year => 2024, month => 1, day => 1, hour => 18, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'B',
                expects => '夕方',
            },
        ],
    },
    # NOTE: c (week day)
    {
        locale => 'en',
        name => 'week day',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'c',
                # Monday
                expects => 1,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'cc',
                # Monday
                expects => '01',
            },
            # Abbreviated
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'ccc',
                # Monday
                expects => 'Mon',
            },
            # Wide
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'cccc',
                # Monday
                expects => 'Monday',
            },
            # Narrow
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'ccccc',
                # Monday
                expects => 'M',
            },
            # Short
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'cccccc',
                # Monday
                expects => 'Mo',
            },
        ],
    },
    # NOTE: C (preferred allowed time format)
    {
        locale => 'en',
        name => 'preferred allowed time format',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                # Numeric hour (minimum digits), abbreviated dayPeriod if used
                pattern => 'C',
                expects => 7,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                # Numeric hour (2 digits, zero pad if needed), abbreviated dayPeriod if used
                pattern => 'CC',
                expects => '07',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                # 7 in the morning
                # Numeric hour (minimum digits), wide dayPeriod if used
                pattern => 'CCC',
                expects => 7,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'CCCC',
                # 07 in the morning
                # Numeric hour (2 digits, zero pad if needed), wide dayPeriod if used
                # expects => '07 in the morning',
                expects => '07',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                # 7
                # Numeric hour (minimum digits), narrow dayPeriod if used
                pattern => 'CCCCC',
                expects => 7,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                # 08
                # Numeric hour (2 digits, zero pad if needed), narrow dayPeriod if used
                pattern => 'CCCCCC',
                expects => '07',
            },
        ],
    },
    {
        locale => 'en-TW',
        name => 'preferred allowed time format',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                # Numeric hour (minimum digits), abbreviated dayPeriod if used
                pattern => 'C',
                expects => '7 in the morning',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                # Numeric hour (2 digits, zero pad if needed), abbreviated dayPeriod if used
                pattern => 'CC',
                expects => '07 in the morning',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                # 7 in the morning
                # Numeric hour (minimum digits), wide dayPeriod if used
                pattern => 'CCC',
                expects => '7 in the morning',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'CCCC',
                # 07 in the morning
                # Numeric hour (2 digits, zero pad if needed), wide dayPeriod if used
                # expects => '07 in the morning',
                expects => '07 in the morning',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                # 7
                # Numeric hour (minimum digits), narrow dayPeriod if used
                pattern => 'CCCCC',
                expects => '7 in the morning',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                # 08
                # Numeric hour (2 digits, zero pad if needed), narrow dayPeriod if used
                pattern => 'CCCCCC',
                expects => '07 in the morning',
            },
        ],
    },
    # NOTE: d (day)
    # Day of month (numeric)
    {
        locale => 'en',
        name => 'day of month',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'd',
                expects => 1,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'dd',
                expects => '01',
            },
        ],
    },
    # NOTE: D (day of year)
    # Day of year (numeric)
    {
        locale => 'en',
        name => 'day of year',
        tests => [
            {
                data => { year => 2024, month => 1, day => 31, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'D',
                expects => 31,
            },
            {
                data => { year => 2024, month => 1, day => 31, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'DD',
                expects => 31,
            },
            {
                data => { year => 2024, month => 1, day => 31, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'DDD',
                expects => '031',
            },
            {
                data => { year => 2024, month => 8, day => 31, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'DDD',
                expects => '244',
            },
        ],
    },
    # NOTE: e (week day)
    # Local day of week number/name
    {
        locale => 'en',
        name => 'day of week',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'e',
                # Monday
                expects => 2,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'ee',
                expects => '02',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eee',
                # Abbreviated
                expects => 'Mon',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eeee',
                # Wide
                expects => 'Monday',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eeeee',
                # Narrow
                expects => 'M',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eeeeee',
                # Short
                expects => 'Mo',
            },
        ],
    },
    {
        locale => 'en-GB',
        name => 'day of week',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'e',
                # Monday
                expects => 1,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'ee',
                expects => '01',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eee',
                # Abbreviated
                expects => 'Mon',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eeee',
                # Wide
                expects => 'Monday',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eeeee',
                # Narrow
                expects => 'M',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eeeeee',
                # Short
                expects => 'Mo',
            },
        ],
    },
    {
        locale => 'ja',
        name => 'day of week',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'e',
                # Monday
                expects => 2,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'ee',
                expects => '02',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eee',
                # Abbreviated
                expects => '月',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eeee',
                # Wide
                expects => '月曜日',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eeeee',
                # Narrow
                expects => '月',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eeeeee',
                # Short
                expects => '月',
            },
        ],
    },
    {
        locale => 'fr',
        name => 'day of week',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'e',
                # Monday
                expects => 1,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'ee',
                expects => '01',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eee',
                # Abbreviated
                expects => 'lun.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eeee',
                # Wide
                expects => 'lundi',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eeeee',
                # Narrow
                expects => 'lu',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'eeeeee',
                # Short
                expects => 'lu',
            },
        ],
    },
    # NOTE: E (week day)
    # Day of week name, format style.
    {
        locale => 'en',
        name => 'day of week name',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'E',
                # Abbreviated
                expects => 'Mon',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'EE',
                # Abbreviated
                expects => 'Mon',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'EEE',
                # Abbreviated
                expects => 'Mon',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'EEEE',
                # Wide
                expects => 'Monday',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'EEEEE',
                # Narrow
                expects => 'M',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'EEEEEE',
                # Short
                expects => 'Mo',
            },
        ],
    },
    # NOTE: F (day of week in month)
    # Day of Week in Month (numeric)
    {
        locale => 'en',
        name => 'day of week in month',
        tests => [
            {
                data => { year => 2024, month => 1, day => 15, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'F',
                # 2024/1/15 is the 3rd Monday of the month
                expects => 3,
            },
        ],
    },
    # NOTE: g (Julian day)
    # Modified Julian day (numeric)
    {
        locale => 'en',
        name => 'Julian day',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'g',
                expects => 60310,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'gggggg',
                expects => '060310',
            },
        ],
    },
    # NOTE: G (era)
    # Era name
    {
        locale => 'en',
        name => 'era name',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'G',
                # Abbreviated
                expects => 'AD',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'GG',
                # Abbreviated
                expects => 'AD',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'GGG',
                # Abbreviated
                expects => 'AD',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'GGGG',
                # Wide
                expects => 'Anno Domini',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'GGGGG',
                # Narrow
                expects => 'A',
            },
        ],
    },
    {
        locale => 'ja',
        name => 'era name',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'G',
                # Abbreviated
                expects => '西暦',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'GG',
                # Abbreviated
                expects => '西暦',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'GGG',
                # Abbreviated
                expects => '西暦',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'GGGG',
                # Wide
                expects => '西暦',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'GGGGG',
                # Narrow
                expects => 'AD',
            },
        ],
    },
    # NOTE: h (hour)
    # Hour [1-12]
    {
        locale => 'en',
        name => 'hour [1-12]',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'h',
                expects => 7,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'hh',
                expects => '07',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'h',
                expects => 12,
            },
        ],
    },
    # NOTE: H (hour)
    # Hour [0-23]
    {
        locale => 'en',
        name => 'hour [0-23]',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'H',
                expects => 7,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'HH',
                expects => '07',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'H',
                expects => 23,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'H',
                expects => 0,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'HH',
                expects => '00',
            },
        ],
    },
    # NOTE: j (preferred hour format)
    {
        locale => 'en',
        name => 'preferred hour format',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'j',
                expects => 7,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'jj',
                expects => '07',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'jjj',
                expects => 11,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'jjjj',
                expects => '12',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'jjjjj',
                expects => 7,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'jjjjjj',
                expects => '07',
            },
        ],
    },
    # NOTE: J (preferred hour format)
    {
        locale => 'en',
        name => 'preferred hour format',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'J',
                expects => 7,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'JJ',
                expects => '07',
            },
        ],
    },
    # NOTE: k (hour)
    # Hour [1-24]
    {
        locale => 'en',
        name => 'hour [1-24]',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'k',
                expects => 7,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'kk',
                expects => '07',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'k',
                expects => 23,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'k',
                expects => 24,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'kk',
                expects => '24',
            },
        ],
    },
    # NOTE: K (hour)
    # Hour [1-24]
    {
        locale => 'en',
        name => 'hour [0-11]',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'K',
                expects => 7,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'KK',
                expects => '07',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'K',
                expects => 11,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'K',
                expects => 0,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'KK',
                expects => '00',
            },
        ],
    },
    # NOTE: L (month)
    # Stand-Alone month number/name
    {
        locale => 'en',
        name => 'month stand-alone',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'L',
                # Numeric: minimum digits
                expects => 1,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'LL',
                # Numeric: 2 digits, zero pad if needed
                expects => '01',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'LLL',
                # Abbreviated
                expects => 'Jan',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'LLLL',
                # Wide
                expects => 'January',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'LLLLL',
                # Narrow
                expects => 'J',
            },
        ],
    },
    # NOTE: M (month)
    # Numeric: minimum digits
    {
        locale => 'en',
        name => 'month minimum digits',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'M',
                expects => 1,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'MM',
                # Numeric: 2 digits, zero pad if needed
                expects => '01',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'MMM',
                # Abbreviated
                expects => 'Jan',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'MMMM',
                # Wide
                expects => 'January',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 23, minute => 0, second => 0, time_zone => 'GMT' },
                pattern => 'MMMMM',
                # Narrow
                expects => 'J',
            },
        ],
    },
    # NOTE: m (minute)
    # Minute (numeric). Truncated, not rounded
    {
        locale => 'en',
        name => 'minute numeric',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 0, time_zone => 'GMT' },
                pattern => 'm',
                # Numeric: minimum digits
                expects => 12,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'mm',
                # Numeric: 2 digits, zero pad if needed
                expects => '07',
            },
        ],
    },
    # NOTE: O (zone)
    {
        locale => 'en',
        name => 'GMT time zone',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 0, time_zone => 'Asia/Tokyo' },
                pattern => 'O',
                # short localized GMT format
                expects => 'GMT+9',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'Asia/Tokyo' },
                pattern => 'OOOO',
                # long localized GMT format
                expects => 'GMT+09:00',
            },
        ],
    },
    # NOTE: q (quarter)
    # Stand-Alone Quarter number/name
    {
        locale => 'en',
        name => 'quarter stand-alone',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 0, time_zone => 'GMT' },
                pattern => 'q',
                # Numeric: 1 digit
                expects => 1,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qq',
                # Numeric: 2 digits + zero pad
                expects => '01',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qqq',
                # Abbreviated
                expects => 'Q1',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qqqq',
                # Wide
                expects => '1st quarter',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qqqqq',
                # Narrow
                expects => 1,
            },
        ],
    },
    {
        locale => 'ja',
        name => 'quarter stand-alone',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 0, time_zone => 'GMT' },
                pattern => 'q',
                # Numeric: 1 digit
                expects => 1,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qq',
                # Numeric: 2 digits + zero pad
                expects => '01',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qqq',
                # Abbreviated
                expects => 'Q1',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qqqq',
                # Wide
                expects => '第1四半期',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qqqqq',
                # Narrow
                expects => 'Q1',
            },
        ],
    },
    {
        locale => 'fr',
        name => 'quarter stand-alone',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 0, time_zone => 'GMT' },
                pattern => 'q',
                # Numeric: 1 digit
                expects => 1,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qq',
                # Numeric: 2 digits + zero pad
                expects => '01',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qqq',
                # Abbreviated
                expects => 'T1',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qqqq',
                # Wide
                expects => '1er trimestre',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qqqqq',
                # Narrow
                expects => 'T1',
            },
        ],
    },
    # NOTE: Q (quarter)
    # Quarter number/name
    {
        locale => 'en',
        name => 'quarter stand-alone',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 0, time_zone => 'GMT' },
                pattern => 'q',
                # Numeric: 1 digit
                expects => 1,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qq',
                # Numeric: 2 digits + zero pad
                expects => '01',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qqq',
                # Abbreviated
                expects => 'Q1',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qqqq',
                # Wide
                expects => '1st quarter',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'qqqqq',
                # Narrow
                expects => 1,
            },
        ],
    },
    # NOTE: r (related year)
    # Related Gregorian year (numeric)
    {
        locale => 'en',
        name => 'related Gregorian year',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 0, time_zone => 'GMT' },
                pattern => 'r',
                # Numeric: 1 digit
                expects => 2024,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'rr',
                # Numeric: 2 digits + zero pad
                expects => '2024',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 0, time_zone => 'GMT' },
                pattern => 'rrrrr',
                # Abbreviated
                expects => '02024',
            },
        ],
    },
    # NOTE: s (second)
    # Second (numeric). Truncated, not rounded
    {
        locale => 'en',
        name => 'second',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'GMT' },
                pattern => 's',
                # Numeric: 1 digit
                expects => 10,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 7, time_zone => 'GMT' },
                pattern => 'ss',
                # Numeric: 2 digits + zero pad
                expects => '07',
            },
        ],
    },
    # NOTE: S (second)
    # Fractional Second (numeric)
    {
        locale => 'en',
        name => 'fractional second',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, nanosecond => 34567, time_zone => 'GMT' },
                pattern => 'S',
                # Numeric: 1 digit
                expects => 3,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 7, nanosecond => 34567, time_zone => 'GMT' },
                pattern => 'SS',
                # Numeric: 2 digits + zero pad
                expects => 34,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 7, nanosecond => 34567, time_zone => 'GMT' },
                pattern => 'SSSS',
                # Numeric: 2 digits + zero pad
                expects => 3456,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 7, second => 7, nanosecond => 34567, time_zone => 'GMT' },
                pattern => 'SSSSSSSSSS',
                # Numeric: 2 digits + zero pad
                expects => 3456700000,
            },
        ],
    },
    # NOTE: u (year)
    # Extended year (numeric)
    {
        locale => 'en',
        name => 'extended year',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'GMT' },
                pattern => 'u',
                expects => 2024,
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'GMT' },
                pattern => 'uu',
                expects => 2024,
            },
        ],
    },
    # NOTE: U (cyclic year)
    # Cyclic year name
    {
        locale => 'en',
        name => 'cyclic year',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'GMT' },
                pattern => 'U',
                # Abbreviated
                expects => 'AD',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'GMT' },
                pattern => 'UUUU',
                # Wide
                expects => 'Anno Domini',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'GMT' },
                pattern => 'UUUUU',
                # Narrow
                expects => 'A',
            },
        ],
    },
    {
        locale => 'ja',
        name => 'cyclic year',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'GMT' },
                pattern => 'U',
                # Abbreviated
                expects => '西暦',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'GMT' },
                pattern => 'UUUU',
                # Wide
                expects => '西暦',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'GMT' },
                pattern => 'UUUUU',
                # Narrow
                expects => 'AD',
            },
        ],
    },
    {
        locale => 'fr',
        name => 'cyclic year',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'GMT' },
                pattern => 'U',
                # Abbreviated
                expects => 'ap. J.-C.',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'GMT' },
                pattern => 'UUUU',
                # Wide
                expects => 'après Jésus-Christ',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'GMT' },
                pattern => 'UUUUU',
                # Narrow
                expects => 'ap. J.-C.',
            },
        ],
    },
    # NOTE: v (zone)
    # Time zone
    {
        locale => 'en',
        name => 'time zone',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'America/Los_Angeles' },
                pattern => 'v',
                # short generic non-location format, or 
                # generic location format ("VVVV"), or
                # short localized GMT format
                expects => 'PT',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'America/Los_Angeles' },
                pattern => 'vvvv',
                # long generic non-location format, or
                # generic location format ("VVVV")
                expects => 'Pacific Time',
            },
        ],
    },
    # NOTE: V (zone)
    # Time zone
    {
        locale => 'en',
        name => 'time zone',
        tests => [
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'America/Los_Angeles' },
                pattern => 'V',
                # The short time zone ID.
                # Where that is unavailable, the special short time zone ID unk (Unknown Zone) is used.
                expects => 'uslax',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'America/Los_Angeles' },
                pattern => 'VV',
                # The long time zone ID.
                expects => 'America/Los_Angeles',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'America/Los_Angeles' },
                pattern => 'VVV',
                # The exemplar city (location) for the time zone.
                # Where that is unavailable, the localized exemplar city name for the special zone Etc/Unknown is used as the fallback (for example, "Unknown City").
                expects => 'Los Angeles',
            },
            {
                data => { year => 2024, month => 1, day => 1, hour => 7, minute => 12, second => 10, time_zone => 'America/Los_Angeles' },
                pattern => 'VVVV',
                # The generic location format.
                # Where that is unavailable, falls back to the long localized GMT format
                expects => 'Los Angeles Time',
            },
        ],
    },
    # NOTE: w (week of year)
    {
        locale => 'en',
        name => 'week of year',
        tests => [
            {
                data => { year => 2024, month => 1, day => 8, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'w',
                expects => 2,
            },
            {
                data => { year => 2024, month => 1, day => 8, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'ww',
                expects => '02',
            },
            {
                data => { year => 2024, month => 3, day => 25, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'w',
                expects => 13,
            },
            {
                data => { year => 2024, month => 3, day => 25, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'ww',
                expects => 13,
            },
        ],
    },
    # NOTE: W (week of month)
    {
        locale => 'en',
        name => 'week of month',
        tests => [
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'W',
                expects => 2,
            },
        ],
    },
    # NOTE: x (zone)
    {
        locale => 'en',
        name => 'zone',
        tests => [
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'x',
                expects => '+09',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'America/St_Johns' },
                pattern => 'x',
                expects => '-0230',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'xx',
                expects => '+0900',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'xx',
                expects => '+0000',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'xxx',
                expects => '+09:00',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'xxx',
                expects => '+00:00',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'xxxx',
                expects => '+0900',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'xxxx',
                expects => '+0000',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'xxxxx',
                expects => '+09:00',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'xxxxx',
                expects => '+00:00',
            },
        ],
    },
    # NOTE: X (zone)
    {
        locale => 'en',
        name => 'zone',
        tests => [
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'X',
                expects => '+09',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'America/St_Johns' },
                pattern => 'X',
                expects => '-0230',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'X',
                expects => 'Z',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'XX',
                expects => '+0900',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'XX',
                expects => 'Z',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'XXX',
                expects => '+09:00',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'XXX',
                expects => 'Z',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'XXXX',
                expects => '+0900',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'XXXX',
                expects => 'Z',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'XXXXX',
                expects => '+09:00',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'XXXXX',
                expects => 'Z',
            },
        ],
    },
    # NOTE: y (Calendar year numeric)
    {
        locale => 'en',
        name => 'calendar year numeric',
        tests => [
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'y',
                expects => '2024',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'yy',
                expects => '24',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'yyy',
                expects => '2024',
            },
            {
                data => { year => 2, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'yyy',
                expects => '002',
            },
            {
                data => { year => 20, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'yyy',
                expects => '020',
            },
            {
                data => { year => 603, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'yyy',
                expects => '603',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'yyyy',
                expects => '2024',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'yyyyy',
                expects => '02024',
            },
        ],
    },
    # NOTE: Y (Week of Year)
    {
        locale => 'en',
        name => 'calendar year numeric',
        tests => [
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'Y',
                expects => '2024',
            },
        ],
    },
    # NOTE: z (zone)
    {
        locale => 'en',
        name => 'zone',
        tests => [
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'z',
                expects => 'Japan (Tokyo)',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'zz',
                expects => 'Japan (Tokyo)',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'zzz',
                expects => 'Japan (Tokyo)',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'zzzz',
                expects => 'Japan Standard Time',
            },
        ],
    },
    # NOTE: Z (zone)
    {
        locale => 'en',
        name => 'zone',
        tests => [
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'Z',
                expects => '+0900',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'ZZ',
                expects => '+0900',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'ZZZ',
                expects => '+0900',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'ZZZZ',
                expects => 'GMT+09:00',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'ZZZZZ',
                expects => '+09:00',
            },
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'ZZZZZ',
                expects => 'Z',
            },
        ],
    },
    {
        locale => 'cs',
        name => 'zone',
        tests => [
            {
                data => { year => 2024, month => 9, day => 9, hour => 7, minute => 12, second => 10, time_zone => 'Asia/Tokyo' },
                pattern => 'ZZZZ',
                expects => 'GMT+9:00',
            },
        ],
    },
    {
        locale => 'ar-SA',
        name => 'localised digits',
        tests => [
            {
                data => { year => 2024, month => 9, day => 10, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'd/M/y',
                expects => '١٠/٩/٢٠٢٤',
            },
        ],
    },
    {
        locale => 'ar-SA-u-nu-latn',
        name => 'localised digits',
        tests => [
            {
                data => { year => 2024, month => 9, day => 10, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'd/M/y',
                expects => '10/9/2024',
            },
        ],
    },
    {
        locale => 'fa-IR',
        name => 'localised digits',
        tests => [
            {
                data => { year => 2024, month => 9, day => 10, hour => 7, minute => 12, second => 10, time_zone => 'UTC' },
                pattern => 'y/M/d',
                expects => '۲۰۲۴/۹/۱۰',
            },
        ],
    },
];

foreach my $test ( @$tests )
{
    subtest $test->{name} . ' with locale ' . $test->{locale} => sub
    {
        my $fmt = DateTime::Format::Unicode->new( locale => $test->{locale} ) ||
            diag( "Error instantiating a new DateTime::Format::Unicode object: ", DateTime::Format::Unicode->error );
        isa_ok( $fmt => 'DateTime::Format::Unicode' );
        local $@;
        foreach my $def ( @{$test->{tests}} )
        {
            # try-catch
            my $dt = eval{ DateTime->new( %{$def->{data}} ); };
            if( $@ )
            {
                diag( "Error instantiating a DateTime object: $@" );
            }
            isa_ok( $dt => 'DateTime' );
            $fmt->pattern( $def->{pattern} );
            my $str = $fmt->format_datetime( $dt );
            if( !defined( $str ) )
            {
                diag( "Error calling format_datetime() with datetime ", $dt->iso8601, ": ", $fmt->error );
            }
            is( $str => $def->{expects}, "[$test->{locale} / $def->{pattern}] format_datetime( " . $dt->iso8601 . " ) " . ' with time zone ' . $dt->time_zone_long_name . " -> '" . ( $def->{expects} // 'undef' ) . "'" );
        }
    };
}

done_testing();

__END__
