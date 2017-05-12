# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..1\n";

$_ = '';

# Search pattern not terminated
# 乽僒乕僠僷僞乕儞偑廔椆偟側偄乿
eval { /昞/ };
if ($@) {
    print "not ok - 1 eval { /HYO/ }\n";
}
else {
    print "ok - 1 eval { /HYO/ }\n";
}

__END__

Shift-JIS僥僉僗僩傪惓偟偔埖偆
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
