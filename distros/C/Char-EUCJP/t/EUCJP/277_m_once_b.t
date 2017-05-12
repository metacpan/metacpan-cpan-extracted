# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use strict;
use EUCJP;
print "1..4\n";

my $__FILE__ = __FILE__;

if ('、◆' =~ ?□?) {
    print qq{not ok - 1 '、◆' =~ ?□? $^X $__FILE__\n};
}
else {
    print qq{ok - 1 '、◆' =~ ?□? $^X $__FILE__\n};
}

if ('、◆' =~ ?□?b) {
    print qq{ok - 2 '、◆' =~ ?□?b $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 '、◆' =~ ?□?b $^X $__FILE__\n};
}

if ('、◆' =~ ?□?i) {
    print qq{not ok - 3 '、◆' =~ ?□?i $^X $__FILE__\n};
}
else {
    print qq{ok - 3 '、◆' =~ ?□?i $^X $__FILE__\n};
}

if ('、◆' =~ ?□?ib) {
    print qq{ok - 4 '、◆' =~ ?□?ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 '、◆' =~ ?□?ib $^X $__FILE__\n};
}

__END__

