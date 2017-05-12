# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{あ} ne "\xa4\xa2";

use EUCTW;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = 'あいうえおあいうえお';
if (index($_,'うえ') == 4) {
    print qq{ok - 1 index(\$_,'うえ') == 4 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 index(\$_,'うえ') == 4 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (index($_,'うえ',6) == 14) {
    print qq{ok - 2 index(\$_,'うえ',6) == 14 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 index(\$_,'うえ',6) == 14 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (EUCTW::index($_,'うえ') == 2) {
    print qq{ok - 3 EUCTW::index(\$_,'うえ') == 2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 EUCTW::index(\$_,'うえ') == 2 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (EUCTW::index($_,'うえ',3) == 7) {
    print qq{ok - 4 EUCTW::index(\$_,'うえ',3) == 7 $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 EUCTW::index(\$_,'うえ',3) == 7 $^X $__FILE__\n};
}

__END__
