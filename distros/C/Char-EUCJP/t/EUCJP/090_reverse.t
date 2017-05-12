# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;
print "1..2\n";

my $__FILE__ = __FILE__;

@_ = EUCJP::reverse('あいうえお', 'かきくけこ', 'さしすせそ');
if ("@_" eq "さしすせそ かきくけこ あいうえお") {
    print qq{ok - 1 \@_ = EUCJP::reverse('あいうえお', 'かきくけこ', 'さしすせそ') $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \@_ = EUCJP::reverse('あいうえお', 'かきくけこ', 'さしすせそ') $^X $__FILE__\n};
}

$_ = EUCJP::reverse('あいうえお', 'かきくけこ', 'さしすせそ');
if ($_ eq "そせすしさこけくきかおえういあ") {
    print qq{ok - 2 \$_ = EUCJP::reverse('あいうえお', 'かきくけこ', 'さしすせそ') $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ = EUCJP::reverse('あいうえお', 'かきくけこ', 'さしすせそ') $^X $__FILE__\n};
}

__END__
