use strict;
use warnings;
use Test::More;
use Time::Local;
use Date::PeriodParser;
use POSIX qw( strftime );
require 't/helpers.pl';

# Tests for "january 2007", etc

my %phrases = (
    'january 2007' => [
        [
            '2007-03-01T09:23:07',   # base
            '2007-01-01T00:00:00',   # expected from
            '2007-01-31T23:59:59',   # expected to
        ],
        [
            '2007-01-01T10:07:22',   # base
            '2007-01-01T00:00:00',   # expected from
            '2007-01-31T23:59:59',   # expected to
        ],
        [
            '2006-11-23T10:47:58',   # base
            '2007-01-01T00:00:00',   # expected from
            '2007-01-31T23:59:59',   # expected to
        ],
    ],
    'jan 2007' => [
        [
            '2007-03-01T09:23:07',   # base
            '2007-01-01T00:00:00',   # expected from
            '2007-01-31T23:59:59',   # expected to
        ],
        [
            '2007-01-01T10:07:22',   # base
            '2007-01-01T00:00:00',   # expected from
            '2007-01-31T23:59:59',   # expected to
        ],
        [
            '2006-11-23T10:47:58',   # base
            '2007-01-01T00:00:00',   # expected from
            '2007-01-31T23:59:59',   # expected to
        ],
    ],
    'february 1993' => [
        [
            '2007-03-01T09:23:07',   # base
            '1993-02-01T00:00:00',   # expected from
            '1993-02-28T23:59:59',   # expected to
        ],
        [
            '2007-01-01T10:07:22',   # base
            '1993-02-01T00:00:00',   # expected from
            '1993-02-28T23:59:59',   # expected to
        ],
        [
            '2006-11-23T10:47:58',   # base
            '1993-02-01T00:00:00',   # expected from
            '1993-02-28T23:59:59',   # expected to
        ],
    ],
    'feb 1993' => [
        [
            '2007-03-01T09:23:07',   # base
            '1993-02-01T00:00:00',   # expected from
            '1993-02-28T23:59:59',   # expected to
        ],
        [
            '2007-01-01T10:07:22',   # base
            '1993-02-01T00:00:00',   # expected from
            '1993-02-28T23:59:59',   # expected to
        ],
        [
            '2006-11-23T10:47:58',   # base
            '1993-02-01T00:00:00',   # expected from
            '1993-02-28T23:59:59',   # expected to
        ],
    ],
    'febr 1993' => [
        [
            '2007-03-01T09:23:07',   # base
            '1993-02-01T00:00:00',   # expected from
            '1993-02-28T23:59:59',   # expected to
        ],
        [
            '2007-01-01T10:07:22',   # base
            '1993-02-01T00:00:00',   # expected from
            '1993-02-28T23:59:59',   # expected to
        ],
        [
            '2006-11-23T10:47:58',   # base
            '1993-02-01T00:00:00',   # expected from
            '1993-02-28T23:59:59',   # expected to
        ],
    ],
);

plan tests => 2 * 15;

while ( my ($phrase, $tests) = each %phrases ) {
    for my $test (@$tests) {
        my ($base, $right_from, $right_to) = @$test;
        set_time($base);

        my ( $from, $to ) = parse_period($phrase);
        is( iso($from), $right_from, "$phrase 'from' ok" );
        is( iso($to), $right_to, "$phrase 'to' ok" );
    }
}
