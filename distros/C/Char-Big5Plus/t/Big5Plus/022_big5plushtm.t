# encoding: Big5Plus
# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{あ} ne "\x82\xa0";

use Big5Plus;
print "1..1\n";

# エラーにはならないけど文字化けする（５）
if (lc('アイウエオ') eq 'アイウエオ') {
    print "ok - 1 lc('アイウエオ') eq 'アイウエオ'\n";
}
else {
    print "not ok - 1 lc('アイウエオ') eq 'アイウエオ'\n";
}

__END__

Big5Plus.pm の処理結果が以下になることを期待している

if (Ebig5plus::lc('アイウエオ') eq 'アイウエオ') {

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
