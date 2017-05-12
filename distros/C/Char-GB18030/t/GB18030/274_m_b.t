# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use strict;
use GB18030;
print "1..56\n";

my $__FILE__ = __FILE__;

if ('A' =~ /A/) {
    print qq{ok - 1 'A' =~ /A/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 'A' =~ /A/ $^X $__FILE__\n};
}

if ('A' =~ /A/b) {
    print qq{ok - 2 'A' =~ /A/b $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 'A' =~ /A/b $^X $__FILE__\n};
}

if ('A' =~ /a/i) {
    print qq{ok - 3 'A' =~ /a/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 'A' =~ /a/i $^X $__FILE__\n};
}

if ('A' =~ /a/ib) {
    print qq{ok - 4 'A' =~ /a/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 'A' =~ /a/ib $^X $__FILE__\n};
}

if ('a' =~ /A/) {
    print qq{not ok - 5 'a' =~ /A/ $^X $__FILE__\n};
}
else {
    print qq{ok - 5 'a' =~ /A/ $^X $__FILE__\n};
}

if ('a' =~ /A/b) {
    print qq{not ok - 6 'a' =~ /A/b $^X $__FILE__\n};
}
else {
    print qq{ok - 6 'a' =~ /A/b $^X $__FILE__\n};
}

if ('a' =~ /a/i) {
    print qq{ok - 7 'a' =~ /a/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 'a' =~ /a/i $^X $__FILE__\n};
}

if ('a' =~ /a/ib) {
    print qq{ok - 8 'a' =~ /a/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 'a' =~ /a/ib $^X $__FILE__\n};
}

if ('A' =~ /傾/) {
    print qq{not ok - 9 'A' =~ /傾/ $^X $__FILE__\n};
}
else {
    print qq{ok - 9 'A' =~ /傾/ $^X $__FILE__\n};
}

if ('A' =~ /傾/b) {
    print qq{not ok - 10 'A' =~ /傾/b $^X $__FILE__\n};
}
else {
    print qq{ok - 10 'A' =~ /傾/b $^X $__FILE__\n};
}

if ('A' =~ /傾/i) {
    print qq{not ok - 11 'A' =~ /傾/i $^X $__FILE__\n};
}
else {
    print qq{ok - 11 'A' =~ /傾/i $^X $__FILE__\n};
}

if ('A' =~ /傾/ib) {
    print qq{not ok - 12 'A' =~ /傾/ib $^X $__FILE__\n};
}
else {
    print qq{ok - 12 'A' =~ /傾/ib $^X $__FILE__\n};
}

if ('A' =~ /僡/) {
    print qq{not ok - 13 'A' =~ /僡/ $^X $__FILE__\n};
}
else {
    print qq{ok - 13 'A' =~ /僡/ $^X $__FILE__\n};
}

if ('A' =~ /僡/b) {
    print qq{not ok - 14 'A' =~ /僡/b $^X $__FILE__\n};
}
else {
    print qq{ok - 14 'A' =~ /僡/b $^X $__FILE__\n};
}

if ('A' =~ /僡/i) {
    print qq{not ok - 15 'A' =~ /僡/i $^X $__FILE__\n};
}
else {
    print qq{ok - 15 'A' =~ /僡/i $^X $__FILE__\n};
}

if ('A' =~ /僡/ib) {
    print qq{not ok - 16 'A' =~ /僡/ib $^X $__FILE__\n};
}
else {
    print qq{ok - 16 'A' =~ /僡/ib $^X $__FILE__\n};
}

if ('a' =~ /傾/) {
    print qq{not ok - 17 'a' =~ /傾/ $^X $__FILE__\n};
}
else {
    print qq{ok - 17 'a' =~ /傾/ $^X $__FILE__\n};
}

if ('a' =~ /傾/b) {
    print qq{not ok - 18 'a' =~ /傾/b $^X $__FILE__\n};
}
else {
    print qq{ok - 18 'a' =~ /傾/b $^X $__FILE__\n};
}

if ('a' =~ /傾/i) {
    print qq{not ok - 19 'a' =~ /傾/i $^X $__FILE__\n};
}
else {
    print qq{ok - 19 'a' =~ /傾/i $^X $__FILE__\n};
}

