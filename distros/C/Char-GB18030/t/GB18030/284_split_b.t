# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use strict;
use GB18030;
print "1..56\n";

my $__FILE__ = __FILE__;

my @split = ();

@split = split(m/A/, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 1 split(m/A/, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 split(m/A/, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/i, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 2 split(m/a/i, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 split(m/a/i, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 3 split(m/A/, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 3 split(m/A/, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/i, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 4 split(m/a/i, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 split(m/a/i, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 5 split(m/傾/, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 5 split(m/傾/, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/i, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 6 split(m/傾/i, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 6 split(m/傾/i, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 7 split(m/僡/, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 7 split(m/僡/, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/i, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 8 split(m/僡/i, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 8 split(m/僡/i, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 9 split(m/傾/, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 9 split(m/傾/, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/i, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 10 split(m/傾/i, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 10 split(m/傾/i, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 11 split(m/僡/, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 11 split(m/僡/, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/i, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 12 split(m/僡/i, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 12 split(m/僡/i, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/, join('傾', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 13 split(m/A/, join('傾', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 13 split(m/A/, join('傾', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/i, join('傾', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 14 split(m/A/i, join('傾', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 14 split(m/A/i, join('傾', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/, join('傾', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 15 split(m/a/, join('傾', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 15 split(m/a/, join('傾', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/i, join('傾', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 16 split(m/a/i, join('傾', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 16 split(m/a/i, join('傾', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/, join('僡', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 17 split(m/A/, join('僡', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 17 split(m/A/, join('僡', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/i, join('僡', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 18 split(m/A/i, join('僡', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 18 split(m/A/i, join('僡', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/, join('僡', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 19 split(m/a/, join('僡', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 19 split(m/a/, join('僡', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/i, join('僡', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 20 split(m/a/i, join('僡', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 20 split(m/a/i, join('僡', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/, join('儍A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 21 split(m/傾/, join('儍A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 21 split(m/傾/, join('儍A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/i, join('儍A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 22 split(m/傾/i, join('儍A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 22 split(m/傾/i, join('儍A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/, join('儍A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 23 split(m/僡/, join('儍A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 23 split(m/僡/, join('儍A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/i, join('儍A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 24 split(m/僡/i, join('儍A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 24 split(m/僡/i, join('儍A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/, join('儍a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 25 split(m/傾/, join('儍a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 25 split(m/傾/, join('儍a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/i, join('儍a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 26 split(m/傾/i, join('儍a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 26 split(m/傾/i, join('儍a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/, join('儍a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 27 split(m/僡/, join('儍a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 27 split(m/僡/, join('儍a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/i, join('儍a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 28 split(m/僡/i, join('儍a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 28 split(m/僡/i, join('儍a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/b, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 29 split(m/A/b, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 29 split(m/A/b, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/b, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 30 split(m/A/b, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 30 split(m/A/b, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/b, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 31 split(m/傾/b, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 31 split(m/傾/b, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/b, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 32 split(m/僡/b, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 32 split(m/僡/b, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/b, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 33 split(m/傾/b, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 33 split(m/傾/b, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/b, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 34 split(m/僡/b, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 34 split(m/僡/b, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/b, join('傾', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 35 split(m/A/b, join('傾', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 35 split(m/A/b, join('傾', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/b, join('傾', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 36 split(m/a/b, join('傾', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 36 split(m/a/b, join('傾', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/b, join('僡', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 37 split(m/A/b, join('僡', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 37 split(m/A/b, join('僡', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/b, join('僡', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 38 split(m/a/b, join('僡', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 38 split(m/a/b, join('僡', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/b, join('儍A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 39 split(m/傾/b, join('儍A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 39 split(m/傾/b, join('儍A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/b, join('儍A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 40 split(m/僡/b, join('儍A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 40 split(m/僡/b, join('儍A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/b, join('儍a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 41 split(m/傾/b, join('儍a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 41 split(m/傾/b, join('儍a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/b, join('儍a', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 42 split(m/僡/b, join('儍a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 42 split(m/僡/b, join('儍a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/ib, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 43 split(m/a/ib, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 43 split(m/a/ib, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/ib, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 44 split(m/a/ib, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 44 split(m/a/ib, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/ib, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 45 split(m/傾/ib, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 45 split(m/傾/ib, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/ib, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 46 split(m/僡/ib, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 46 split(m/僡/ib, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/ib, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 47 split(m/傾/ib, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 47 split(m/傾/ib, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/ib, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 48 split(m/僡/ib, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 48 split(m/僡/ib, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/ib, join('傾', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 49 split(m/A/ib, join('傾', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 49 split(m/A/ib, join('傾', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/ib, join('傾', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 50 split(m/a/ib, join('傾', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 50 split(m/a/ib, join('傾', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/ib, join('僡', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 51 split(m/A/ib, join('僡', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 51 split(m/A/ib, join('僡', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/ib, join('僡', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 52 split(m/a/ib, join('僡', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 52 split(m/a/ib, join('僡', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/ib, join('儍A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 53 split(m/傾/ib, join('儍A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 53 split(m/傾/ib, join('儍A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/ib, join('儍A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 54 split(m/僡/ib, join('儍A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 54 split(m/僡/ib, join('儍A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/傾/ib, join('儍a', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 55 split(m/傾/ib, join('儍a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 55 split(m/傾/ib, join('儍a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/僡/ib, join('儍a', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 56 split(m/僡/ib, join('儍a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 56 split(m/僡/ib, join('儍a', 1..10)) $^X $__FILE__\n};
}

__END__

