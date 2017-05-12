# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = 'あいうえおあいうえお';
if (rindex($_,'いう') == 12) {
    print qq{ok - 1 rindex(\$_,'いう') == 12 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 rindex(\$_,'いう') == 12 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (rindex($_,'いう',10) == 2) {
    print qq{ok - 2 rindex(\$_,'いう',10) == 2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 rindex(\$_,'いう',10) == 2 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (EUCJP::rindex($_,'いう') == 6) {
    print qq{ok - 3 EUCJP::rindex(\$_,'いう') == 6 $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 EUCJP::rindex(\$_,'いう') == 6 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (EUCJP::rindex($_,'いう',5) == 1) {
    print qq{ok - 4 EUCJP::rindex(\$_,'いう',5) == 1 $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 EUCJP::rindex(\$_,'いう',5) == 1 $^X $__FILE__\n};
}

__END__
