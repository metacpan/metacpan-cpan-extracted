# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..2\n";

my $__FILE__ = __FILE__;

@_ = GBK::reverse('偁偄偆偊偍', '偐偒偔偗偙', '偝偟偡偣偦');
if ("@_" eq "偝偟偡偣偦 偐偒偔偗偙 偁偄偆偊偍") {
    print qq{ok - 1 \@_ = GBK::reverse('偁偄偆偊偍', '偐偒偔偗偙', '偝偟偡偣偦') $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \@_ = GBK::reverse('偁偄偆偊偍', '偐偒偔偗偙', '偝偟偡偣偦') $^X $__FILE__\n};
}

$_ = GBK::reverse('偁偄偆偊偍', '偐偒偔偗偙', '偝偟偡偣偦');
if ($_ eq "偦偣偡偟偝偙偗偔偒偐偍偊偆偄偁") {
    print qq{ok - 2 \$_ = GBK::reverse('偁偄偆偊偍', '偐偒偔偗偙', '偝偟偡偣偦') $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ = GBK::reverse('偁偄偆偊偍', '偐偒偔偗偙', '偝偟偡偣偦') $^X $__FILE__\n};
}

__END__
