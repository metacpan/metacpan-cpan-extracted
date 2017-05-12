# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use OldUTF8;
print "1..2\n";

my $__FILE__ = __FILE__;

if (length('あいうえお') == 15) {
    print qq{ok - 1 length('あいうえお') == 15 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 length('あいうえお') == 15 $^X $__FILE__\n};
}

if (OldUTF8::length('あいうえお') == 5) {
    print qq{ok - 2 OldUTF8::length('あいうえお') == 5 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 OldUTF8::length('あいうえお') == 5 $^X $__FILE__\n};
}

__END__
