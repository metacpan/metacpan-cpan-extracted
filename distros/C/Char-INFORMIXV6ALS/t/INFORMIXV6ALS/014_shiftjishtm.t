# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

use INFORMIXV6ALS;
print "1..1\n";

# Unrecognized character \x82
# 「認識されない文字 \x82」
if (q{マッチ} eq pack('C6',0x83,0x7d,0x83,0x62,0x83,0x60)) {
    print qq<ok - 1 q{MACCHI}\n>;
}
else {
    print qq<not ok - 1 q{MACCHI}\n>;
}

__END__

INFORMIXV6ALS.pm の処理結果が以下になることを期待している

if (q{ソ}ッチ} eq pack('C6',0x83,0x7d,0x83,0x62,0x83,0x60)) {

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
