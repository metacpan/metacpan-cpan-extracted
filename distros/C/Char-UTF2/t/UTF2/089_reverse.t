# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use UTF2;
print "1..2\n";

my $__FILE__ = __FILE__;

@_ = UTF2::reverse('あいうえお', 'かきくけこ', 'さしすせそ');
if ("@_" eq "さしすせそ かきくけこ あいうえお") {
    print qq{ok - 1 \@_ = reverse('あいうえお', 'かきくけこ', 'さしすせそ') $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \@_ = reverse('あいうえお', 'かきくけこ', 'さしすせそ') $^X $__FILE__\n};
}

$_ = UTF2::reverse('あいうえお', 'かきくけこ', 'さしすせそ');
if ($_ eq "そせすしさこけくきかおえういあ") {
    print qq{ok - 2 \$_ = reverse('あいうえお', 'かきくけこ', 'さしすせそ') $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ = reverse('あいうえお', 'かきくけこ', 'さしすせそ') $^X $__FILE__\n};
}

__END__
