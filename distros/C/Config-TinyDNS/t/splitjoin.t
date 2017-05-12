#!/usr/bin/perl

use utf8;

use strict;
use warnings;

use Test::More;
use Test::Warn;

use Config::TinyDNS qw/split_tdns_data join_tdns_data/;
use Scalar::Util    qw/reftype/;

warnings_are {
    is_deeply [split_tdns_data(<<DATA)],
=one:1.2.3.4
+two:1.2.3.4:::lo
DATA
        [
            [qw/= one 1.2.3.4/],
            [qw/+ two 1.2.3.4/, "", "", "lo"],
        ], 
        "split_tdns_data splits by lines and colons";

    is_deeply [split_tdns_data(<<DATA)],
=one

=two


=three
DATA
        [[qw/= one/], [qw/= two/], [qw/= three/]],
        "...blank lines are ignored";

    is_deeply [split_tdns_data(<<DATA)],
=one:two:::
=one:two::three:::
DATA
        [
            ["=", "one", "two"],
            ["=", "one", "two", "", "three"],
        ],
        "...trailing blank fields are ignored";

    is_deeply [split_tdns_data(<<DATA)],
=one
# one
# one:two
# one:two:::
DATA
        [
            ["=", "one"],
            ["#", " one"],
            ["#", " one:two"],
            ["#", " one:two:::"],
        ],
        "...comments are kept but not split";

    is_deeply [split_tdns_data(<<DATA)],
=mÿdømaın:1.2.3.4
≠mydomain:1.2.3.4
DATA
        [
            ["=", "mÿdømaın", "1.2.3.4"],
            ["≠", "mydomain", "1.2.3.4"],
        ],
        "...utf8 is preserved";
} [], "no warnings so far";

warnings_are {

    is join_tdns_data(
            ["=", "dom", "1.2.3.4"],
            ["+", "dim", "1.2.3.4"],
        ), <<DATA,
=dom:1.2.3.4
+dim:1.2.3.4
DATA
        "lines are joined correctly";

    is join_tdns_data(
            ["=", "dom", "1.2.3.4", "", "", "ex"],
        ), <<DATA,
=dom:1.2.3.4:::ex
DATA
        "...non-trailing blank fields are preserved";

    is join_tdns_data(
            ["=", "dom", "1.2.3.4", "", "", ""],
        ), <<DATA,
=dom:1.2.3.4
DATA
        "...but trailing blanks are ignored";

    is join_tdns_data(["*"]), "*\n",
        "...just a special character";

    is join_tdns_data(
        ["=", "dom", "1.2.3.4"],
        [],
        ["+", "dim", "1.2.3.4"],
    ), <<DATA,
=dom:1.2.3.4

+dim:1.2.3.4
DATA
        "...blank lines are preserved";

    is join_tdns_data(
        ["=", "mÿdømaın", "1.2.3.4"],
        ["≠", "mydomain", "1.2.3.4"],
    ), <<DATA,
=mÿdømaın:1.2.3.4
≠mydomain:1.2.3.4
DATA
        "...utf8 is preserved";

} [], "no warnings";


done_testing;
