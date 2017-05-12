# encoding: TIS620
# This file is encoded in TIS-620.
die "This file is not encoded in TIS-620.\n" if q{ } ne "\x82\xa0";

use strict;
use TIS620;
print "1..32\n";

my $__FILE__ = __FILE__;

$_ = 'AAA';
m/A/;
if ($_ =~ m//) {
    print qq{ok - 1 \$_='AAA'; m/A/; m// $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \$_='AAA'; m/A/; m// $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ m//) {
    print qq{not ok - 2 \$_='BBB'; m// $^X $__FILE__\n};
}
else {
    print qq{ok - 2 \$_='BBB'; m// $^X $__FILE__\n};
}

$_ = 'AAA';
if ($_ =~ s///) {
    print qq{ok - 3 \$_='AAA'; s///; $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 \$_='AAA'; s///; $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ s///) {
    print qq{not ok - 4 \$_='BBB'; s///; $^X $__FILE__\n};
}
else {
    print qq{ok - 4 \$_='BBB'; s///; $^X $__FILE__\n};
}

$_ = 'AAA';
s/A//;
if ($_ =~ m//) {
    print qq{ok - 5 \$_='AAA'; s/A//; m// $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 \$_='AAA'; s/A//; m// $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ m//) {
    print qq{not ok - 6 \$_='BBB'; m// $^X $__FILE__\n};
}
else {
    print qq{ok - 6 \$_='BBB'; m// $^X $__FILE__\n};
}

$_ = 'AAA';
if ($_ =~ s///) {
    print qq{ok - 7 \$_='AAA'; s///; $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 \$_='AAA'; s///; $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ s///) {
    print qq{not ok - 8 \$_='BBB'; s///; $^X $__FILE__\n};
}
else {
    print qq{ok - 8 \$_='BBB'; s///; $^X $__FILE__\n};
}

$_ = 'AAA';
m/A/;
if ($_ =~ m'') {
    print qq{ok - 9 \$_='AAA'; m/A/; m'' $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 \$_='AAA'; m/A/; m'' $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ m'') {
    print qq{not ok - 10 \$_='BBB'; m'' $^X $__FILE__\n};
}
else {
    print qq{ok - 10 \$_='BBB'; m'' $^X $__FILE__\n};
}

$_ = 'AAA';
if ($_ =~ s''') {
    print qq{ok - 11 \$_='AAA'; s'''; $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 \$_='AAA'; s'''; $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ s''') {
    print qq{not ok - 12 \$_='BBB'; s'''; $^X $__FILE__\n};
}
else {
    print qq{ok - 12 \$_='BBB'; s'''; $^X $__FILE__\n};
}

$_ = 'AAA';
s/A//;
if ($_ =~ m'') {
    print qq{ok - 13 \$_='AAA'; s/A//; m'' $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 \$_='AAA'; s/A//; m'' $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ m'') {
    print qq{not ok - 14 \$_='BBB'; m'' $^X $__FILE__\n};
}
else {
    print qq{ok - 14 \$_='BBB'; m'' $^X $__FILE__\n};
}

$_ = 'AAA';
if ($_ =~ s''') {
    print qq{ok - 15 \$_='AAA'; s'''; $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 \$_='AAA'; s'''; $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ s''') {
    print qq{not ok - 16 \$_='BBB'; s'''; $^X $__FILE__\n};
}
else {
    print qq{ok - 16 \$_='BBB'; s'''; $^X $__FILE__\n};
}

$_ = 'AAA';
m'A';
if ($_ =~ m//) {
    print qq{ok - 17 \$_='AAA'; m'A'; m// $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 \$_='AAA'; m'A'; m// $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ m//) {
    print qq{not ok - 18 \$_='BBB'; m// $^X $__FILE__\n};
}
else {
    print qq{ok - 18 \$_='BBB'; m// $^X $__FILE__\n};
}

$_ = 'AAA';
if ($_ =~ s///) {
    print qq{ok - 19 \$_='AAA'; s///; $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 \$_='AAA'; s///; $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ s///) {
    print qq{not ok - 20 \$_='BBB'; s///; $^X $__FILE__\n};
}
else {
    print qq{ok - 20 \$_='BBB'; s///; $^X $__FILE__\n};
}

$_ = 'AAA';
s'A'';
if ($_ =~ m//) {
    print qq{ok - 21 \$_='AAA'; s'A''; m// $^X $__FILE__\n};
}
else {
    print qq{not ok - 21 \$_='AAA'; s'A''; m// $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ m//) {
    print qq{not ok - 22 \$_='BBB'; m// $^X $__FILE__\n};
}
else {
    print qq{ok - 22 \$_='BBB'; m// $^X $__FILE__\n};
}

$_ = 'AAA';
if ($_ =~ s///) {
    print qq{ok - 23 \$_='AAA'; s///; $^X $__FILE__\n};
}
else {
    print qq{not ok - 23 \$_='AAA'; s///; $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ s///) {
    print qq{not ok - 24 \$_='BBB'; s///; $^X $__FILE__\n};
}
else {
    print qq{ok - 24 \$_='BBB'; s///; $^X $__FILE__\n};
}

$_ = 'AAA';
m'A';
if ($_ =~ m'') {
    print qq{ok - 25 \$_='AAA'; m'A'; m'' $^X $__FILE__\n};
}
else {
    print qq{not ok - 25 \$_='AAA'; m'A'; m'' $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ m'') {
    print qq{not ok - 26 \$_='BBB'; m'' $^X $__FILE__\n};
}
else {
    print qq{ok - 26 \$_='BBB'; m'' $^X $__FILE__\n};
}

$_ = 'AAA';
if ($_ =~ s''') {
    print qq{ok - 27 \$_='AAA'; s'''; $^X $__FILE__\n};
}
else {
    print qq{not ok - 27 \$_='AAA'; s'''; $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ s''') {
    print qq{not ok - 28 \$_='BBB'; s'''; $^X $__FILE__\n};
}
else {
    print qq{ok - 28 \$_='BBB'; s'''; $^X $__FILE__\n};
}

$_ = 'AAA';
s'A'';
if ($_ =~ m'') {
    print qq{ok - 29 \$_='AAA'; s'A''; m'' $^X $__FILE__\n};
}
else {
    print qq{not ok - 29 \$_='AAA'; s'A''; m'' $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ m'') {
    print qq{not ok - 30 \$_='BBB'; m'' $^X $__FILE__\n};
}
else {
    print qq{ok - 30 \$_='BBB'; m'' $^X $__FILE__\n};
}

$_ = 'AAA';
if ($_ =~ s''') {
    print qq{ok - 31 \$_='AAA'; s'''; $^X $__FILE__\n};
}
else {
    print qq{not ok - 31 \$_='AAA'; s'''; $^X $__FILE__\n};
}

$_ = 'BBB';
if ($_ =~ s''') {
    print qq{not ok - 32 \$_='BBB'; s'''; $^X $__FILE__\n};
}
else {
    print qq{ok - 32 \$_='BBB'; s'''; $^X $__FILE__\n};
}

__END__

