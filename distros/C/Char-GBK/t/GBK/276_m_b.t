# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use strict;
use GBK;
print "1..56\n";

my $__FILE__ = __FILE__;

if ('A' =~ m'A') {
    print qq{ok - 1 'A' =~ m'A' $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 'A' =~ m'A' $^X $__FILE__\n};
}

if ('A' =~ m'A'b) {
    print qq{ok - 2 'A' =~ m'A'b $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 'A' =~ m'A'b $^X $__FILE__\n};
}

if ('A' =~ m'a'i) {
    print qq{ok - 3 'A' =~ m'a'i $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 'A' =~ m'a'i $^X $__FILE__\n};
}

if ('A' =~ m'a'ib) {
    print qq{ok - 4 'A' =~ m'a'ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 'A' =~ m'a'ib $^X $__FILE__\n};
}

if ('a' =~ m'A') {
    print qq{not ok - 5 'a' =~ m'A' $^X $__FILE__\n};
}
else {
    print qq{ok - 5 'a' =~ m'A' $^X $__FILE__\n};
}

if ('a' =~ m'A'b) {
    print qq{not ok - 6 'a' =~ m'A'b $^X $__FILE__\n};
}
else {
    print qq{ok - 6 'a' =~ m'A'b $^X $__FILE__\n};
}

if ('a' =~ m'a'i) {
    print qq{ok - 7 'a' =~ m'a'i $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 'a' =~ m'a'i $^X $__FILE__\n};
}

if ('a' =~ m'a'ib) {
    print qq{ok - 8 'a' =~ m'a'ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 'a' =~ m'a'ib $^X $__FILE__\n};
}

if ('A' =~ m'傾') {
    print qq{not ok - 9 'A' =~ m'傾' $^X $__FILE__\n};
}
else {
    print qq{ok - 9 'A' =~ m'傾' $^X $__FILE__\n};
}

if ('A' =~ m'傾'b) {
    print qq{not ok - 10 'A' =~ m'傾'b $^X $__FILE__\n};
}
else {
    print qq{ok - 10 'A' =~ m'傾'b $^X $__FILE__\n};
}

if ('A' =~ m'傾'i) {
    print qq{not ok - 11 'A' =~ m'傾'i $^X $__FILE__\n};
}
else {
    print qq{ok - 11 'A' =~ m'傾'i $^X $__FILE__\n};
}

if ('A' =~ m'傾'ib) {
    print qq{not ok - 12 'A' =~ m'傾'ib $^X $__FILE__\n};
}
else {
    print qq{ok - 12 'A' =~ m'傾'ib $^X $__FILE__\n};
}

if ('A' =~ m'僡') {
    print qq{not ok - 13 'A' =~ m'僡' $^X $__FILE__\n};
}
else {
    print qq{ok - 13 'A' =~ m'僡' $^X $__FILE__\n};
}

if ('A' =~ m'僡'b) {
    print qq{not ok - 14 'A' =~ m'僡'b $^X $__FILE__\n};
}
else {
    print qq{ok - 14 'A' =~ m'僡'b $^X $__FILE__\n};
}

if ('A' =~ m'僡'i) {
    print qq{not ok - 15 'A' =~ m'僡'i $^X $__FILE__\n};
}
else {
    print qq{ok - 15 'A' =~ m'僡'i $^X $__FILE__\n};
}

if ('A' =~ m'僡'ib) {
    print qq{not ok - 16 'A' =~ m'僡'ib $^X $__FILE__\n};
}
else {
    print qq{ok - 16 'A' =~ m'僡'ib $^X $__FILE__\n};
}

if ('a' =~ m'傾') {
    print qq{not ok - 17 'a' =~ m'傾' $^X $__FILE__\n};
}
else {
    print qq{ok - 17 'a' =~ m'傾' $^X $__FILE__\n};
}

if ('a' =~ m'傾'b) {
    print qq{not ok - 18 'a' =~ m'傾'b $^X $__FILE__\n};
}
else {
    print qq{ok - 18 'a' =~ m'傾'b $^X $__FILE__\n};
}

if ('a' =~ m'傾'i) {
    print qq{not ok - 19 'a' =~ m'傾'i $^X $__FILE__\n};
}
else {
    print qq{ok - 19 'a' =~ m'傾'i $^X $__FILE__\n};
}

