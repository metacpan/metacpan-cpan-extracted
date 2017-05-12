use strict;
use warnings;
use Test::More;
use Time::Local;
use Date::PeriodParser;
use POSIX qw( strftime );
require 't/helpers.pl';

# Tests for "this month" and "last month"

my %phrases = (
    'this month' => [
        [
            '2006-12-28T21:33:40',  # base
            '2006-12-01T00:00:00',   # expected from
            '2006-12-31T23:59:59',   # expected to
        ],
        [
            '2007-01-19T10:07:22',   # base
            '2007-01-01T00:00:00',   # expected from
            '2007-01-31T23:59:59',   # expected to
        ],
    ],
    'last month' => [
        [
            '2006-12-28T21:33:40',   # base
            '2006-11-01T00:00:00',   # expected from
            '2006-11-30T23:59:59',   # expected to
        ],
        [
            '2007-01-19T10:07:22',   # base
            '2006-12-01T00:00:00',   # expected from
            '2006-12-31T23:59:59',   # expected to
        ],
    ],
    'next month' => [
        [
            '2006-12-28T21:33:40',   # base
            '2007-01-01T00:00:00',   # expected from
            '2007-01-31T23:59:59',   # expected to
        ],
        [
            '2006-05-19T10:07:22',   # base
            '2006-06-01T00:00:00',   # expected from
            '2006-06-30T23:59:59',   # expected to
        ],
    ],
);

plan tests => 4 * 3;

while ( my ($phrase, $tests) = each %phrases ) {
    for my $test (@$tests) {
        my ($base, $right_from, $right_to) = @$test;
        set_time($base);

        my ( $from, $to ) = parse_period($phrase);
        is( iso($from), $right_from, "$phrase 'from' ok" );
        is( iso($to), $right_to, "$phrase 'to' ok" );
    }
}
