# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{あ} ne "\x82\xa0";

use HP15;
print "1..4\n";

my $__FILE__ = __FILE__;

#
# chop, chomp
#

$y = "あいう";
$x = chomp($y);
if ($x ne 0 || $y ne "あいう") {
    print "not ok - 1 $^X $__FILE__\n";
}
else {
    print "ok - 1 $^X $__FILE__\n";
}

$y = "あいう\n";
$x = chomp($y);
if ($x ne 1 || $y ne "あいう") {
    print "not ok - 2 $^X $__FILE__\n";
}
else {
    print "ok - 2 $^X $__FILE__\n";
}

$y = "あいう";
$x = chop($y);
if ($x ne "う" || $y ne "あい") {
    print "not ok - 3 $^X $__FILE__\n";
}
else {
    print "ok - 3 $^X $__FILE__\n";
}

$y = "あいうt";
$x = chop($y);
if ($x ne "t" || $y ne "あいう") {
    print "not ok - 4 $^X $__FILE__\n";
}
else {
    print "ok - 4 $^X $__FILE__\n";
}

__END__
