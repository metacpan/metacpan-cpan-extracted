#!perl

use 5.010;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Algorithm::History::Levels qw(group_histories_into_levels);

subtest "argument checks" => sub {
    dies_ok { group_histories_into_levels(levels=>[[86400,7]]) }
        "histories arg required";
    dies_ok { group_histories_into_levels(levels=>[[86400,7]], histories=>[1,2,1]) }
        "names must be unique (1)";
    dies_ok { group_histories_into_levels(levels=>[[86400,7]], histories=>[[1,1], [2,2], [1,3]]) }
        "names must be unique (2)";

    dies_ok { group_histories_into_levels(histories=>[]) }
        "levels arg required";
    dies_ok { group_histories_into_levels(histories=>[], levels=>[]) }
        "there must be at least 1 level";
    dies_ok { group_histories_into_levels(histories=>[], levels=>[[1]]) }
        "each level must be a 2-element array";
    dies_ok { group_histories_into_levels(histories=>[], levels=>[[100,3],[90,2]]) }
        "period must be monotonically increasing";
};

subtest "basics" => sub {
    my $now = time();
    is_deeply(
        group_histories_into_levels(
            histories=>[map {$now-$_*86400} 0..15],
            levels=>[[86400,7], [7*86400,4]],
        ),
        {
            levels => [
                [map {$now-$_*86400} 0..6],
                [map {$now-$_*86400} 7, 10, 12, 14],
            ],
            discard => [
                map {$now-$_*86400} 8, 9, 11, 13, 15
            ],
        },
        'histories as array of timestamps',
    );

    is_deeply(
        group_histories_into_levels(
            histories=>[map {[$_,$now-$_*86400]} 0..15],
            levels=>[[86400,7], [7*86400,4], [30*86400,3]],
        ),
        {
            levels => [
                [0..6],
                [7, 10, 12, 14],
                [9, 11, 13],
            ],
            discard => [
                8, 15,
            ],
        },
        'histories as array of [name,timestamp] pairs',
    );

    is_deeply(
        group_histories_into_levels(
            histories=>[map {[$_,$now-$_*86400]} 0, map {$_+1} 0..6, 7,10,12,14, 9,11,13],
            levels=>[[86400,7], [7*86400,4], [30*86400,3]],
        ),
        {
            levels => [
                [0..6],
                [7, 11, 13, 14],
                [10, 12, 15],
            ],
            discard => [
                8,
            ],
        },
        'day 2',
    );

    is_deeply(
        group_histories_into_levels(
            histories=>[map {[$_,$now-$_*86400]} 0..15],
            levels=>[[86400,7], [7*86400,4], [30*86400,3]],
            discard_young_histories => 1,
        ),
        {
            levels => [
                [0..6],
                [7, 14],
                [],
            ],
            discard => [
                8..13, 15,
            ],
        },
        "opt:discard_young_histories=1",
    );

    is_deeply(
        group_histories_into_levels(
            histories=>[map {[$_,$now-$_*86400]} 0..15, 200],
            levels=>[[86400,7], [7*86400,4], [30*86400,3]],
            discard_old_histories => 1,
        ),
        {
            levels => [
                [0..6],
                [7, 10, 12, 14],
                [9, 11, 13],
            ],
            discard => [
                8, 15, 200,
            ],
        },
        "opt:discard_old_histories=1",
    );

    is_deeply(
        group_histories_into_levels(
            histories=>[map {[$_,$now-$_*86400]} 0..15, 200],
            levels=>[[86400,7], [7*86400,4], [30*86400,3]],
            discard_young_histories => 1,
            discard_old_histories => 1,
        ),
        {
            levels => [
                [0..6],
                [7, 14],
                [],
            ],
            discard => [
                8..13, 15, 200,
            ],
        },
        "opt:discard_young_histories=1,discard_old_histories=1",
    );
};

DONE_TESTING:
done_testing;
