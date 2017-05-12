# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{あ} ne "\xa4\xa2";

use EUCTW;
print "1..2\n";

my $__FILE__ = __FILE__;

if (length('あいうえお') == 10) {
    print qq{ok - 1 length('あいうえお') == 10 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 length('あいうえお') == 10 $^X $__FILE__\n};
}

if (EUCTW::length('あいうえお') == 5) {
    print qq{ok - 2 EUCTW::length('あいうえお') == 5 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 EUCTW::length('あいうえお') == 5 $^X $__FILE__\n};
}

__END__
