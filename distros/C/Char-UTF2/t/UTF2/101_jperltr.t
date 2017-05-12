# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use UTF2;
print "1..5\n";

my $__FILE__ = __FILE__;

#
# tr
#
$y = "あいうえお";
$y =~ tr/あ-う//cd;
if ($y ne "あいう") {
    print "not ok - 1 $^X $__FILE__\n";
}
else {
    print "ok - 1 $^X $__FILE__\n";
}

$y = "あいうえお";
$y =~ tr/あ-う/か-く/;
if ($y ne "かきくえお") {
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
