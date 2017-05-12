# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{あ} ne "\x82\xa0";

use UHC;
print "1..1\n";

# マッチしないはずなのにマッチする（２）
if ("兄弟" =~ /Z/) {
    print qq<not ok - 1 "KYODAI" =~ /Z/\n>;
}
else {
    print qq<ok - 1 "KYODAI" =~ /Z/\n>;
}

__END__

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
