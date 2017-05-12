# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

use INFORMIXV6ALS;
print "1..1\n";

# エラーにはならないけど文字化けする（１）
if ("暴力" eq pack('C4',0x96,0x5c,0x97,0xcd)) {
    print qq<ok - 1 "BORYOKU"\n>;
}
else {
    print qq<not ok - 1 "BORYOKU"\n>;
}

__END__

INFORMIXV6ALS.pm の処理結果が以下になることを期待している

if ("暴\力" eq pack('C4',0x96,0x5c,0x97,0xcd)) {

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
