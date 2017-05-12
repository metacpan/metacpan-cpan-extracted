# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{Ç†} ne "\x82\xa0";

use strict;
use HP15;
print "1..56\n";

my $__FILE__ = __FILE__;

$_ = 'A';
if ($_ =~ s/A//) {
    print qq{ok - 1 \$_ =~ s/A// $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \$_ =~ s/A// $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s/A//b) {
    print qq{ok - 2 \$_ =~ s/A//b $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ =~ s/A//b $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s/a//i) {
    print qq{ok - 3 \$_ =~ s/a//i $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 \$_ =~ s/a//i $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s/a//ib) {
    print qq{ok - 4 \$_ =~ s/a//ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 \$_ =~ s/a//ib $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s/A//) {
    print qq{not ok - 5 \$_ =~ s/A// $^X $__FILE__\n};
}
else {
    print qq{ok - 5 \$_ =~ s/A// $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s/A//b) {
    print qq{not ok - 6 \$_ =~ s/A//b $^X $__FILE__\n};
}
else {
    print qq{ok - 6 \$_ =~ s/A//b $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s/a//i) {
    print qq{ok - 7 \$_ =~ s/a//i $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 \$_ =~ s/a//i $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s/a//ib) {
    print qq{ok - 8 \$_ =~ s/a//ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 \$_ =~ s/a//ib $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s/ÉA//) {
    print qq{not ok - 9 \$_ =~ s/ÉA// $^X $__FILE__\n};
}
else {
    print qq{ok - 9 \$_ =~ s/ÉA// $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s/ÉA//b) {
    print qq{not ok - 10 \$_ =~ s/ÉA//b $^X $__FILE__\n};
}
else {
    print qq{ok - 10 \$_ =~ s/ÉA//b $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s/ÉA//i) {
    print qq{not ok - 11 \$_ =~ s/ÉA//i $^X $__FILE__\n};
}
else {
    print qq{ok - 11 \$_ =~ s/ÉA//i $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s/ÉA//ib) {
    print qq{not ok - 12 \$_ =~ s/ÉA//ib $^X $__FILE__\n};
}
else {
    print qq{ok - 12 \$_ =~ s/ÉA//ib $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s/Éa//) {
    print qq{not ok - 13 \$_ =~ s/Éa// $^X $__FILE__\n};
}
else {
    print qq{ok - 13 \$_ =~ s/Éa// $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s/Éa//b) {
    print qq{not ok - 14 \$_ =~ s/Éa//b $^X $__FILE__\n};
}
else {
    print qq{ok - 14 \$_ =~ s/Éa//b $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s/Éa//i) {
    print qq{not ok - 15 \$_ =~ s/Éa//i $^X $__FILE__\n};
}
else {
    print qq{ok - 15 \$_ =~ s/Éa//i $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s/Éa//ib) {
    print qq{not ok - 16 \$_ =~ s/Éa//ib $^X $__FILE__\n};
}
else {
    print qq{ok - 16 \$_ =~ s/Éa//ib $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s/ÉA//) {
    print qq{not ok - 17 \$_ =~ s/ÉA// $^X $__FILE__\n};
}
else {
    print qq{ok - 17 \$_ =~ s/ÉA// $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s/ÉA//b) {
    print qq{not ok - 18 \$_ =~ s/ÉA//b $^X $__FILE__\n};
}
else {
    print qq{ok - 18 \$_ =~ s/ÉA//b $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s/ÉA//i) {
    print qq{not ok - 19 \$_ =~ s/ÉA//i $^X $__FILE__\n};
}
else {
    print qq{ok - 19 \$_ =~ s/ÉA//i $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s/ÉA//ib) {
    print qq{not ok - 20 \$_ =~ s/ÉA//ib $^X $__FILE__\n};
}
else {
    print qq{ok - 20 \$_ =~ s/ÉA//ib $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s/Éa//) {
    print qq{not ok - 21 \$_ =~ s/Éa// $^X $__FILE__\n};
}
else {
    print qq{ok - 21 \$_ =~ s/Éa// $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s/Éa//b) {
    print qq{not ok - 22 \$_ =~ s/Éa//b $^X $__FILE__\n};
}
else {
    print qq{ok - 22 \$_ =~ s/Éa//b $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s/Éa//i) {
    print qq{not ok - 23 \$_ =~ s/Éa//i $^X $__FILE__\n};
}
else {
    print qq{ok - 23 \$_ =~ s/Éa//i $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s/Éa//ib) {
    print qq{not ok - 24 \$_ =~ s/Éa//ib $^X $__FILE__\n};
}
else {
    print qq{ok - 24 \$_ =~ s/Éa//ib $^X $__FILE__\n};
}

$_ = 'ÉA';
if ($_ =~ s/A//) {
    print qq{not ok - 25 \$_ =~ s/A// $^X $__FILE__\n};
}
else {
    print qq{ok - 25 \$_ =~ s/A// $^X $__FILE__\n};
}

$_ = 'ÉA';
if ($_ =~ s/A//b) {
    print qq{ok - 26 \$_ =~ s/A//b $^X $__FILE__\n};
}
else {
    print qq{not ok - 26 \$_ =~ s/A//b $^X $__FILE__\n};
}

$_ = 'ÉA';
if ($_ =~ s/A//i) {
    print qq{not ok - 27 \$_ =~ s/A//i $^X $__FILE__\n};
}
else {
    print qq{ok - 27 \$_ =~ s/A//i $^X $__FILE__\n};
}

$_ = 'ÉA';
if ($_ =~ s/A//ib) {
    print qq{ok - 28 \$_ =~ s/A//ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 28 \$_ =~ s/A//ib $^X $__FILE__\n};
}

$_ = 'ÉA';
if ($_ =~ s/a//) {
    print qq{not ok - 29 \$_ =~ s/a// $^X $__FILE__\n};
}
else {
    print qq{ok - 29 \$_ =~ s/a// $^X $__FILE__\n};
}

$_ = 'ÉA';
if ($_ =~ s/a//b) {
    print qq{not ok - 30 \$_ =~ s/a//b $^X $__FILE__\n};
}
else {
    print qq{ok - 30 \$_ =~ s/a//b $^X $__FILE__\n};
}

$_ = 'ÉA';
if ($_ =~ s/a//i) {
    print qq{not ok - 31 \$_ =~ s/a//i $^X $__FILE__\n};
}
else {
    print qq{ok - 31 \$_ =~ s/a//i $^X $__FILE__\n};
}

$_ = 'ÉA';
if ($_ =~ s/a//ib) {
    print qq{ok - 32 \$_ =~ s/a//ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 32 \$_ =~ s/a//ib $^X $__FILE__\n};
}

$_ = 'Éa';
if ($_ =~ s/A//) {
    print qq{not ok - 33 \$_ =~ s/A// $^X $__FILE__\n};
}
else {
    print qq{ok - 33 \$_ =~ s/A// $^X $__FILE__\n};
}

$_ = 'Éa';
if ($_ =~ s/A//b) {
    print qq{not ok - 34 \$_ =~ s/A//b $^X $__FILE__\n};
}
else {
    print qq{ok - 34 \$_ =~ s/A//b $^X $__FILE__\n};
}

$_ = 'Éa';
if ($_ =~ s/A//i) {
    print qq{not ok - 35 \$_ =~ s/A//i $^X $__FILE__\n};
}
else {
    print qq{ok - 35 \$_ =~ s/A//i $^X $__FILE__\n};
}

$_ = 'Éa';
if ($_ =~ s/A//ib) {
    print qq{ok - 36 \$_ =~ s/A//ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 36 \$_ =~ s/A//ib $^X $__FILE__\n};
}

$_ = 'Éa';
if ($_ =~ s/a//) {
    print qq{not ok - 37 \$_ =~ s/a// $^X $__FILE__\n};
}
else {
    print qq{ok - 37 \$_ =~ s/a// $^X $__FILE__\n};
}

$_ = 'Éa';
if ($_ =~ s/a//b) {
    print qq{ok - 38 \$_ =~ s/a//b $^X $__FILE__\n};
}
else {
    print qq{not ok - 38 \$_ =~ s/a//b $^X $__FILE__\n};
}

$_ = 'Éa';
if ($_ =~ s/a//i) {
    print qq{not ok - 39 \$_ =~ s/a//i $^X $__FILE__\n};
}
else {
    print qq{ok - 39 \$_ =~ s/a//i $^X $__FILE__\n};
}

$_ = 'Éa';
if ($_ =~ s/a//ib) {
    print qq{ok - 40 \$_ =~ s/a//ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 40 \$_ =~ s/a//ib $^X $__FILE__\n};
}

$_ = 'ÉÉA';
if ($_ =~ s/ÉA//) {
    print qq{not ok - 41 \$_ =~ s/ÉA// $^X $__FILE__\n};
}
else {
    print qq{ok - 41 \$_ =~ s/ÉA// $^X $__FILE__\n};
}

$_ = 'ÉÉA';
if ($_ =~ s/ÉA//b) {
    print qq{ok - 42 \$_ =~ s/ÉA//b $^X $__FILE__\n};
}
else {
    print qq{not ok - 42 \$_ =~ s/ÉA//b $^X $__FILE__\n};
}

$_ = 'ÉÉA';
if ($_ =~ s/ÉA//i) {
    print qq{not ok - 43 \$_ =~ s/ÉA//i $^X $__FILE__\n};
}
else {
    print qq{ok - 43 \$_ =~ s/ÉA//i $^X $__FILE__\n};
}

$_ = 'ÉÉA';
if ($_ =~ s/ÉA//ib) {
    print qq{ok - 44 \$_ =~ s/ÉA//ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 44 \$_ =~ s/ÉA//ib $^X $__FILE__\n};
}

$_ = 'ÉÉA';
if ($_ =~ s/Éa//) {
    print qq{not ok - 45 \$_ =~ s/Éa// $^X $__FILE__\n};
}
else {
    print qq{ok - 45 \$_ =~ s/Éa// $^X $__FILE__\n};
}

$_ = 'ÉÉA';
if ($_ =~ s/Éa//b) {
    print qq{not ok - 46 \$_ =~ s/Éa//b $^X $__FILE__\n};
}
else {
    print qq{ok - 46 \$_ =~ s/Éa//b $^X $__FILE__\n};
}

$_ = 'ÉÉA';
if ($_ =~ s/Éa//i) {
    print qq{not ok - 47 \$_ =~ s/Éa//i $^X $__FILE__\n};
}
else {
    print qq{ok - 47 \$_ =~ s/Éa//i $^X $__FILE__\n};
}

$_ = 'ÉÉA';
if ($_ =~ s/Éa//ib) {
    print qq{ok - 48 \$_ =~ s/Éa//ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 48 \$_ =~ s/Éa//ib $^X $__FILE__\n};
}

$_ = 'ÉÉa';
if ($_ =~ s/ÉA//) {
    print qq{not ok - 49 \$_ =~ s/ÉA// $^X $__FILE__\n};
}
else {
    print qq{ok - 49 \$_ =~ s/ÉA// $^X $__FILE__\n};
}

$_ = 'ÉÉa';
if ($_ =~ s/ÉA//b) {
    print qq{not ok - 50 \$_ =~ s/ÉA//b $^X $__FILE__\n};
}
else {
    print qq{ok - 50 \$_ =~ s/ÉA//b $^X $__FILE__\n};
}

$_ = 'ÉÉa';
if ($_ =~ s/ÉA//i) {
    print qq{not ok - 51 \$_ =~ s/ÉA//i $^X $__FILE__\n};
}
else {
    print qq{ok - 51 \$_ =~ s/ÉA//i $^X $__FILE__\n};
}

$_ = 'ÉÉa';
if ($_ =~ s/ÉA//ib) {
    print qq{ok - 52 \$_ =~ s/ÉA//ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 52 \$_ =~ s/ÉA//ib $^X $__FILE__\n};
}

$_ = 'ÉÉa';
if ($_ =~ s/Éa//) {
    print qq{not ok - 53 \$_ =~ s/Éa// $^X $__FILE__\n};
}
else {
    print qq{ok - 53 \$_ =~ s/Éa// $^X $__FILE__\n};
}

$_ = 'ÉÉa';
if ($_ =~ s/Éa//b) {
    print qq{ok - 54 \$_ =~ s/Éa//b $^X $__FILE__\n};
}
else {
    print qq{not ok - 54 \$_ =~ s/Éa//b $^X $__FILE__\n};
}

$_ = 'ÉÉa';
if ($_ =~ s/Éa//i) {
    print qq{not ok - 55 \$_ =~ s/Éa//i $^X $__FILE__\n};
}
else {
    print qq{ok - 55 \$_ =~ s/Éa//i $^X $__FILE__\n};
}

$_ = 'ÉÉa';
if ($_ =~ s/Éa//ib) {
    print qq{ok - 56 \$_ =~ s/Éa//ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 56 \$_ =~ s/Éa//ib $^X $__FILE__\n};
}

__END__