if ('a' =~ m'傾'ib) {
    print qq{not ok - 20 'a' =~ m'傾'ib $^X $__FILE__\n};
}
else {
    print qq{ok - 20 'a' =~ m'傾'ib $^X $__FILE__\n};
}

if ('a' =~ m'僡') {
    print qq{not ok - 21 'a' =~ m'僡' $^X $__FILE__\n};
}
else {
    print qq{ok - 21 'a' =~ m'僡' $^X $__FILE__\n};
}

if ('a' =~ m'僡'b) {
    print qq{not ok - 22 'a' =~ m'僡'b $^X $__FILE__\n};
}
else {
    print qq{ok - 22 'a' =~ m'僡'b $^X $__FILE__\n};
}

if ('a' =~ m'僡'i) {
    print qq{not ok - 23 'a' =~ m'僡'i $^X $__FILE__\n};
}
else {
    print qq{ok - 23 'a' =~ m'僡'i $^X $__FILE__\n};
}

if ('a' =~ m'僡'ib) {
    print qq{not ok - 24 'a' =~ m'僡'ib $^X $__FILE__\n};
}
else {
    print qq{ok - 24 'a' =~ m'僡'ib $^X $__FILE__\n};
}

if ('傾' =~ m'A') {
    print qq{not ok - 25 '傾' =~ m'A' $^X $__FILE__\n};
}
else {
    print qq{ok - 25 '傾' =~ m'A' $^X $__FILE__\n};
}

if ('傾' =~ m'A'b) {
    print qq{ok - 26 '傾' =~ m'A'b $^X $__FILE__\n};
}
else {
    print qq{not ok - 26 '傾' =~ m'A'b $^X $__FILE__\n};
}

if ('傾' =~ m'A'i) {
    print qq{not ok - 27 '傾' =~ m'A'i $^X $__FILE__\n};
}
else {
    print qq{ok - 27 '傾' =~ m'A'i $^X $__FILE__\n};
}

if ('傾' =~ m'A'ib) {
    print qq{ok - 28 '傾' =~ m'A'ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 28 '傾' =~ m'A'ib $^X $__FILE__\n};
}

if ('傾' =~ m'a') {
    print qq{not ok - 29 '傾' =~ m'a' $^X $__FILE__\n};
}
else {
    print qq{ok - 29 '傾' =~ m'a' $^X $__FILE__\n};
}

if ('傾' =~ m'a'b) {
    print qq{not ok - 30 '傾' =~ m'a'b $^X $__FILE__\n};
}
else {
    print qq{ok - 30 '傾' =~ m'a'b $^X $__FILE__\n};
}

if ('傾' =~ m'a'i) {
    print qq{not ok - 31 '傾' =~ m'a'i $^X $__FILE__\n};
}
else {
    print qq{ok - 31 '傾' =~ m'a'i $^X $__FILE__\n};
}

if ('傾' =~ m'a'ib) {
    print qq{ok - 32 '傾' =~ m'a'ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 32 '傾' =~ m'a'ib $^X $__FILE__\n};
}

if ('僡' =~ m'A') {
    print qq{not ok - 33 '僡' =~ m'A' $^X $__FILE__\n};
}
else {
    print qq{ok - 33 '僡' =~ m'A' $^X $__FILE__\n};
}

if ('僡' =~ m'A'b) {
    print qq{not ok - 34 '僡' =~ m'A'b $^X $__FILE__\n};
}
else {
    print qq{ok - 34 '僡' =~ m'A'b $^X $__FILE__\n};
}

if ('僡' =~ m'A'i) {
    print qq{not ok - 35 '僡' =~ m'A'i $^X $__FILE__\n};
}
else {
    print qq{ok - 35 '僡' =~ m'A'i $^X $__FILE__\n};
}

if ('僡' =~ m'A'ib) {
    print qq{ok - 36 '僡' =~ m'A'ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 36 '僡' =~ m'A'ib $^X $__FILE__\n};
}

if ('僡' =~ m'a') {
    print qq{not ok - 37 '僡' =~ m'a' $^X $__FILE__\n};
}
else {
    print qq{ok - 37 '僡' =~ m'a' $^X $__FILE__\n};
}

if ('僡' =~ m'a'b) {
    print qq{ok - 38 '僡' =~ m'a'b $^X $__FILE__\n};
}
else {
    print qq{not ok - 38 '僡' =~ m'a'b $^X $__FILE__\n};
}

