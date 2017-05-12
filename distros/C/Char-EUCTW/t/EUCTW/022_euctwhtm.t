# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{あ} ne "\xa4\xa2";

use EUCTW;
print "1..1\n";

# エラーにはならないけど文字化けする（５）
if (lc('アイウエオ') eq 'アイウエオ') {
    print "ok - 1 lc('アイウエオ') eq 'アイウエオ'\n";
}
else {
    print "not ok - 1 lc('アイウエオ') eq 'アイウエオ'\n";
}

__END__

EUCTW.pm の処理結果が以下になることを期待している

if (lc('アイウエオ') eq 'アイウエオ') {

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
