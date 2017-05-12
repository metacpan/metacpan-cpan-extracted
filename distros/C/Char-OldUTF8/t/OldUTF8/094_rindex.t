# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use OldUTF8;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = 'あいうえおあいうえお';
if (rindex($_,'いう') == 18) {
    print qq{ok - 1 rindex(\$_,'いう') == 18 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 rindex(\$_,'いう') == 18 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (rindex($_,'いう',15) == 3) {
    print qq{ok - 2 rindex(\$_,'いう',15) == 3 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 rindex(\$_,'いう',15) == 3 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (OldUTF8::rindex($_,'いう') == 6) {
    print qq{ok - 3 OldUTF8::rindex(\$_,'いう') == 6 $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 OldUTF8::rindex(\$_,'いう') == 6 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (OldUTF8::rindex($_,'いう',5) == 1) {
    print qq{ok - 4 OldUTF8::rindex(\$_,'いう',5) == 1 $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 OldUTF8::rindex(\$_,'いう',5) == 1 $^X $__FILE__\n};
}

__END__
