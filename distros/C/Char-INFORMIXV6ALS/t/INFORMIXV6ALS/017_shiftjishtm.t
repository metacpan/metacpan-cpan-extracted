# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

use INFORMIXV6ALS;
print "1..1\n";

# マッチするはずなのにマッチしない（１）
if ("運転免許" =~ /運転/) {
    print qq<ok - 1 "UNTENMENKYO" =~ /UNTEN/\n>;
}
else {
    print qq<not ok - 1 "UNTENMENKYO" =~ /UNTEN/\n>;
}

__END__

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
