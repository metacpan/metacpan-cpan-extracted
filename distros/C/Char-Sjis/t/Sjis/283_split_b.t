# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use strict;
use Sjis;
print "1..56\n";

my $__FILE__ = __FILE__;

my @split = ();

@split = split(/A/, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 1 split(/A/, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 split(/A/, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/i, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 2 split(/a/i, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 split(/a/i, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 3 split(/A/, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 3 split(/A/, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/i, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 4 split(/a/i, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 split(/a/i, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 5 split(/ア/, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 5 split(/ア/, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/i, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 6 split(/ア/i, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 6 split(/ア/i, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 7 split(/ヂ/, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 7 split(/ヂ/, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/i, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 8 split(/ヂ/i, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 8 split(/ヂ/i, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 9 split(/ア/, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 9 split(/ア/, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/i, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 10 split(/ア/i, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 10 split(/ア/i, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 11 split(/ヂ/, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 11 split(/ヂ/, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/i, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 12 split(/ヂ/i, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 12 split(/ヂ/i, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/, join('ア', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 13 split(/A/, join('ア', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 13 split(/A/, join('ア', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/i, join('ア', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 14 split(/A/i, join('ア', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 14 split(/A/i, join('ア', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/, join('ア', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 15 split(/a/, join('ア', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 15 split(/a/, join('ア', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/i, join('ア', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 16 split(/a/i, join('ア', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 16 split(/a/i, join('ア', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/, join('ヂ', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 17 split(/A/, join('ヂ', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 17 split(/A/, join('ヂ', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/i, join('ヂ', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 18 split(/A/i, join('ヂ', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 18 split(/A/i, join('ヂ', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/, join('ヂ', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 19 split(/a/, join('ヂ', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 19 split(/a/, join('ヂ', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/i, join('ヂ', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 20 split(/a/i, join('ヂ', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 20 split(/a/i, join('ヂ', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/, join('ャA', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 21 split(/ア/, join('ャA', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 21 split(/ア/, join('ャA', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/i, join('ャA', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 22 split(/ア/i, join('ャA', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 22 split(/ア/i, join('ャA', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/, join('ャA', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 23 split(/ヂ/, join('ャA', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 23 split(/ヂ/, join('ャA', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/i, join('ャA', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 24 split(/ヂ/i, join('ャA', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 24 split(/ヂ/i, join('ャA', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/, join('ャa', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 25 split(/ア/, join('ャa', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 25 split(/ア/, join('ャa', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/i, join('ャa', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 26 split(/ア/i, join('ャa', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 26 split(/ア/i, join('ャa', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/, join('ャa', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 27 split(/ヂ/, join('ャa', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 27 split(/ヂ/, join('ャa', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/i, join('ャa', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 28 split(/ヂ/i, join('ャa', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 28 split(/ヂ/i, join('ャa', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/b, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 29 split(/A/b, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 29 split(/A/b, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/b, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 30 split(/A/b, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 30 split(/A/b, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/b, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 31 split(/ア/b, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 31 split(/ア/b, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/b, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 32 split(/ヂ/b, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 32 split(/ヂ/b, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/b, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 33 split(/ア/b, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 33 split(/ア/b, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/b, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 34 split(/ヂ/b, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 34 split(/ヂ/b, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/b, join('ア', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 35 split(/A/b, join('ア', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 35 split(/A/b, join('ア', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/b, join('ア', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 36 split(/a/b, join('ア', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 36 split(/a/b, join('ア', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/b, join('ヂ', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 37 split(/A/b, join('ヂ', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 37 split(/A/b, join('ヂ', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/b, join('ヂ', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 38 split(/a/b, join('ヂ', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 38 split(/a/b, join('ヂ', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/b, join('ャA', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 39 split(/ア/b, join('ャA', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 39 split(/ア/b, join('ャA', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/b, join('ャA', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 40 split(/ヂ/b, join('ャA', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 40 split(/ヂ/b, join('ャA', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/b, join('ャa', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 41 split(/ア/b, join('ャa', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 41 split(/ア/b, join('ャa', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/b, join('ャa', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 42 split(/ヂ/b, join('ャa', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 42 split(/ヂ/b, join('ャa', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/ib, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 43 split(/a/ib, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 43 split(/a/ib, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/ib, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 44 split(/a/ib, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 44 split(/a/ib, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/ib, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 45 split(/ア/ib, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 45 split(/ア/ib, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/ib, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 46 split(/ヂ/ib, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 46 split(/ヂ/ib, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/ib, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 47 split(/ア/ib, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 47 split(/ア/ib, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/ib, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 48 split(/ヂ/ib, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 48 split(/ヂ/ib, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/ib, join('ア', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 49 split(/A/ib, join('ア', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 49 split(/A/ib, join('ア', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/ib, join('ア', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 50 split(/a/ib, join('ア', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 50 split(/a/ib, join('ア', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/ib, join('ヂ', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 51 split(/A/ib, join('ヂ', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 51 split(/A/ib, join('ヂ', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/ib, join('ヂ', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 52 split(/a/ib, join('ヂ', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 52 split(/a/ib, join('ヂ', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/ib, join('ャA', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 53 split(/ア/ib, join('ャA', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 53 split(/ア/ib, join('ャA', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/ib, join('ャA', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 54 split(/ヂ/ib, join('ャA', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 54 split(/ヂ/ib, join('ャA', 1..10)) $^X $__FILE__\n};
}

@split = split(/ア/ib, join('ャa', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 55 split(/ア/ib, join('ャa', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 55 split(/ア/ib, join('ャa', 1..10)) $^X $__FILE__\n};
}

@split = split(/ヂ/ib, join('ャa', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 56 split(/ヂ/ib, join('ャa', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 56 split(/ヂ/ib, join('ャa', 1..10)) $^X $__FILE__\n};
}

__END__

