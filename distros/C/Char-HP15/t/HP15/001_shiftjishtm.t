# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{あ} ne "\x82\xa0";

use HP15;
print "1..1\n";

# エラーにはならないけど文字化けする（１）
if ("表示" eq pack('C4',0x95,0x5c,0x8e,0xa6)) {
    print qq<ok - 1 "HYOUJI"\n>;
}
else {
    print qq<not ok - 1 "HYOUJI"\n>;
}

__END__

HP15.pm の処理結果が以下になることを期待している

if ("表\示" eq pack('C4',0x95,0x5c,0x8e,0xa6)) {

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
