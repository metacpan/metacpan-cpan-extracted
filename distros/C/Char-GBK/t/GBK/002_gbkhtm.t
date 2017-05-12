# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..1\n";

# 僄儔乕偵偼側傜側偄偗偳暥帤壔偗偡傞乮侾乯
if ("朶椡" eq pack('C4',0x96,0x5c,0x97,0xcd)) {
    print qq<ok - 1 "BORYOKU"\n>;
}
else {
    print qq<not ok - 1 "BORYOKU"\n>;
}

__END__

GBK.pm 偺張棟寢壥偑埲壓偵側傞偙偲傪婜懸偟偰偄傞

if ("朶\椡" eq pack('C4',0x96,0x5c,0x97,0xcd)) {

Shift-JIS僥僉僗僩傪惓偟偔埖偆
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