if ('a' =~ /傾/ib) {
    print qq{not ok - 20 'a' =~ /傾/ib $^X $__FILE__\n};
}
else {
    print qq{ok - 20 'a' =~ /傾/ib $^X $__FILE__\n};
}

if ('a' =~ /僡/) {
    print qq{not ok - 21 'a' =~ /僡/ $^X $__FILE__\n};
}
else {
    print qq{ok - 21 'a' =~ /僡/ $^X $__FILE__\n};
}

if ('a' =~ /僡/b) {
    print qq{not ok - 22 'a' =~ /僡/b $^X $__FILE__\n};
}
else {
    print qq{ok - 22 'a' =~ /僡/b $^X $__FILE__\n};
}

if ('a' =~ /僡/i) {
    print qq{not ok - 23 'a' =~ /僡/i $^X $__FILE__\n};
}
else {
    print qq{ok - 23 'a' =~ /僡/i $^X $__FILE__\n};
}

if ('a' =~ /僡/ib) {
    print qq{not ok - 24 'a' =~ /僡/ib $^X $__FILE__\n};
}
else {
    print qq{ok - 24 'a' =~ /僡/ib $^X $__FILE__\n};
}

if ('傾' =~ /A/) {
    print qq{not ok - 25 '傾' =~ /A/ $^X $__FILE__\n};
}
else {
    print qq{ok - 25 '傾' =~ /A/ $^X $__FILE__\n};
}

if ('傾' =~ /A/b) {
    print qq{ok - 26 '傾' =~ /A/b $^X $__FILE__\n};
}
else {
    print qq{not ok - 26 '傾' =~ /A/b $^X $__FILE__\n};
}

if ('傾' =~ /A/i) {
    print qq{not ok - 27 '傾' =~ /A/i $^X $__FILE__\n};
}
else {
    print qq{ok - 27 '傾' =~ /A/i $^X $__FILE__\n};
}

if ('傾' =~ /A/ib) {
    print qq{ok - 28 '傾' =~ /A/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 28 '傾' =~ /A/ib $^X $__FILE__\n};
}

if ('傾' =~ /a/) {
    print qq{not ok - 29 '傾' =~ /a/ $^X $__FILE__\n};
}
else {
    print qq{ok - 29 '傾' =~ /a/ $^X $__FILE__\n};
}

if ('傾' =~ /a/b) {
    print qq{not ok - 30 '傾' =~ /a/b $^X $__FILE__\n};
}
else {
    print qq{ok - 30 '傾' =~ /a/b $^X $__FILE__\n};
}

if ('傾' =~ /a/i) {
    print qq{not ok - 31 '傾' =~ /a/i $^X $__FILE__\n};
}
else {
    print qq{ok - 31 '傾' =~ /a/i $^X $__FILE__\n};
}

if ('傾' =~ /a/ib) {
    print qq{ok - 32 '傾' =~ /a/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 32 '傾' =~ /a/ib $^X $__FILE__\n};
}

if ('僡' =~ /A/) {
    print qq{not ok - 33 '僡' =~ /A/ $^X $__FILE__\n};
}
else {
    print qq{ok - 33 '僡' =~ /A/ $^X $__FILE__\n};
}

if ('僡' =~ /A/b) {
    print qq{not ok - 34 '僡' =~ /A/b $^X $__FILE__\n};
}
else {
    print qq{ok - 34 '僡' =~ /A/b $^X $__FILE__\n};
}

if ('僡' =~ /A/i) {
    print qq{not ok - 35 '僡' =~ /A/i $^X $__FILE__\n};
}
else {
    print qq{ok - 35 '僡' =~ /A/i $^X $__FILE__\n};
}

if ('僡' =~ /A/ib) {
    print qq{ok - 36 '僡' =~ /A/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 36 '僡' =~ /A/ib $^X $__FILE__\n};
}

if ('僡' =~ /a/) {
    print qq{not ok - 37 '僡' =~ /a/ $^X $__FILE__\n};
}
else {
    print qq{ok - 37 '僡' =~ /a/ $^X $__FILE__\n};
}

if ('僡' =~ /a/b) {
    print qq{ok - 38 '僡' =~ /a/b $^X $__FILE__\n};
}
else {
    print qq{not ok - 38 '僡' =~ /a/b $^X $__FILE__\n};
}

