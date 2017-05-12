# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = '偁偄偆偊偍偁偄偆偊偍';
if (rindex($_,'偄偆') == 12) {
    print qq{ok - 1 rindex(\$_,'偄偆') == 12 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 rindex(\$_,'偄偆') == 12 $^X $__FILE__\n};
}

$_ = '偁偄偆偊偍偁偄偆偊偍';
if (rindex($_,'偄偆',10) == 2) {
    print qq{ok - 2 rindex(\$_,'偄偆',10) == 2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 rindex(\$_,'偄偆',10) == 2 $^X $__FILE__\n};
}

$_ = '偁偄偆偊偍偁偄偆偊偍';
if (GBK::rindex($_,'偄偆') == 6) {
    print qq{ok - 3 GBK::rindex(\$_,'偄偆') == 6 $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 GBK::rindex(\$_,'偄偆') == 6 $^X $__FILE__\n};
}

$_ = '偁偄偆偊偍偁偄偆偊偍';
if (GBK::rindex($_,'偄偆',5) == 1) {
    print qq{ok - 4 GBK::rindex(\$_,'偄偆',5) == 1 $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 GBK::rindex(\$_,'偄偆',5) == 1 $^X $__FILE__\n};
}

__END__