if ('僡' =~ m'a'i) {
    print qq{not ok - 39 '僡' =~ m'a'i $^X $__FILE__\n};
}
else {
    print qq{ok - 39 '僡' =~ m'a'i $^X $__FILE__\n};
}

if ('僡' =~ m'a'ib) {
    print qq{ok - 40 '僡' =~ m'a'ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 40 '僡' =~ m'a'ib $^X $__FILE__\n};
}

if ('儍A' =~ m'傾') {
    print qq{not ok - 41 '儍A' =~ m'傾' $^X $__FILE__\n};
}
else {
    print qq{ok - 41 '儍A' =~ m'傾' $^X $__FILE__\n};
}

if ('儍A' =~ m'傾'b) {
    print qq{ok - 42 '儍A' =~ m'傾'b $^X $__FILE__\n};
}
else {
    print qq{not ok - 42 '儍A' =~ m'傾'b $^X $__FILE__\n};
}

if ('儍A' =~ m'傾'i) {
    print qq{not ok - 43 '儍A' =~ m'傾'i $^X $__FILE__\n};
}
else {
    print qq{ok - 43 '儍A' =~ m'傾'i $^X $__FILE__\n};
}

if ('儍A' =~ m'傾'ib) {
    print qq{ok - 44 '儍A' =~ m'傾'ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 44 '儍A' =~ m'傾'ib $^X $__FILE__\n};
}

if ('儍A' =~ m'僡') {
    print qq{not ok - 45 '儍A' =~ m'僡' $^X $__FILE__\n};
}
else {
    print qq{ok - 45 '儍A' =~ m'僡' $^X $__FILE__\n};
}

if ('儍A' =~ m'僡'b) {
    print qq{not ok - 46 '儍A' =~ m'僡'b $^X $__FILE__\n};
}
else {
    print qq{ok - 46 '儍A' =~ m'僡'b $^X $__FILE__\n};
}

if ('儍A' =~ m'僡'i) {
    print qq{not ok - 47 '儍A' =~ m'僡'i $^X $__FILE__\n};
}
else {
    print qq{ok - 47 '儍A' =~ m'僡'i $^X $__FILE__\n};
}

if ('儍A' =~ m'僡'ib) {
    print qq{ok - 48 '儍A' =~ m'僡'ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 48 '儍A' =~ m'僡'ib $^X $__FILE__\n};
}

if ('儍a' =~ m'傾') {
    print qq{not ok - 49 '儍a' =~ m'傾' $^X $__FILE__\n};
}
else {
    print qq{ok - 49 '儍a' =~ m'傾' $^X $__FILE__\n};
}

if ('儍a' =~ m'傾'b) {
    print qq{not ok - 50 '儍a' =~ m'傾'b $^X $__FILE__\n};
}
else {
    print qq{ok - 50 '儍a' =~ m'傾'b $^X $__FILE__\n};
}

if ('儍a' =~ m'傾'i) {
    print qq{not ok - 51 '儍a' =~ m'傾'i $^X $__FILE__\n};
}
else {
    print qq{ok - 51 '儍a' =~ m'傾'i $^X $__FILE__\n};
}

if ('儍a' =~ m'傾'ib) {
    print qq{ok - 52 '儍a' =~ m'傾'ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 52 '儍a' =~ m'傾'ib $^X $__FILE__\n};
}

if ('儍a' =~ m'僡') {
    print qq{not ok - 53 '儍a' =~ m'僡' $^X $__FILE__\n};
}
else {
    print qq{ok - 53 '儍a' =~ m'僡' $^X $__FILE__\n};
}

if ('儍a' =~ m'僡'b) {
    print qq{ok - 54 '儍a' =~ m'僡'b $^X $__FILE__\n};
}
else {
    print qq{not ok - 54 '儍a' =~ m'僡'b $^X $__FILE__\n};
}

if ('儍a' =~ m'僡'i) {
    print qq{not ok - 55 '儍a' =~ m'僡'i $^X $__FILE__\n};
}
else {
    print qq{ok - 55 '儍a' =~ m'僡'i $^X $__FILE__\n};
}

if ('儍a' =~ m'僡'ib) {
    print qq{ok - 56 '儍a' =~ m'僡'ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 56 '儍a' =~ m'僡'ib $^X $__FILE__\n};
}

__END__

