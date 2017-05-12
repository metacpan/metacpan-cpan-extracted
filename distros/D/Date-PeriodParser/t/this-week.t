use strict;
use warnings;
use Test::More;
use Time::Local;
use Date::PeriodParser;
use POSIX qw( strftime );
require 't/helpers.pl';

# Tests for "this week" and "last week"

my %phrases = (
    'this week' => [
        [
            '2006-12-28T21:33:40',  # base
            '2006-12-25T00:00:00',   # expected from
            '2006-12-31T23:59:59',   # expected to
        ],
        [
            '2007-01-19T10:07:22',   # base
            '2007-01-15T00:00:00',   # expected from
            '2007-01-21T23:59:59',   # expected to
        ],
    ],
    'last week' => [
        [
            '2006-12-28T21:33:40',  # base
            '2006-12-18T00:00:00',   # expected from
            '2006-12-24T23:59:59',   # expected to
        ],
        [
            '2007-01-19T10:07:22',   # base
            '2007-01-08T00:00:00',   # expected from
            '2007-01-14T23:59:59',   # expected to
        ],
    ],
    'next week' => [
        [
            '2006-12-28T21:33:40',  # base
            '2007-01-01T00:00:00',   # expected from
            '2007-01-07T23:59:59',   # expected to
        ],
        [
            '2007-01-19T10:07:22',   # base
            '2007-01-22T00:00:00',   # expected from
            '2007-01-28T23:59:59',   # expected to
        ],
    ],
);

plan tests => 3 * 4;

while ( my ($phrase, $tests) = each %phrases ) {
    for my $test (@$tests) {
        my ($base, $right_from, $right_to) = @$test;
        set_time($base);

        my ( $from, $to ) = parse_period($phrase);
        is( iso($from), $right_from, "$phrase 'from' ok" );
        is( iso($to), $right_to, "$phrase 'to' ok" );
    }
}
