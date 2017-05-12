# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..1\n";

# Unrecognized character \x82
# 乽擣幆偝傟側偄暥帤 \x82乿
if (join('',"懳墳昞", "側傫偱傕偄偄偗偳") eq join('',pack('C6',0x91,0xce,0x89,0x9e,0x95,0x5c),"側傫偱傕偄偄偗偳")) {
    print qq<ok - 1 "TAIOUHYO","NANDEMOIIKEDO"\n>;
}
else {
    print qq<not ok - 1 "TAIOUHYO","NANDEMOIIKEDO"\n>;
}

__END__

GBK.pm 偺張棟寢壥偑埲壓偵側傞偙偲傪婜懸偟偰偄傞

if (join('',"懳墳昞\", "側傫偱傕偄偄偗偳") eq join('',pack('C6',0x91,0xce,0x89,0x9e,0x95,0x5c),"側傫偱傕偄偄偗偳")) {

Shift-JIS僥僉僗僩傪惓偟偔埖偆
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
