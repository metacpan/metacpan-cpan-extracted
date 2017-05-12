# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..1\n";

# 僄儔乕偵偼側傜側偄偗偳暥帤壔偗偡傞乮俆乯
if (lc('傾僀僂僄僆') eq '傾僀僂僄僆') {
    print "ok - 1 lc('傾僀僂僄僆') eq '傾僀僂僄僆'\n";
}
else {
    print "not ok - 1 lc('傾僀僂僄僆') eq '傾僀僂僄僆'\n";
}

__END__

GBK.pm 偺張棟寢壥偑埲壓偵側傞偙偲傪婜懸偟偰偄傞

if (Egbk::lc('傾僀僂僄僆') eq '傾僀僂僄僆') {

Shift-JIS僥僉僗僩傪惓偟偔埖偆
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
