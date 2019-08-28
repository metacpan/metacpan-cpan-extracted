# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{‚ } ne "\x82\xa0";

use Big5HKSCS;
print "1..5\n";

my $__FILE__ = __FILE__;

#
# tr
#
$y = "‚©‚«‚­‚¯‚±";
$y =~ tr/‚©-‚­//cd;
if ($y ne "‚©‚«‚­") {
    print "not ok - 1 $^X $__FILE__\n";
}
else {
    print "ok - 1 $^X $__FILE__\n";
}

$y = "‚©‚«‚­‚¯‚±";
$y =~ tr/‚©-‚­/‚³-‚·/;
if ($y ne "‚³‚µ‚·‚¯‚±") {
    print "not ok - $^X 2 $__FILE__\n";
}
else {
    print "ok - 2 $^X $__FILE__\n";
}

$y = 'abcabcabc';
$y =~ tr/a-c/d-f/;
if ($y ne 'defdefdef') {
    print "not ok - 3 $^X $__FILE__\n";
}
else {
    print "ok - 3 $^X $__FILE__\n";
}

$y = 'abc';
$y =~ tr/abc/def/;
if ($y ne 'def') {
    print "not ok - 4 $^X $__FILE__\n";
}
else {
    print "ok - 4 $^X $__FILE__\n";
}

$y = 'abcabcabc';
$y =~ tr/abc/def/;
if ($y ne 'defdefdef') {
    print "not ok - 5 $^X $__FILE__\n";
}
else {
    print "ok - 5 $^X $__FILE__\n";
}

__END__
