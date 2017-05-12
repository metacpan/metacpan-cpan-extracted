# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..1\n";

# In string, @dog now must be written as \@dog (Perl 5.6.0傑偱)
# 乽暥帤楍偺拞偱偼丄@dog偼崱偼\@dog偲彂偐側偗傟偽側傜側偄乿
if ("將丂dog" eq pack('C7',0x8c,0xa2,0x81,0x40,0x64,0x6f,0x67)) {
    print qq<ok - 1 "INU dog"\n>;
}
else {
    print qq<not ok - 1 "INU dog"\n>;
}

__END__

GBK.pm 偺張棟寢壥偑埲壓偵側傞偙偲傪婜懸偟偰偄傞

if ("將乗@dog" eq pack('C7',0x8c,0xa2,0x81,0x40,0x64,0x6f,0x67)) {

Shift-JIS僥僉僗僩傪惓偟偔埖偆
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
