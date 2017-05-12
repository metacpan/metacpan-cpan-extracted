# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..1\n";

my $__FILE__ = __FILE__;

# 屻撉傒尵柧 (椺偊偽 C<(?<=[A-Z])>) 偑捈慜偺擇僶僀僩暥帤偺戞擇僶僀僩偵
# 岆偭偰儅僢僠偡傞偙偲偵偼懳張偝傟偰偄傑偣傫丅
# 椺偊偽丄 C<match("傾僀僂", '(?<=[A-Z])(\p{Kana})')> 偼 C<('僀')>
# 傪曉偟傑偡偑丄傕偪傠傫岆傝偱偡丅

if ('傾僀僂' =~ /(?<=[A-Z])([傾僀僂])/) {
    print "ok - 1 # SKIP $^X $__FILE__ ('傾僀僂' =~ /(?<=[A-Z])([傾僀僂])/)($1)\n";
}
else {
    print "ok - 1 $^X $__FILE__ ('傾僀僂' =~ /(?<=[A-Z])([傾僀僂])/)()\n";
}

__END__

