# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use OldUTF8;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = 'あいうえおあいうえお';
if (index($_,'うえ') == 6) {
    print qq{ok - 1 index(\$_,'うえ') == 6 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 index(\$_,'うえ') == 6 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (index($_,'うえ',9) == 21) {
    print qq{ok - 2 index(\$_,'うえ',9) == 21 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 index(\$_,'うえ',9) == 21 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (OldUTF8::index($_,'うえ') == 2) {
    print qq{ok - 3 OldUTF8::index(\$_,'うえ') == 2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 OldUTF8::index(\$_,'うえ') == 2 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (OldUTF8::index($_,'うえ',3) == 7) {
    print qq{ok - 4 OldUTF8::index(\$_,'うえ',3) == 7 $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 OldUTF8::index(\$_,'うえ',3) == 7 $^X $__FILE__\n};
}

__END__
