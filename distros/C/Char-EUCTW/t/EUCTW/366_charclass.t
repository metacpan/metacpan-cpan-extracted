# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{丐} ne "\xa4\xa2";

my $__FILE__ = __FILE__;

use 5.00503;
use EUCTW;
print "1..344\n";

if ('P' =~ /[PQR]/) {
    print qq{ok - 1 'P' =~ /[PQR]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 'P' =~ /[PQR]/ $^X $__FILE__\n};
}

if ('R' =~ /[PQR]/) {
    print qq{ok - 2 'R' =~ /[PQR]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 'R' =~ /[PQR]/ $^X $__FILE__\n};
}

if ('O' !~ /[PQR]/) {
    print qq{ok - 3 'O' !~ /[PQR]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 'O' !~ /[PQR]/ $^X $__FILE__\n};
}

if ('S' !~ /[PQR]/) {
    print qq{ok - 4 'S' !~ /[PQR]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 'S' !~ /[PQR]/ $^X $__FILE__\n};
}

if ('P' =~ /[\x50\x51\x52]/) {
    print qq{ok - 5 'P' =~ /[\x50\x51\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 'P' =~ /[\x50\x51\x52]/ $^X $__FILE__\n};
}

if ('R' =~ /[\x50\x51\x52]/) {
    print qq{ok - 6 'R' =~ /[\x50\x51\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 'R' =~ /[\x50\x51\x52]/ $^X $__FILE__\n};
}

if ('O' !~ /[\x50\x51\x52]/) {
    print qq{ok - 7 'O' !~ /[\x50\x51\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 'O' !~ /[\x50\x51\x52]/ $^X $__FILE__\n};
}

if ('S' !~ /[\x50\x51\x52]/) {
    print qq{ok - 8 'S' !~ /[\x50\x51\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 'S' !~ /[\x50\x51\x52]/ $^X $__FILE__\n};
}

if ('P' =~ /[P-R]/) {
    print qq{ok - 9 'P' =~ /[P-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 'P' =~ /[P-R]/ $^X $__FILE__\n};
}

if ('R' =~ /[P-R]/) {
    print qq{ok - 10 'R' =~ /[P-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 'R' =~ /[P-R]/ $^X $__FILE__\n};
}

if ('O' !~ /[P-R]/) {
    print qq{ok - 11 'O' !~ /[P-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 'O' !~ /[P-R]/ $^X $__FILE__\n};
}

if ('S' !~ /[P-R]/) {
    print qq{ok - 12 'S' !~ /[P-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 'S' !~ /[P-R]/ $^X $__FILE__\n};
}

if ('P' =~ /[\x50-\x52]/) {
    print qq{ok - 13 'P' =~ /[\x50-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 'P' =~ /[\x50-\x52]/ $^X $__FILE__\n};
}

if ('R' =~ /[\x50-\x52]/) {
    print qq{ok - 14 'R' =~ /[\x50-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 'R' =~ /[\x50-\x52]/ $^X $__FILE__\n};
}

if ('O' !~ /[\x50-\x52]/) {
    print qq{ok - 15 'O' !~ /[\x50-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 'O' !~ /[\x50-\x52]/ $^X $__FILE__\n};
}

if ('S' !~ /[\x50-\x52]/) {
    print qq{ok - 16 'S' !~ /[\x50-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 'S' !~ /[\x50-\x52]/ $^X $__FILE__\n};
}

if ('P' =~ /[P-\x52]/) {
    print qq{ok - 17 'P' =~ /[P-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 'P' =~ /[P-\x52]/ $^X $__FILE__\n};
}

if ('R' =~ /[P-\x52]/) {
    print qq{ok - 18 'R' =~ /[P-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 18 'R' =~ /[P-\x52]/ $^X $__FILE__\n};
}

if ('O' !~ /[P-\x52]/) {
    print qq{ok - 19 'O' !~ /[P-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 'O' !~ /[P-\x52]/ $^X $__FILE__\n};
}

if ('S' !~ /[P-\x52]/) {
    print qq{ok - 20 'S' !~ /[P-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 20 'S' !~ /[P-\x52]/ $^X $__FILE__\n};
}

if ('P' =~ /[\x50-R]/) {
    print qq{ok - 21 'P' =~ /[\x50-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 21 'P' =~ /[\x50-R]/ $^X $__FILE__\n};
}

if ('R' =~ /[\x50-R]/) {
    print qq{ok - 22 'R' =~ /[\x50-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 22 'R' =~ /[\x50-R]/ $^X $__FILE__\n};
}

if ('O' !~ /[\x50-R]/) {
    print qq{ok - 23 'O' !~ /[\x50-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 23 'O' !~ /[\x50-R]/ $^X $__FILE__\n};
}

if ('S' !~ /[\x50-R]/) {
    print qq{ok - 24 'S' !~ /[\x50-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 24 'S' !~ /[\x50-R]/ $^X $__FILE__\n};
}

if ('市' =~ /[市平弁]/) {
    print qq{ok - 25 '市' =~ /[市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 25 '市' =~ /[市平弁]/ $^X $__FILE__\n};
}

if ('弁' =~ /[市平弁]/) {
    print qq{ok - 26 '弁' =~ /[市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 26 '弁' =~ /[市平弁]/ $^X $__FILE__\n};
}

if ('左' !~ /[市平弁]/) {
    print qq{ok - 27 '左' !~ /[市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 27 '左' !~ /[市平弁]/ $^X $__FILE__\n};
}

if ('弗' !~ /[市平弁]/) {
    print qq{ok - 28 '弗' !~ /[市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 28 '弗' !~ /[市平弁]/ $^X $__FILE__\n};
}

if ('J' !~ /[市平弁]/) {
    print qq{ok - 29 'J' !~ /[市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 29 'J' !~ /[市平弁]/ $^X $__FILE__\n};
}

if ('N' !~ /[市平弁]/) {
    print qq{ok - 30 'N' !~ /[市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 30 'N' !~ /[市平弁]/ $^X $__FILE__\n};
}

if ('j' !~ /[市平弁]/) {
    print qq{ok - 31 'j' !~ /[市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 31 'j' !~ /[市平弁]/ $^X $__FILE__\n};
}

if ('n' !~ /[市平弁]/) {
    print qq{ok - 32 'n' !~ /[市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 32 'n' !~ /[市平弁]/ $^X $__FILE__\n};
}

if ('市' =~ /[市-弁]/) {
    print qq{ok - 33 '市' =~ /[市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 33 '市' =~ /[市-弁]/ $^X $__FILE__\n};
}

if ('弁' =~ /[市-弁]/) {
    print qq{ok - 34 '弁' =~ /[市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 34 '弁' =~ /[市-弁]/ $^X $__FILE__\n};
}

if ('左' !~ /[市-弁]/) {
    print qq{ok - 35 '左' !~ /[市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 35 '左' !~ /[市-弁]/ $^X $__FILE__\n};
}

if ('弗' !~ /[市-弁]/) {
    print qq{ok - 36 '弗' !~ /[市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 36 '弗' !~ /[市-弁]/ $^X $__FILE__\n};
}

if ('J' !~ /[市-弁]/) {
    print qq{ok - 37 'J' !~ /[市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 37 'J' !~ /[市-弁]/ $^X $__FILE__\n};
}

if ('N' !~ /[市-弁]/) {
    print qq{ok - 38 'N' !~ /[市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 38 'N' !~ /[市-弁]/ $^X $__FILE__\n};
}

if ('j' !~ /[市-弁]/) {
    print qq{ok - 39 'j' !~ /[市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 39 'j' !~ /[市-弁]/ $^X $__FILE__\n};
}

if ('n' !~ /[市-弁]/) {
    print qq{ok - 40 'n' !~ /[市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 40 'n' !~ /[市-弁]/ $^X $__FILE__\n};
}

if ('P' =~ /[PQR市平弁]/) {
    print qq{ok - 41 'P' =~ /[PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 41 'P' =~ /[PQR市平弁]/ $^X $__FILE__\n};
}

if ('R' =~ /[PQR市平弁]/) {
    print qq{ok - 42 'R' =~ /[PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 42 'R' =~ /[PQR市平弁]/ $^X $__FILE__\n};
}

if ('市' =~ /[PQR市平弁]/) {
    print qq{ok - 43 '市' =~ /[PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 43 '市' =~ /[PQR市平弁]/ $^X $__FILE__\n};
}

if ('弁' =~ /[PQR市平弁]/) {
    print qq{ok - 44 '弁' =~ /[PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 44 '弁' =~ /[PQR市平弁]/ $^X $__FILE__\n};
}

if ('O' !~ /[PQR市平弁]/) {
    print qq{ok - 45 'O' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 45 'O' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}

if ('S' !~ /[PQR市平弁]/) {
    print qq{ok - 46 'S' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 46 'S' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}

if ('左' !~ /[PQR市平弁]/) {
    print qq{ok - 47 '左' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 47 '左' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}

if ('弗' !~ /[PQR市平弁]/) {
    print qq{ok - 48 '弗' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 48 '弗' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}

if ('J' !~ /[PQR市平弁]/) {
    print qq{ok - 49 'J' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 49 'J' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}

if ('N' !~ /[PQR市平弁]/) {
    print qq{ok - 50 'N' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 50 'N' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}

if ('j' !~ /[PQR市平弁]/) {
    print qq{ok - 51 'j' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 51 'j' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}

if ('n' !~ /[PQR市平弁]/) {
    print qq{ok - 52 'n' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 52 'n' !~ /[PQR市平弁]/ $^X $__FILE__\n};
}

if ('P' =~ /[P-R市-弁]/) {
    print qq{ok - 53 'P' =~ /[P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 53 'P' =~ /[P-R市-弁]/ $^X $__FILE__\n};
}

if ('R' =~ /[P-R市-弁]/) {
    print qq{ok - 54 'R' =~ /[P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 54 'R' =~ /[P-R市-弁]/ $^X $__FILE__\n};
}

if ('市' =~ /[P-R市-弁]/) {
    print qq{ok - 55 '市' =~ /[P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 55 '市' =~ /[P-R市-弁]/ $^X $__FILE__\n};
}

if ('弁' =~ /[P-R市-弁]/) {
    print qq{ok - 56 '弁' =~ /[P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 56 '弁' =~ /[P-R市-弁]/ $^X $__FILE__\n};
}

if ('O' !~ /[P-R市-弁]/) {
    print qq{ok - 57 'O' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 57 'O' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}

if ('S' !~ /[P-R市-弁]/) {
    print qq{ok - 58 'S' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 58 'S' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}

if ('左' !~ /[P-R市-弁]/) {
    print qq{ok - 59 '左' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 59 '左' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}

if ('弗' !~ /[P-R市-弁]/) {
    print qq{ok - 60 '弗' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 60 '弗' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}

if ('J' !~ /[P-R市-弁]/) {
    print qq{ok - 61 'J' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 61 'J' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}

if ('N' !~ /[P-R市-弁]/) {
    print qq{ok - 62 'N' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 62 'N' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}

if ('j' !~ /[P-R市-弁]/) {
    print qq{ok - 63 'j' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 63 'j' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}

if ('n' !~ /[P-R市-弁]/) {
    print qq{ok - 64 'n' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 64 'n' !~ /[P-R市-弁]/ $^X $__FILE__\n};
}

if ('P' =~ /[PQR]/i) {
    print qq{ok - 65 'P' =~ /[PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 65 'P' =~ /[PQR]/i $^X $__FILE__\n};
}

if ('R' =~ /[PQR]/i) {
    print qq{ok - 66 'R' =~ /[PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 66 'R' =~ /[PQR]/i $^X $__FILE__\n};
}

if ('p' =~ /[PQR]/i) {
    print qq{ok - 67 'p' =~ /[PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 67 'p' =~ /[PQR]/i $^X $__FILE__\n};
}

if ('r' =~ /[PQR]/i) {
    print qq{ok - 68 'r' =~ /[PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 68 'r' =~ /[PQR]/i $^X $__FILE__\n};
}

if ('O' !~ /[PQR]/i) {
    print qq{ok - 69 'O' !~ /[PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 69 'O' !~ /[PQR]/i $^X $__FILE__\n};
}

if ('S' !~ /[PQR]/i) {
    print qq{ok - 70 'S' !~ /[PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 70 'S' !~ /[PQR]/i $^X $__FILE__\n};
}

if ('o' !~ /[PQR]/i) {
    print qq{ok - 71 'o' !~ /[PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 71 'o' !~ /[PQR]/i $^X $__FILE__\n};
}

if ('s' !~ /[PQR]/i) {
    print qq{ok - 72 's' !~ /[PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 72 's' !~ /[PQR]/i $^X $__FILE__\n};
}

if ('P' =~ /[\x50\x51\x52]/i) {
    print qq{ok - 73 'P' =~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 73 'P' =~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('R' =~ /[\x50\x51\x52]/i) {
    print qq{ok - 74 'R' =~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 74 'R' =~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('p' =~ /[\x50\x51\x52]/i) {
    print qq{ok - 75 'p' =~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 75 'p' =~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('r' =~ /[\x50\x51\x52]/i) {
    print qq{ok - 76 'r' =~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 76 'r' =~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('O' !~ /[\x50\x51\x52]/i) {
    print qq{ok - 77 'O' !~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 77 'O' !~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('S' !~ /[\x50\x51\x52]/i) {
    print qq{ok - 78 'S' !~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 78 'S' !~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('o' !~ /[\x50\x51\x52]/i) {
    print qq{ok - 79 'o' !~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 79 'o' !~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('s' !~ /[\x50\x51\x52]/i) {
    print qq{ok - 80 's' !~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 80 's' !~ /[\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('P' =~ /[P-R]/i) {
    print qq{ok - 81 'P' =~ /[P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 81 'P' =~ /[P-R]/i $^X $__FILE__\n};
}

if ('R' =~ /[P-R]/i) {
    print qq{ok - 82 'R' =~ /[P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 82 'R' =~ /[P-R]/i $^X $__FILE__\n};
}

if ('p' =~ /[P-R]/i) {
    print qq{ok - 83 'p' =~ /[P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 83 'p' =~ /[P-R]/i $^X $__FILE__\n};
}

if ('r' =~ /[P-R]/i) {
    print qq{ok - 84 'r' =~ /[P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 84 'r' =~ /[P-R]/i $^X $__FILE__\n};
}

if ('O' !~ /[P-R]/i) {
    print qq{ok - 85 'O' !~ /[P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 85 'O' !~ /[P-R]/i $^X $__FILE__\n};
}

if ('S' !~ /[P-R]/i) {
    print qq{ok - 86 'S' !~ /[P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 86 'S' !~ /[P-R]/i $^X $__FILE__\n};
}

if ('o' !~ /[P-R]/i) {
    print qq{ok - 87 'o' !~ /[P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 87 'o' !~ /[P-R]/i $^X $__FILE__\n};
}

if ('s' !~ /[P-R]/i) {
    print qq{ok - 88 's' !~ /[P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 88 's' !~ /[P-R]/i $^X $__FILE__\n};
}

if ('P' =~ /[\x50-\x52]/i) {
    print qq{ok - 89 'P' =~ /[\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 89 'P' =~ /[\x50-\x52]/i $^X $__FILE__\n};
}

if ('R' =~ /[\x50-\x52]/i) {
    print qq{ok - 90 'R' =~ /[\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 90 'R' =~ /[\x50-\x52]/i $^X $__FILE__\n};
}

if ('p' =~ /[\x50-\x52]/i) {
    print qq{ok - 91 'p' =~ /[\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 91 'p' =~ /[\x50-\x52]/i $^X $__FILE__\n};
}

if ('r' =~ /[\x50-\x52]/i) {
    print qq{ok - 92 'r' =~ /[\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 92 'r' =~ /[\x50-\x52]/i $^X $__FILE__\n};
}

if ('O' !~ /[\x50-\x52]/i) {
    print qq{ok - 93 'O' !~ /[\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 93 'O' !~ /[\x50-\x52]/i $^X $__FILE__\n};
}

if ('S' !~ /[\x50-\x52]/i) {
    print qq{ok - 94 'S' !~ /[\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 94 'S' !~ /[\x50-\x52]/i $^X $__FILE__\n};
}

if ('o' !~ /[\x50-\x52]/i) {
    print qq{ok - 95 'o' !~ /[\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 95 'o' !~ /[\x50-\x52]/i $^X $__FILE__\n};
}

if ('s' !~ /[\x50-\x52]/i) {
    print qq{ok - 96 's' !~ /[\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 96 's' !~ /[\x50-\x52]/i $^X $__FILE__\n};
}

if ('P' =~ /[P-\x52]/i) {
    print qq{ok - 97 'P' =~ /[P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 97 'P' =~ /[P-\x52]/i $^X $__FILE__\n};
}

if ('R' =~ /[P-\x52]/i) {
    print qq{ok - 98 'R' =~ /[P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 98 'R' =~ /[P-\x52]/i $^X $__FILE__\n};
}

if ('p' =~ /[P-\x52]/i) {
    print qq{ok - 99 'p' =~ /[P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 99 'p' =~ /[P-\x52]/i $^X $__FILE__\n};
}

if ('r' =~ /[P-\x52]/i) {
    print qq{ok - 100 'r' =~ /[P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 100 'r' =~ /[P-\x52]/i $^X $__FILE__\n};
}

if ('O' !~ /[P-\x52]/i) {
    print qq{ok - 101 'O' !~ /[P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 101 'O' !~ /[P-\x52]/i $^X $__FILE__\n};
}

if ('S' !~ /[P-\x52]/i) {
    print qq{ok - 102 'S' !~ /[P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 102 'S' !~ /[P-\x52]/i $^X $__FILE__\n};
}

if ('o' !~ /[P-\x52]/i) {
    print qq{ok - 103 'o' !~ /[P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 103 'o' !~ /[P-\x52]/i $^X $__FILE__\n};
}

if ('s' !~ /[P-\x52]/i) {
    print qq{ok - 104 's' !~ /[P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 104 's' !~ /[P-\x52]/i $^X $__FILE__\n};
}

if ('P' =~ /[\x50-R]/i) {
    print qq{ok - 105 'P' =~ /[\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 105 'P' =~ /[\x50-R]/i $^X $__FILE__\n};
}

if ('R' =~ /[\x50-R]/i) {
    print qq{ok - 106 'R' =~ /[\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 106 'R' =~ /[\x50-R]/i $^X $__FILE__\n};
}

if ('p' =~ /[\x50-R]/i) {
    print qq{ok - 107 'p' =~ /[\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 107 'p' =~ /[\x50-R]/i $^X $__FILE__\n};
}

if ('r' =~ /[\x50-R]/i) {
    print qq{ok - 108 'r' =~ /[\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 108 'r' =~ /[\x50-R]/i $^X $__FILE__\n};
}

if ('O' !~ /[\x50-R]/i) {
    print qq{ok - 109 'O' !~ /[\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 109 'O' !~ /[\x50-R]/i $^X $__FILE__\n};
}

if ('S' !~ /[\x50-R]/i) {
    print qq{ok - 110 'S' !~ /[\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 110 'S' !~ /[\x50-R]/i $^X $__FILE__\n};
}

if ('o' !~ /[\x50-R]/i) {
    print qq{ok - 111 'o' !~ /[\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 111 'o' !~ /[\x50-R]/i $^X $__FILE__\n};
}

if ('s' !~ /[\x50-R]/i) {
    print qq{ok - 112 's' !~ /[\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 112 's' !~ /[\x50-R]/i $^X $__FILE__\n};
}

if ('市' =~ /[市平弁]/i) {
    print qq{ok - 113 '市' =~ /[市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 113 '市' =~ /[市平弁]/i $^X $__FILE__\n};
}

if ('弁' =~ /[市平弁]/i) {
    print qq{ok - 114 '弁' =~ /[市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 114 '弁' =~ /[市平弁]/i $^X $__FILE__\n};
}

if ('左' !~ /[市平弁]/i) {
    print qq{ok - 115 '左' !~ /[市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 115 '左' !~ /[市平弁]/i $^X $__FILE__\n};
}

if ('弗' !~ /[市平弁]/i) {
    print qq{ok - 116 '弗' !~ /[市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 116 '弗' !~ /[市平弁]/i $^X $__FILE__\n};
}

if ('J' !~ /[市平弁]/i) {
    print qq{ok - 117 'J' !~ /[市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 117 'J' !~ /[市平弁]/i $^X $__FILE__\n};
}

if ('N' !~ /[市平弁]/i) {
    print qq{ok - 118 'N' !~ /[市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 118 'N' !~ /[市平弁]/i $^X $__FILE__\n};
}

if ('j' !~ /[市平弁]/i) {
    print qq{ok - 119 'j' !~ /[市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 119 'j' !~ /[市平弁]/i $^X $__FILE__\n};
}

if ('n' !~ /[市平弁]/i) {
    print qq{ok - 120 'n' !~ /[市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 120 'n' !~ /[市平弁]/i $^X $__FILE__\n};
}

if ('市' =~ /[市-弁]/i) {
    print qq{ok - 121 '市' =~ /[市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 121 '市' =~ /[市-弁]/i $^X $__FILE__\n};
}

if ('弁' =~ /[市-弁]/i) {
    print qq{ok - 122 '弁' =~ /[市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 122 '弁' =~ /[市-弁]/i $^X $__FILE__\n};
}

if ('左' !~ /[市-弁]/i) {
    print qq{ok - 123 '左' !~ /[市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 123 '左' !~ /[市-弁]/i $^X $__FILE__\n};
}

if ('弗' !~ /[市-弁]/i) {
    print qq{ok - 124 '弗' !~ /[市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 124 '弗' !~ /[市-弁]/i $^X $__FILE__\n};
}

if ('J' !~ /[市-弁]/i) {
    print qq{ok - 125 'J' !~ /[市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 125 'J' !~ /[市-弁]/i $^X $__FILE__\n};
}

if ('N' !~ /[市-弁]/i) {
    print qq{ok - 126 'N' !~ /[市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 126 'N' !~ /[市-弁]/i $^X $__FILE__\n};
}

if ('j' !~ /[市-弁]/i) {
    print qq{ok - 127 'j' !~ /[市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 127 'j' !~ /[市-弁]/i $^X $__FILE__\n};
}

if ('n' !~ /[市-弁]/i) {
    print qq{ok - 128 'n' !~ /[市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 128 'n' !~ /[市-弁]/i $^X $__FILE__\n};
}

if ('P' =~ /[PQR市平弁]/i) {
    print qq{ok - 129 'P' =~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 129 'P' =~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('R' =~ /[PQR市平弁]/i) {
    print qq{ok - 130 'R' =~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 130 'R' =~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('p' =~ /[PQR市平弁]/i) {
    print qq{ok - 131 'p' =~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 131 'p' =~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('r' =~ /[PQR市平弁]/i) {
    print qq{ok - 132 'r' =~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 132 'r' =~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('市' =~ /[PQR市平弁]/i) {
    print qq{ok - 133 '市' =~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 133 '市' =~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('弁' =~ /[PQR市平弁]/i) {
    print qq{ok - 134 '弁' =~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 134 '弁' =~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('O' !~ /[PQR市平弁]/i) {
    print qq{ok - 135 'O' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 135 'O' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('S' !~ /[PQR市平弁]/i) {
    print qq{ok - 136 'S' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 136 'S' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('o' !~ /[PQR市平弁]/i) {
    print qq{ok - 137 'o' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 137 'o' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('s' !~ /[PQR市平弁]/i) {
    print qq{ok - 138 's' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 138 's' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('左' !~ /[PQR市平弁]/i) {
    print qq{ok - 139 '左' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 139 '左' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('弗' !~ /[PQR市平弁]/i) {
    print qq{ok - 140 '弗' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 140 '弗' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('J' !~ /[PQR市平弁]/i) {
    print qq{ok - 141 'J' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 141 'J' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('N' !~ /[PQR市平弁]/i) {
    print qq{ok - 142 'N' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 142 'N' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('j' !~ /[PQR市平弁]/i) {
    print qq{ok - 143 'j' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 143 'j' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('n' !~ /[PQR市平弁]/i) {
    print qq{ok - 144 'n' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 144 'n' !~ /[PQR市平弁]/i $^X $__FILE__\n};
}

if ('P' =~ /[P-R市-弁]/i) {
    print qq{ok - 145 'P' =~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 145 'P' =~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('R' =~ /[P-R市-弁]/i) {
    print qq{ok - 146 'R' =~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 146 'R' =~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('p' =~ /[P-R市-弁]/i) {
    print qq{ok - 147 'p' =~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 147 'p' =~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('r' =~ /[P-R市-弁]/i) {
    print qq{ok - 148 'r' =~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 148 'r' =~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('市' =~ /[P-R市-弁]/i) {
    print qq{ok - 149 '市' =~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 149 '市' =~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('弁' =~ /[P-R市-弁]/i) {
    print qq{ok - 150 '弁' =~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 150 '弁' =~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('O' !~ /[P-R市-弁]/i) {
    print qq{ok - 151 'O' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 151 'O' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('S' !~ /[P-R市-弁]/i) {
    print qq{ok - 152 'S' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 152 'S' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('o' !~ /[P-R市-弁]/i) {
    print qq{ok - 153 'o' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 153 'o' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('s' !~ /[P-R市-弁]/i) {
    print qq{ok - 154 's' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 154 's' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('左' !~ /[P-R市-弁]/i) {
    print qq{ok - 155 '左' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 155 '左' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('弗' !~ /[P-R市-弁]/i) {
    print qq{ok - 156 '弗' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 156 '弗' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('J' !~ /[P-R市-弁]/i) {
    print qq{ok - 157 'J' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 157 'J' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('N' !~ /[P-R市-弁]/i) {
    print qq{ok - 158 'N' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 158 'N' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('j' !~ /[P-R市-弁]/i) {
    print qq{ok - 159 'j' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 159 'j' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('n' !~ /[P-R市-弁]/i) {
    print qq{ok - 160 'n' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 160 'n' !~ /[P-R市-弁]/i $^X $__FILE__\n};
}

if ('O' =~ /[^PQR]/) {
    print qq{ok - 161 'O' =~ /[^PQR]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 161 'O' =~ /[^PQR]/ $^X $__FILE__\n};
}

if ('S' =~ /[^PQR]/) {
    print qq{ok - 162 'S' =~ /[^PQR]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 162 'S' =~ /[^PQR]/ $^X $__FILE__\n};
}

if ('P' !~ /[^PQR]/) {
    print qq{ok - 163 'P' !~ /[^PQR]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 163 'P' !~ /[^PQR]/ $^X $__FILE__\n};
}

if ('R' !~ /[^PQR]/) {
    print qq{ok - 164 'R' !~ /[^PQR]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 164 'R' !~ /[^PQR]/ $^X $__FILE__\n};
}

if ('O' =~ /[^\x50\x51\x52]/) {
    print qq{ok - 165 'O' =~ /[^\x50\x51\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 165 'O' =~ /[^\x50\x51\x52]/ $^X $__FILE__\n};
}

if ('S' =~ /[^\x50\x51\x52]/) {
    print qq{ok - 166 'S' =~ /[^\x50\x51\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 166 'S' =~ /[^\x50\x51\x52]/ $^X $__FILE__\n};
}

if ('P' !~ /[^\x50\x51\x52]/) {
    print qq{ok - 167 'P' !~ /[^\x50\x51\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 167 'P' !~ /[^\x50\x51\x52]/ $^X $__FILE__\n};
}

if ('R' !~ /[^\x50\x51\x52]/) {
    print qq{ok - 168 'R' !~ /[^\x50\x51\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 168 'R' !~ /[^\x50\x51\x52]/ $^X $__FILE__\n};
}

if ('O' =~ /[^P-R]/) {
    print qq{ok - 169 'O' =~ /[^P-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 169 'O' =~ /[^P-R]/ $^X $__FILE__\n};
}

if ('S' =~ /[^P-R]/) {
    print qq{ok - 170 'S' =~ /[^P-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 170 'S' =~ /[^P-R]/ $^X $__FILE__\n};
}

if ('P' !~ /[^P-R]/) {
    print qq{ok - 171 'P' !~ /[^P-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 171 'P' !~ /[^P-R]/ $^X $__FILE__\n};
}

if ('R' !~ /[^P-R]/) {
    print qq{ok - 172 'R' !~ /[^P-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 172 'R' !~ /[^P-R]/ $^X $__FILE__\n};
}

if ('O' =~ /[^\x50-\x52]/) {
    print qq{ok - 173 'O' =~ /[^\x50-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 173 'O' =~ /[^\x50-\x52]/ $^X $__FILE__\n};
}

if ('S' =~ /[^\x50-\x52]/) {
    print qq{ok - 174 'S' =~ /[^\x50-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 174 'S' =~ /[^\x50-\x52]/ $^X $__FILE__\n};
}

if ('P' !~ /[^\x50-\x52]/) {
    print qq{ok - 175 'P' !~ /[^\x50-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 175 'P' !~ /[^\x50-\x52]/ $^X $__FILE__\n};
}

if ('R' !~ /[^\x50-\x52]/) {
    print qq{ok - 176 'R' !~ /[^\x50-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 176 'R' !~ /[^\x50-\x52]/ $^X $__FILE__\n};
}

if ('O' =~ /[^P-\x52]/) {
    print qq{ok - 177 'O' =~ /[^P-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 177 'O' =~ /[^P-\x52]/ $^X $__FILE__\n};
}

if ('S' =~ /[^P-\x52]/) {
    print qq{ok - 178 'S' =~ /[^P-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 178 'S' =~ /[^P-\x52]/ $^X $__FILE__\n};
}

if ('P' !~ /[^P-\x52]/) {
    print qq{ok - 179 'P' !~ /[^P-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 179 'P' !~ /[^P-\x52]/ $^X $__FILE__\n};
}

if ('R' !~ /[^P-\x52]/) {
    print qq{ok - 180 'R' !~ /[^P-\x52]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 180 'R' !~ /[^P-\x52]/ $^X $__FILE__\n};
}

if ('O' =~ /[^\x50-R]/) {
    print qq{ok - 181 'O' =~ /[^\x50-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 181 'O' =~ /[^\x50-R]/ $^X $__FILE__\n};
}

if ('S' =~ /[^\x50-R]/) {
    print qq{ok - 182 'S' =~ /[^\x50-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 182 'S' =~ /[^\x50-R]/ $^X $__FILE__\n};
}

if ('P' !~ /[^\x50-R]/) {
    print qq{ok - 183 'P' !~ /[^\x50-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 183 'P' !~ /[^\x50-R]/ $^X $__FILE__\n};
}

if ('R' !~ /[^\x50-R]/) {
    print qq{ok - 184 'R' !~ /[^\x50-R]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 184 'R' !~ /[^\x50-R]/ $^X $__FILE__\n};
}

if ('左' =~ /[^市平弁]/) {
    print qq{ok - 185 '左' =~ /[^市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 185 '左' =~ /[^市平弁]/ $^X $__FILE__\n};
}

if ('弗' =~ /[^市平弁]/) {
    print qq{ok - 186 '弗' =~ /[^市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 186 '弗' =~ /[^市平弁]/ $^X $__FILE__\n};
}

if ('J' =~ /[^市平弁]/) {
    print qq{ok - 187 'J' =~ /[^市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 187 'J' =~ /[^市平弁]/ $^X $__FILE__\n};
}

if ('N' =~ /[^市平弁]/) {
    print qq{ok - 188 'N' =~ /[^市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 188 'N' =~ /[^市平弁]/ $^X $__FILE__\n};
}

if ('j' =~ /[^市平弁]/) {
    print qq{ok - 189 'j' =~ /[^市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 189 'j' =~ /[^市平弁]/ $^X $__FILE__\n};
}

if ('n' =~ /[^市平弁]/) {
    print qq{ok - 190 'n' =~ /[^市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 190 'n' =~ /[^市平弁]/ $^X $__FILE__\n};
}

if ('市' !~ /[^市平弁]/) {
    print qq{ok - 191 '市' !~ /[^市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 191 '市' !~ /[^市平弁]/ $^X $__FILE__\n};
}

if ('弁' !~ /[^市平弁]/) {
    print qq{ok - 192 '弁' !~ /[^市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 192 '弁' !~ /[^市平弁]/ $^X $__FILE__\n};
}

if ('左' =~ /[^市-弁]/) {
    print qq{ok - 193 '左' =~ /[^市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 193 '左' =~ /[^市-弁]/ $^X $__FILE__\n};
}

if ('弗' =~ /[^市-弁]/) {
    print qq{ok - 194 '弗' =~ /[^市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 194 '弗' =~ /[^市-弁]/ $^X $__FILE__\n};
}

if ('J' =~ /[^市-弁]/) {
    print qq{ok - 195 'J' =~ /[^市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 195 'J' =~ /[^市-弁]/ $^X $__FILE__\n};
}

if ('N' =~ /[^市-弁]/) {
    print qq{ok - 196 'N' =~ /[^市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 196 'N' =~ /[^市-弁]/ $^X $__FILE__\n};
}

if ('j' =~ /[^市-弁]/) {
    print qq{ok - 197 'j' =~ /[^市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 197 'j' =~ /[^市-弁]/ $^X $__FILE__\n};
}

if ('n' =~ /[^市-弁]/) {
    print qq{ok - 198 'n' =~ /[^市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 198 'n' =~ /[^市-弁]/ $^X $__FILE__\n};
}

if ('市' !~ /[^市-弁]/) {
    print qq{ok - 199 '市' !~ /[^市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 199 '市' !~ /[^市-弁]/ $^X $__FILE__\n};
}

if ('弁' !~ /[^市-弁]/) {
    print qq{ok - 200 '弁' !~ /[^市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 200 '弁' !~ /[^市-弁]/ $^X $__FILE__\n};
}

if ('O' =~ /[^PQR市平弁]/) {
    print qq{ok - 201 'O' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 201 'O' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}

if ('S' =~ /[^PQR市平弁]/) {
    print qq{ok - 202 'S' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 202 'S' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}

if ('左' =~ /[^PQR市平弁]/) {
    print qq{ok - 203 '左' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 203 '左' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}

if ('弗' =~ /[^PQR市平弁]/) {
    print qq{ok - 204 '弗' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 204 '弗' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}

if ('J' =~ /[^PQR市平弁]/) {
    print qq{ok - 205 'J' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 205 'J' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}

if ('N' =~ /[^PQR市平弁]/) {
    print qq{ok - 206 'N' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 206 'N' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}

if ('j' =~ /[^PQR市平弁]/) {
    print qq{ok - 207 'j' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 207 'j' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}

if ('n' =~ /[^PQR市平弁]/) {
    print qq{ok - 208 'n' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 208 'n' =~ /[^PQR市平弁]/ $^X $__FILE__\n};
}

if ('P' !~ /[^PQR市平弁]/) {
    print qq{ok - 209 'P' !~ /[^PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 209 'P' !~ /[^PQR市平弁]/ $^X $__FILE__\n};
}

if ('R' !~ /[^PQR市平弁]/) {
    print qq{ok - 210 'R' !~ /[^PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 210 'R' !~ /[^PQR市平弁]/ $^X $__FILE__\n};
}

if ('市' !~ /[^PQR市平弁]/) {
    print qq{ok - 211 '市' !~ /[^PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 211 '市' !~ /[^PQR市平弁]/ $^X $__FILE__\n};
}

if ('弁' !~ /[^PQR市平弁]/) {
    print qq{ok - 212 '弁' !~ /[^PQR市平弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 212 '弁' !~ /[^PQR市平弁]/ $^X $__FILE__\n};
}

if ('O' =~ /[^P-R市-弁]/) {
    print qq{ok - 213 'O' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 213 'O' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}

if ('S' =~ /[^P-R市-弁]/) {
    print qq{ok - 214 'S' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 214 'S' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}

if ('左' =~ /[^P-R市-弁]/) {
    print qq{ok - 215 '左' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 215 '左' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}

if ('弗' =~ /[^P-R市-弁]/) {
    print qq{ok - 216 '弗' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 216 '弗' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}

if ('J' =~ /[^P-R市-弁]/) {
    print qq{ok - 217 'J' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 217 'J' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}

if ('N' =~ /[^P-R市-弁]/) {
    print qq{ok - 218 'N' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 218 'N' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}

if ('j' =~ /[^P-R市-弁]/) {
    print qq{ok - 219 'j' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 219 'j' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}

if ('n' =~ /[^P-R市-弁]/) {
    print qq{ok - 220 'n' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 220 'n' =~ /[^P-R市-弁]/ $^X $__FILE__\n};
}

if ('P' !~ /[^P-R市-弁]/) {
    print qq{ok - 221 'P' !~ /[^P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 221 'P' !~ /[^P-R市-弁]/ $^X $__FILE__\n};
}

if ('R' !~ /[^P-R市-弁]/) {
    print qq{ok - 222 'R' !~ /[^P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 222 'R' !~ /[^P-R市-弁]/ $^X $__FILE__\n};
}

if ('市' !~ /[^P-R市-弁]/) {
    print qq{ok - 223 '市' !~ /[^P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 223 '市' !~ /[^P-R市-弁]/ $^X $__FILE__\n};
}

if ('弁' !~ /[^P-R市-弁]/) {
    print qq{ok - 224 '弁' !~ /[^P-R市-弁]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 224 '弁' !~ /[^P-R市-弁]/ $^X $__FILE__\n};
}

if ('O' =~ /[^PQR]/i) {
    print qq{ok - 225 'O' =~ /[^PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 225 'O' =~ /[^PQR]/i $^X $__FILE__\n};
}

if ('S' =~ /[^PQR]/i) {
    print qq{ok - 226 'S' =~ /[^PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 226 'S' =~ /[^PQR]/i $^X $__FILE__\n};
}

if ('o' =~ /[^PQR]/i) {
    print qq{ok - 227 'o' =~ /[^PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 227 'o' =~ /[^PQR]/i $^X $__FILE__\n};
}

if ('s' =~ /[^PQR]/i) {
    print qq{ok - 228 's' =~ /[^PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 228 's' =~ /[^PQR]/i $^X $__FILE__\n};
}

if ('P' !~ /[^PQR]/i) {
    print qq{ok - 229 'P' !~ /[^PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 229 'P' !~ /[^PQR]/i $^X $__FILE__\n};
}

if ('R' !~ /[^PQR]/i) {
    print qq{ok - 230 'R' !~ /[^PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 230 'R' !~ /[^PQR]/i $^X $__FILE__\n};
}

if ('p' !~ /[^PQR]/i) {
    print qq{ok - 231 'p' !~ /[^PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 231 'p' !~ /[^PQR]/i $^X $__FILE__\n};
}

if ('r' !~ /[^PQR]/i) {
    print qq{ok - 232 'r' !~ /[^PQR]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 232 'r' !~ /[^PQR]/i $^X $__FILE__\n};
}

if ('O' =~ /[^\x50\x51\x52]/i) {
    print qq{ok - 233 'O' =~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 233 'O' =~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('S' =~ /[^\x50\x51\x52]/i) {
    print qq{ok - 234 'S' =~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 234 'S' =~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('o' =~ /[^\x50\x51\x52]/i) {
    print qq{ok - 235 'o' =~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 235 'o' =~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('s' =~ /[^\x50\x51\x52]/i) {
    print qq{ok - 236 's' =~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 236 's' =~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('P' !~ /[^\x50\x51\x52]/i) {
    print qq{ok - 237 'P' !~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 237 'P' !~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('R' !~ /[^\x50\x51\x52]/i) {
    print qq{ok - 238 'R' !~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 238 'R' !~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('p' !~ /[^\x50\x51\x52]/i) {
    print qq{ok - 239 'p' !~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 239 'p' !~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('r' !~ /[^\x50\x51\x52]/i) {
    print qq{ok - 240 'r' !~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 240 'r' !~ /[^\x50\x51\x52]/i $^X $__FILE__\n};
}

if ('O' =~ /[^P-R]/i) {
    print qq{ok - 241 'O' =~ /[^P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 241 'O' =~ /[^P-R]/i $^X $__FILE__\n};
}

if ('S' =~ /[^P-R]/i) {
    print qq{ok - 242 'S' =~ /[^P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 242 'S' =~ /[^P-R]/i $^X $__FILE__\n};
}

if ('o' =~ /[^P-R]/i) {
    print qq{ok - 243 'o' =~ /[^P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 243 'o' =~ /[^P-R]/i $^X $__FILE__\n};
}

if ('s' =~ /[^P-R]/i) {
    print qq{ok - 244 's' =~ /[^P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 244 's' =~ /[^P-R]/i $^X $__FILE__\n};
}

if ('P' !~ /[^P-R]/i) {
    print qq{ok - 245 'P' !~ /[^P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 245 'P' !~ /[^P-R]/i $^X $__FILE__\n};
}

if ('R' !~ /[^P-R]/i) {
    print qq{ok - 246 'R' !~ /[^P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 246 'R' !~ /[^P-R]/i $^X $__FILE__\n};
}

if ('p' !~ /[^P-R]/i) {
    print qq{ok - 247 'p' !~ /[^P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 247 'p' !~ /[^P-R]/i $^X $__FILE__\n};
}

if ('r' !~ /[^P-R]/i) {
    print qq{ok - 248 'r' !~ /[^P-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 248 'r' !~ /[^P-R]/i $^X $__FILE__\n};
}

if ('O' =~ /[^\x50-\x52]/i) {
    print qq{ok - 249 'O' =~ /[^\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 249 'O' =~ /[^\x50-\x52]/i $^X $__FILE__\n};
}

if ('S' =~ /[^\x50-\x52]/i) {
    print qq{ok - 250 'S' =~ /[^\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 250 'S' =~ /[^\x50-\x52]/i $^X $__FILE__\n};
}

if ('o' =~ /[^\x50-\x52]/i) {
    print qq{ok - 251 'o' =~ /[^\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 251 'o' =~ /[^\x50-\x52]/i $^X $__FILE__\n};
}

if ('s' =~ /[^\x50-\x52]/i) {
    print qq{ok - 252 's' =~ /[^\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 252 's' =~ /[^\x50-\x52]/i $^X $__FILE__\n};
}

if ('P' !~ /[^\x50-\x52]/i) {
    print qq{ok - 253 'P' !~ /[^\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 253 'P' !~ /[^\x50-\x52]/i $^X $__FILE__\n};
}

if ('R' !~ /[^\x50-\x52]/i) {
    print qq{ok - 254 'R' !~ /[^\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 254 'R' !~ /[^\x50-\x52]/i $^X $__FILE__\n};
}

if ('p' !~ /[^\x50-\x52]/i) {
    print qq{ok - 255 'p' !~ /[^\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 255 'p' !~ /[^\x50-\x52]/i $^X $__FILE__\n};
}

if ('r' !~ /[^\x50-\x52]/i) {
    print qq{ok - 256 'r' !~ /[^\x50-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 256 'r' !~ /[^\x50-\x52]/i $^X $__FILE__\n};
}

if ('O' =~ /[^P-\x52]/i) {
    print qq{ok - 257 'O' =~ /[^P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 257 'O' =~ /[^P-\x52]/i $^X $__FILE__\n};
}

if ('S' =~ /[^P-\x52]/i) {
    print qq{ok - 258 'S' =~ /[^P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 258 'S' =~ /[^P-\x52]/i $^X $__FILE__\n};
}

if ('o' =~ /[^P-\x52]/i) {
    print qq{ok - 259 'o' =~ /[^P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 259 'o' =~ /[^P-\x52]/i $^X $__FILE__\n};
}

if ('s' =~ /[^P-\x52]/i) {
    print qq{ok - 260 's' =~ /[^P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 260 's' =~ /[^P-\x52]/i $^X $__FILE__\n};
}

if ('P' !~ /[^P-\x52]/i) {
    print qq{ok - 261 'P' !~ /[^P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 261 'P' !~ /[^P-\x52]/i $^X $__FILE__\n};
}

if ('R' !~ /[^P-\x52]/i) {
    print qq{ok - 262 'R' !~ /[^P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 262 'R' !~ /[^P-\x52]/i $^X $__FILE__\n};
}

if ('p' !~ /[^P-\x52]/i) {
    print qq{ok - 263 'p' !~ /[^P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 263 'p' !~ /[^P-\x52]/i $^X $__FILE__\n};
}

if ('r' !~ /[^P-\x52]/i) {
    print qq{ok - 264 'r' !~ /[^P-\x52]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 264 'r' !~ /[^P-\x52]/i $^X $__FILE__\n};
}

if ('O' =~ /[^\x50-R]/i) {
    print qq{ok - 265 'O' =~ /[^\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 265 'O' =~ /[^\x50-R]/i $^X $__FILE__\n};
}

if ('S' =~ /[^\x50-R]/i) {
    print qq{ok - 266 'S' =~ /[^\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 266 'S' =~ /[^\x50-R]/i $^X $__FILE__\n};
}

if ('o' =~ /[^\x50-R]/i) {
    print qq{ok - 267 'o' =~ /[^\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 267 'o' =~ /[^\x50-R]/i $^X $__FILE__\n};
}

if ('s' =~ /[^\x50-R]/i) {
    print qq{ok - 268 's' =~ /[^\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 268 's' =~ /[^\x50-R]/i $^X $__FILE__\n};
}

if ('P' !~ /[^\x50-R]/i) {
    print qq{ok - 269 'P' !~ /[^\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 269 'P' !~ /[^\x50-R]/i $^X $__FILE__\n};
}

if ('R' !~ /[^\x50-R]/i) {
    print qq{ok - 270 'R' !~ /[^\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 270 'R' !~ /[^\x50-R]/i $^X $__FILE__\n};
}

if ('p' !~ /[^\x50-R]/i) {
    print qq{ok - 271 'p' !~ /[^\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 271 'p' !~ /[^\x50-R]/i $^X $__FILE__\n};
}

if ('r' !~ /[^\x50-R]/i) {
    print qq{ok - 272 'r' !~ /[^\x50-R]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 272 'r' !~ /[^\x50-R]/i $^X $__FILE__\n};
}

if ('左' =~ /[^市平弁]/i) {
    print qq{ok - 273 '左' =~ /[^市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 273 '左' =~ /[^市平弁]/i $^X $__FILE__\n};
}

if ('弗' =~ /[^市平弁]/i) {
    print qq{ok - 274 '弗' =~ /[^市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 274 '弗' =~ /[^市平弁]/i $^X $__FILE__\n};
}

if ('J' =~ /[^市平弁]/i) {
    print qq{ok - 275 'J' =~ /[^市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 275 'J' =~ /[^市平弁]/i $^X $__FILE__\n};
}

if ('N' =~ /[^市平弁]/i) {
    print qq{ok - 276 'N' =~ /[^市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 276 'N' =~ /[^市平弁]/i $^X $__FILE__\n};
}

if ('j' =~ /[^市平弁]/i) {
    print qq{ok - 277 'j' =~ /[^市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 277 'j' =~ /[^市平弁]/i $^X $__FILE__\n};
}

if ('n' =~ /[^市平弁]/i) {
    print qq{ok - 278 'n' =~ /[^市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 278 'n' =~ /[^市平弁]/i $^X $__FILE__\n};
}

if ('市' !~ /[^市平弁]/i) {
    print qq{ok - 279 '市' !~ /[^市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 279 '市' !~ /[^市平弁]/i $^X $__FILE__\n};
}

if ('弁' !~ /[^市平弁]/i) {
    print qq{ok - 280 '弁' !~ /[^市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 280 '弁' !~ /[^市平弁]/i $^X $__FILE__\n};
}

if ('左' =~ /[^市-弁]/i) {
    print qq{ok - 281 '左' =~ /[^市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 281 '左' =~ /[^市-弁]/i $^X $__FILE__\n};
}

if ('弗' =~ /[^市-弁]/i) {
    print qq{ok - 282 '弗' =~ /[^市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 282 '弗' =~ /[^市-弁]/i $^X $__FILE__\n};
}

if ('J' =~ /[^市-弁]/i) {
    print qq{ok - 283 'J' =~ /[^市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 283 'J' =~ /[^市-弁]/i $^X $__FILE__\n};
}

if ('N' =~ /[^市-弁]/i) {
    print qq{ok - 284 'N' =~ /[^市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 284 'N' =~ /[^市-弁]/i $^X $__FILE__\n};
}

if ('j' =~ /[^市-弁]/i) {
    print qq{ok - 285 'j' =~ /[^市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 285 'j' =~ /[^市-弁]/i $^X $__FILE__\n};
}

if ('n' =~ /[^市-弁]/i) {
    print qq{ok - 286 'n' =~ /[^市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 286 'n' =~ /[^市-弁]/i $^X $__FILE__\n};
}

if ('市' !~ /[^市-弁]/i) {
    print qq{ok - 287 '市' !~ /[^市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 287 '市' !~ /[^市-弁]/i $^X $__FILE__\n};
}

if ('弁' !~ /[^市-弁]/i) {
    print qq{ok - 288 '弁' !~ /[^市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 288 '弁' !~ /[^市-弁]/i $^X $__FILE__\n};
}

if ('O' =~ /[^PQR市平弁]/i) {
    print qq{ok - 289 'O' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 289 'O' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('S' =~ /[^PQR市平弁]/i) {
    print qq{ok - 290 'S' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 290 'S' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('o' =~ /[^PQR市平弁]/i) {
    print qq{ok - 291 'o' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 291 'o' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('s' =~ /[^PQR市平弁]/i) {
    print qq{ok - 292 's' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 292 's' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('左' =~ /[^PQR市平弁]/i) {
    print qq{ok - 293 '左' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 293 '左' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('弗' =~ /[^PQR市平弁]/i) {
    print qq{ok - 294 '弗' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 294 '弗' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('J' =~ /[^PQR市平弁]/i) {
    print qq{ok - 295 'J' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 295 'J' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('N' =~ /[^PQR市平弁]/i) {
    print qq{ok - 296 'N' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 296 'N' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('j' =~ /[^PQR市平弁]/i) {
    print qq{ok - 297 'j' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 297 'j' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('n' =~ /[^PQR市平弁]/i) {
    print qq{ok - 298 'n' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 298 'n' =~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('P' !~ /[^PQR市平弁]/i) {
    print qq{ok - 299 'P' !~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 299 'P' !~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('R' !~ /[^PQR市平弁]/i) {
    print qq{ok - 300 'R' !~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 300 'R' !~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('p' !~ /[^PQR市平弁]/i) {
    print qq{ok - 301 'p' !~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 301 'p' !~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('r' !~ /[^PQR市平弁]/i) {
    print qq{ok - 302 'r' !~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 302 'r' !~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('市' !~ /[^PQR市平弁]/i) {
    print qq{ok - 303 '市' !~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 303 '市' !~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('弁' !~ /[^PQR市平弁]/i) {
    print qq{ok - 304 '弁' !~ /[^PQR市平弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 304 '弁' !~ /[^PQR市平弁]/i $^X $__FILE__\n};
}

if ('O' =~ /[^P-R市-弁]/i) {
    print qq{ok - 305 'O' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 305 'O' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('S' =~ /[^P-R市-弁]/i) {
    print qq{ok - 306 'S' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 306 'S' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('o' =~ /[^P-R市-弁]/i) {
    print qq{ok - 307 'o' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 307 'o' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('s' =~ /[^P-R市-弁]/i) {
    print qq{ok - 308 's' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 308 's' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('左' =~ /[^P-R市-弁]/i) {
    print qq{ok - 309 '左' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 309 '左' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('弗' =~ /[^P-R市-弁]/i) {
    print qq{ok - 310 '弗' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 310 '弗' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('J' =~ /[^P-R市-弁]/i) {
    print qq{ok - 311 'J' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 311 'J' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('N' =~ /[^P-R市-弁]/i) {
    print qq{ok - 312 'N' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 312 'N' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('j' =~ /[^P-R市-弁]/i) {
    print qq{ok - 313 'j' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 313 'j' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('n' =~ /[^P-R市-弁]/i) {
    print qq{ok - 314 'n' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 314 'n' =~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('P' !~ /[^P-R市-弁]/i) {
    print qq{ok - 315 'P' !~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 315 'P' !~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('R' !~ /[^P-R市-弁]/i) {
    print qq{ok - 316 'R' !~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 316 'R' !~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('p' !~ /[^P-R市-弁]/i) {
    print qq{ok - 317 'p' !~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 317 'p' !~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('r' !~ /[^P-R市-弁]/i) {
    print qq{ok - 318 'r' !~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 318 'r' !~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('市' !~ /[^P-R市-弁]/i) {
    print qq{ok - 319 '市' !~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 319 '市' !~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('弁' !~ /[^P-R市-弁]/i) {
    print qq{ok - 320 '弁' !~ /[^P-R市-弁]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 320 '弁' !~ /[^P-R市-弁]/i $^X $__FILE__\n};
}

if ('A' =~ /[\x1B-M]/i) {
    print qq{ok - 321 'A' =~ /[\\x1B-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 321 'A' =~ /[\\x1B-M]/i $^X $__FILE__\n};
}

if ('a' =~ /[\x1B-M]/i) {
    print qq{ok - 322 'a' =~ /[\\x1B-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 322 'a' =~ /[\\x1B-M]/i $^X $__FILE__\n};
}

if ('Z' !~ /[\x1B-M]/i) {
    print qq{ok - 323 'Z' !~ /[\\x1B-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 323 'Z' !~ /[\\x1B-M]/i $^X $__FILE__\n};
}

if ('z' !~ /[\x1B-M]/i) {
    print qq{ok - 324 'z' !~ /[\\x1B-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 324 'z' !~ /[\\x1B-M]/i $^X $__FILE__\n};
}

if ('A' !~ /[m-\x7F]/i) {
    print qq{ok - 325 'A' !~ /[m-\\x7F]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 325 'A' !~ /[m-\\x7F]/i $^X $__FILE__\n};
}

if ('a' !~ /[m-\x7F]/i) {
    print qq{ok - 326 'a' !~ /[m-\\x7F]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 326 'a' !~ /[m-\\x7F]/i $^X $__FILE__\n};
}

if ('Z' =~ /[m-\x7F]/i) {
    print qq{ok - 327 'Z' =~ /[m-\\x7F]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 327 'Z' =~ /[m-\\x7F]/i $^X $__FILE__\n};
}

if ('z' =~ /[m-\x7F]/i) {
    print qq{ok - 328 'z' =~ /[m-\\x7F]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 328 'z' =~ /[m-\\x7F]/i $^X $__FILE__\n};
}

if ('A' !~ /[^\x1B-M]/i) {
    print qq{ok - 329 'A' !~ /[^\\x1B-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 329 'A' !~ /[^\\x1B-M]/i $^X $__FILE__\n};
}

if ('a' !~ /[^\x1B-M]/i) {
    print qq{ok - 330 'a' !~ /[^\\x1B-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 330 'a' !~ /[^\\x1B-M]/i $^X $__FILE__\n};
}

if ('Z' =~ /[^\x1B-M]/i) {
    print qq{ok - 331 'Z' =~ /[^\\x1B-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 331 'Z' =~ /[^\\x1B-M]/i $^X $__FILE__\n};
}

if ('z' =~ /[^\x1B-M]/i) {
    print qq{ok - 332 'z' =~ /[^\\x1B-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 332 'z' =~ /[^\\x1B-M]/i $^X $__FILE__\n};
}

if ('A' =~ /[^m-\x7F]/i) {
    print qq{ok - 333 'A' =~ /[^m-\\x7F]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 333 'A' =~ /[^m-\\x7F]/i $^X $__FILE__\n};
}

if ('a' =~ /[^m-\x7F]/i) {
    print qq{ok - 334 'a' =~ /[^m-\\x7F]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 334 'a' =~ /[^m-\\x7F]/i $^X $__FILE__\n};
}

if ('Z' !~ /[^m-\x7F]/i) {
    print qq{ok - 335 'Z' !~ /[^m-\\x7F]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 335 'Z' !~ /[^m-\\x7F]/i $^X $__FILE__\n};
}

if ('z' !~ /[^m-\x7F]/i) {
    print qq{ok - 336 'z' !~ /[^m-\\x7F]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 336 'z' !~ /[^m-\\x7F]/i $^X $__FILE__\n};
}

if ('A' =~ /[\n-M]/i) {
    print qq{ok - 337 'A' =~ /[\\n-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 337 'A' =~ /[\\n-M]/i $^X $__FILE__\n};
}

if ('a' =~ /[\n-M]/i) {
    print qq{ok - 338 'a' =~ /[\\n-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 338 'a' =~ /[\\n-M]/i $^X $__FILE__\n};
}

if ('Z' !~ /[\n-M]/i) {
    print qq{ok - 339 'Z' !~ /[\\n-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 339 'Z' !~ /[\\n-M]/i $^X $__FILE__\n};
}

if ('z' !~ /[\n-M]/i) {
    print qq{ok - 340 'z' !~ /[\\n-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 340 'z' !~ /[\\n-M]/i $^X $__FILE__\n};
}

if ('A' !~ /[^\n-M]/i) {
    print qq{ok - 341 'A' !~ /[^\\n-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 341 'A' !~ /[^\\n-M]/i $^X $__FILE__\n};
}

if ('a' !~ /[^\n-M]/i) {
    print qq{ok - 342 'a' !~ /[^\\n-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 342 'a' !~ /[^\\n-M]/i $^X $__FILE__\n};
}

if ('Z' =~ /[^\n-M]/i) {
    print qq{ok - 343 'Z' =~ /[^\\n-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 343 'Z' =~ /[^\\n-M]/i $^X $__FILE__\n};
}

if ('z' =~ /[^\n-M]/i) {
    print qq{ok - 344 'z' =~ /[^\\n-M]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 344 'z' =~ /[^\\n-M]/i $^X $__FILE__\n};
}

__END__
