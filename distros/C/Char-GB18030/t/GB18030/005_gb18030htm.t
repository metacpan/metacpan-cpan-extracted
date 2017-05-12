# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..1\n";

# 僄儔乕偵偼側傜側偄偗偳暥帤壔偗偡傞乮俁乯
if ("娵廫net" eq pack('C7',0x8a,0xdb,0x8f,0x5c,0x6e,0x65,0x74)) {
    print qq<ok - 1 "MARU JU net"\n>;
}
else {
    print qq<not ok - 1 "MARU JU net"\n>;
}

__END__

GB18030.pm 偺張棟寢壥偑埲壓偵側傞偙偲傪婜懸偟偰偄傞

if ("娵廫\net" eq pack('C7',0x8a,0xdb,0x8f,0x5c,0x6e,0x65,0x74)) {

Shift-JIS僥僉僗僩傪惓偟偔埖偆
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