if ('僡' =~ /a/i) {
    print qq{not ok - 39 '僡' =~ /a/i $^X $__FILE__\n};
}
else {
    print qq{ok - 39 '僡' =~ /a/i $^X $__FILE__\n};
}

if ('僡' =~ /a/ib) {
    print qq{ok - 40 '僡' =~ /a/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 40 '僡' =~ /a/ib $^X $__FILE__\n};
}

if ('儍A' =~ /傾/) {
    print qq{not ok - 41 '儍A' =~ /傾/ $^X $__FILE__\n};
}
else {
    print qq{ok - 41 '儍A' =~ /傾/ $^X $__FILE__\n};
}

if ('儍A' =~ /傾/b) {
    print qq{ok - 42 '儍A' =~ /傾/b $^X $__FILE__\n};
}
else {
    print qq{not ok - 42 '儍A' =~ /傾/b $^X $__FILE__\n};
}

if ('儍A' =~ /傾/i) {
    print qq{not ok - 43 '儍A' =~ /傾/i $^X $__FILE__\n};
}
else {
    print qq{ok - 43 '儍A' =~ /傾/i $^X $__FILE__\n};
}

if ('儍A' =~ /傾/ib) {
    print qq{ok - 44 '儍A' =~ /傾/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 44 '儍A' =~ /傾/ib $^X $__FILE__\n};
}

if ('儍A' =~ /僡/) {
    print qq{not ok - 45 '儍A' =~ /僡/ $^X $__FILE__\n};
}
else {
    print qq{ok - 45 '儍A' =~ /僡/ $^X $__FILE__\n};
}

if ('儍A' =~ /僡/b) {
    print qq{not ok - 46 '儍A' =~ /僡/b $^X $__FILE__\n};
}
else {
    print qq{ok - 46 '儍A' =~ /僡/b $^X $__FILE__\n};
}

if ('儍A' =~ /僡/i) {
    print qq{not ok - 47 '儍A' =~ /僡/i $^X $__FILE__\n};
}
else {
    print qq{ok - 47 '儍A' =~ /僡/i $^X $__FILE__\n};
}

if ('儍A' =~ /僡/ib) {
    print qq{ok - 48 '儍A' =~ /僡/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 48 '儍A' =~ /僡/ib $^X $__FILE__\n};
}

if ('儍a' =~ /傾/) {
    print qq{not ok - 49 '儍a' =~ /傾/ $^X $__FILE__\n};
}
else {
    print qq{ok - 49 '儍a' =~ /傾/ $^X $__FILE__\n};
}

if ('儍a' =~ /傾/b) {
    print qq{not ok - 50 '儍a' =~ /傾/b $^X $__FILE__\n};
}
else {
    print qq{ok - 50 '儍a' =~ /傾/b $^X $__FILE__\n};
}

if ('儍a' =~ /傾/i) {
    print qq{not ok - 51 '儍a' =~ /傾/i $^X $__FILE__\n};
}
else {
    print qq{ok - 51 '儍a' =~ /傾/i $^X $__FILE__\n};
}

if ('儍a' =~ /傾/ib) {
    print qq{ok - 52 '儍a' =~ /傾/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 52 '儍a' =~ /傾/ib $^X $__FILE__\n};
}

if ('儍a' =~ /僡/) {
    print qq{not ok - 53 '儍a' =~ /僡/ $^X $__FILE__\n};
}
else {
    print qq{ok - 53 '儍a' =~ /僡/ $^X $__FILE__\n};
}

if ('儍a' =~ /僡/b) {
    print qq{ok - 54 '儍a' =~ /僡/b $^X $__FILE__\n};
}
else {
    print qq{not ok - 54 '儍a' =~ /僡/b $^X $__FILE__\n};
}

if ('儍a' =~ /僡/i) {
    print qq{not ok - 55 '儍a' =~ /僡/i $^X $__FILE__\n};
}
else {
    print qq{ok - 55 '儍a' =~ /僡/i $^X $__FILE__\n};
}

if ('儍a' =~ /僡/ib) {
    print qq{ok - 56 '儍a' =~ /僡/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 56 '儍a' =~ /僡/ib $^X $__FILE__\n};
}

__END__

