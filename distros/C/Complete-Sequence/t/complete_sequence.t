#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Complete::Sequence qw(complete_sequence);

# scalar, array
is_deeply(
    complete_sequence(word=>""   , sequence=>[ ["a","be"], [1..3], "x", [7..8] ]),
    ["a", "be"],
);
is_deeply(
    complete_sequence(word=>"c"  , sequence=>[ ["a","be"], [1..3], "x", [7..8] ]),
    [],
);

is_deeply(
    complete_sequence(word=>"a"  , sequence=>[ ["a","be"], [1..3], "x", [7..8] ]),
    ["a1", "a2", "a3"],
);
is_deeply(
    complete_sequence(word=>"b"  , sequence=>[ ["a","be"], [1..3], "x", [7..8] ]),
    ["be1", "be2", "be3"],
);

is_deeply(
    complete_sequence(word=>"be1" , sequence=>[ ["a","be"], [1..3], "x", [7..8] ]),
    ["be1x7", "be1x8"],
);

# coderef
is_deeply(
    complete_sequence(word=>""   , sequence=>[ sub{ ["a","be"] }, [1..3], "x", [7..8] ]),
    ["a", "be"],
);

# hash: subsequence
is_deeply(
    complete_sequence(word=>""   , sequence=>[ {sequence=>[ ["a","be"] ]}, [1..3], "x", [7..8] ]),
    ["a", "be"],
);
is_deeply(
    complete_sequence(word=>""   , sequence=>[ {sequence=>[ ["a","be"], [3..4] ]}, [1..3], "x", [7..8] ]),
    ["a3", "a4", "be3", "be4"],
);

# hash: alternative
is_deeply(
    complete_sequence(word=>""   , sequence=>[ {alternative=>[ ["a","be"], ["c","de"] ]}, [1..3], "x", [7..8] ]),
    ["a", "be", "c", "de"],
);

DONE_TESTING:
done_testing;
