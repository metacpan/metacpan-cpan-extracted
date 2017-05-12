# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{あ} ne "\x82\xa0";

use HP15;
print "1..1\n";

# マッチしないはずなのにマッチする（１）
if ("ヤカン" =~ /ポット/) {
    print qq<not ok - 1 "YAKAN" =~ /POTTO/\n>;
}
else {
    print qq<ok - 1 "YAKAN" =~ /POTTO/\n>;
}

__END__

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
