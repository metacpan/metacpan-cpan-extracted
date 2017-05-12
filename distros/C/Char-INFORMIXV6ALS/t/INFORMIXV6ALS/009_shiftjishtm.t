# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

use INFORMIXV6ALS;
print "1..1\n";

# Possible unintended interpolation of @dog in string (Perl 5.6.1以降)
# 文字列の中で、@dogが予期せずに展開される
if ("犬　dog" eq pack('C7',0x8c,0xa2,0x81,0x40,0x64,0x6f,0x67)) {
    print qq<ok - 1 "INU dog"\n>;
}
else {
    print qq<not ok - 1 "INU dog"\n>;
}

__END__

INFORMIXV6ALS.pm の処理結果が以下になることを期待している

if ("犬―@dog" eq pack('C7',0x8c,0xa2,0x81,0x40,0x64,0x6f,0x67)) {

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
