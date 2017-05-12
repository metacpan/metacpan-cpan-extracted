# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use Sjis;
print "1..1\n";

# エラーにはならないけど文字化けする（２）
if ('ミソ\500' eq pack('C8',0x83,0x7e,0x83,0x5c,0x5c,0x35,0x30,0x30)) {
    print "ok - 1 'MISO 500yen'\n";
}
else {
    print "not ok - 1 'MISO 500yen'\n";
}

__END__

Sjis.pm の処理結果が以下になることを期待している

if ('ミソ\\500' eq pack('C8',0x83,0x7e,0x83,0x5c,0x5c,0x35,0x30,0x30)) {

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
