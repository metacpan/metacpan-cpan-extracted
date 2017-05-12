# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..1\n";

# 僄儔乕偵偼側傜側偄偗偳暥帤壔偗偡傞乮俆乯
if (lc('傾僀僂僄僆') eq '傾僀僂僄僆') {
    print "ok - 1 lc('傾僀僂僄僆') eq '傾僀僂僄僆'\n";
}
else {
    print "not ok - 1 lc('傾僀僂僄僆') eq '傾僀僂僄僆'\n";
}

__END__

GB18030.pm 偺張棟寢壥偑埲壓偵側傞偙偲傪婜懸偟偰偄傞

if (Egb18030::lc('傾僀僂僄僆') eq '傾僀僂僄僆') {

Shift-JIS僥僉僗僩傪惓偟偔埖偆
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
