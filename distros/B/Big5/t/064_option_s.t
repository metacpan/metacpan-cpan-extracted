# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{あ} ne "\x82\xa0";

use Big5;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///g
$a = "あいうえおかきくけこさしすせそ";

if ($a =~ s/[おこ]/アイウ/g) {
    if ($a eq "あいうえアイウかきくけアイウさしすせそ") {
        print qq{ok - 1 \$a =~ s/[おこ]/アイウ/g ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/[おこ]/アイウ/g ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/[おこ]/アイウ/g ($a) $^X $__FILE__\n};
}

__END__
