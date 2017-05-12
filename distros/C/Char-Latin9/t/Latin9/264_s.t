# encoding: Latin9
# This file is encoded in Latin-9.
die "This file is not encoded in Latin-9.\n" if q{ } ne "\x82\xa0";

use strict;
use Latin9;
print "1..26\n";

my $__FILE__ = __FILE__;

my $d = 'E';
my $c = '$d';
my $b = '$c';

$_ = 'AAA';
s/A/$b/;
if ($_ eq '$cAA') {
    print qq{ok - 1 s/A/\$b/; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 1 s/A/\$b/; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s/A/$b/e;
if ($_ eq '$cAA') {
    print qq{ok - 2 s/A/\$b/e; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 2 s/A/\$b/e; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s/A/$b/ee;
if ($_ eq '$dAA') {
    print qq{ok - 3 s/A/\$b/ee; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 3 s/A/\$b/ee; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s/A/$b/eee;
if ($_ eq 'EAA') {
    print qq{ok - 4 s/A/\$b/eee; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 4 s/A/\$b/eee; $^X $__FILE__ ($_)\n};
}

{
    no strict qw(subs);
    $_ = 'AAA';
    s/A/$b/eeee;
    if ($_ eq 'EAA') {
        print qq{ok - 5 s/A/\$b/eeee; $^X $__FILE__ ($_)($b)\n};
    }
    else {
        print qq{not ok - 5 s/A/\$b/eeee; $^X $__FILE__ ($_)($b)\n};
    }
}

$_ = 'AAA';
s/A/$b/g;
if ($_ eq '$c$c$c') {
    print qq{ok - 6 s/A/\$b/g; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 6 s/A/\$b/g; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s/A/$b/ge;
if ($_ eq '$c$c$c') {
    print qq{ok - 7 s/A/\$b/ge; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 7 s/A/\$b/ge; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s/A/$b/gee;
if ($_ eq '$d$d$d') {
    print qq{ok - 8 s/A/\$b/gee; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 8 s/A/\$b/gee; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s/A/$b/geee;
if ($_ eq 'EEE') {
    print qq{ok - 9 s/A/\$b/geee; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 9 s/A/\$b/geee; $^X $__FILE__ ($_)\n};
}

{
    no strict qw(subs);
    $_ = 'AAA';
    s/A/$b/geeee;
    if ($_ eq 'EEE') {
        print qq{ok - 10 s/A/\$b/geeee; $^X $__FILE__ ($_)\n};
    }
    else {
        print qq{not ok - 10 s/A/\$b/geeee; $^X $__FILE__ ($_)\n};
    }
}

$_ = 'AAA';
s/A/$0/;
if ($_ eq $0.'AA') {
    print qq{ok - 11 s/A/\$0/; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 11 s/A/\$0/; $^X $__FILE__ ($_)\n};
}

$_ = 'ABCABCABC';
s/A(B)(C)/$1/;
if ($_ eq 'BABCABC') {
    print qq{ok - 12 s/A(B)(C)/\$1/; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 12 s/A(B)(C)/\$1/; $^X $__FILE__ ($_)\n};
}

$_ = 'ABCABCABC';
s/A(B)(C)/$2/;
if ($_ eq 'CABCABC') {
    print qq{ok - 13 s/A(B)(C)/\$2/; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 13 s/A(B)(C)/\$2/; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s/A/\\/;
if ($_ eq '\\AA') {
    print qq{ok - 14 s/A/\\\\/; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 14 s/A/\\\\/; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s/A/\n/;
if ($_ eq "\nAA") {
    print qq{ok - 15 s/A/\\n/; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 15 s/A/\\n/; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s/A/\t/;
if ($_ eq "\tAA") {
    print qq{ok - 16 s/A/\\t/; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 16 s/A/\\t/; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s/A/\$/;
if ($_ eq '$AA') {
    print qq{ok - 17 s/A/\\\$/; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 17 s/A/\\\$/; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s/A/\@/;
if ($_ eq '@AA') {
    print qq{ok - 18 s/A/\\\@/; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 18 s/A/\\\@/; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s'A'$b';
if ($_ eq '$bAA') {
    print qq{ok - 19 s'A'\$b'; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 19 s'A'\$b'; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s'A'$b'e;
if ($_ eq '$cAA') {
    print qq{ok - 20 s'A'\$b'e; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 20 s'A'\$b'e; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s'A'$b'ee;
if ($_ eq '$dAA') {
    print qq{ok - 21 s'A'\$b'ee; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 21 s'A'\$b'ee; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s'A'\\';
if ($_ eq '\AA') {
    print qq{ok - 22 s'A'\\'; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 22 s'A'\\'; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s'A'\n';
if ($_ eq '\nAA') {
    print qq{ok - 23 s'A'\\n'; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 23 s'A'\\n'; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s'A'\t';
if ($_ eq '\tAA') {
    print qq{ok - 24 s'A'\\t'; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 24 s'A'\\t'; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s'A'$';
if ($_ eq '$AA') {
    print qq{ok - 25 s'A'\$'; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 25 s'A'\$'; $^X $__FILE__ ($_)\n};
}

$_ = 'AAA';
s'A'@';
if ($_ eq '@AA') {
    print qq{ok - 26 s'A'\@'; $^X $__FILE__ ($_)\n};
}
else {
    print qq{not ok - 26 s'A'\@'; $^X $__FILE__ ($_)\n};
}

__END__
