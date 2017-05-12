# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{あ} ne "\x82\xa0";

use HP15;
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
