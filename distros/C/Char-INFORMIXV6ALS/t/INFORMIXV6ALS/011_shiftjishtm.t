# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

use INFORMIXV6ALS;
print "1..1\n";

# Can't find string terminator '"' anywhere before EOF
# 「終端文字 '"'がファイルの終り EOF までに見つからなかった」
if (qq{"日本語"} eq pack('C8',0x22,0x93,0xfa,0x96,0x7b,0x8c,0xea,0x22)) {
    print qq<ok - 1 qq{"NIHONGO"}\n>;
}
else {
    print qq<not ok - 1 qq{"NIHONGO"}\n>;
}

__END__

INFORMIXV6ALS.pm の処理結果が以下になることを期待している

if (qq{"日暴{語"} eq pack('C8',0x22,0x93,0xfa,0x96,0x7b,0x8c,0xea,0x22)) {

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
