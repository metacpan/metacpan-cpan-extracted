# encoding: Big5Plus
# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{あ} ne "\x82\xa0";

use Big5Plus;
print "1..1\n";

# エラーにはならないけど文字化けする（３）
if ("丸十net" eq pack('C7',0x8a,0xdb,0x8f,0x5c,0x6e,0x65,0x74)) {
    print qq<ok - 1 "MARU JU net"\n>;
}
else {
    print qq<not ok - 1 "MARU JU net"\n>;
}

__END__

Big5Plus.pm の処理結果が以下になることを期待している

if ("丸十\net" eq pack('C7',0x8a,0xdb,0x8f,0x5c,0x6e,0x65,0x74)) {

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
