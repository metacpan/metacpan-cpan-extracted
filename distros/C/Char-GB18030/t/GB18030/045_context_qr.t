# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{あ} ne "\x82\xa0";

use GB18030;
print "1..2\n";

my $__FILE__ = __FILE__;

# /g なしのスカラーコンテキスト
my $success = "アソア" =~ qr/ソ/;
if ($success) {
    print qq{ok - 1 "アソア" =~ qr/ソ/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "アソア" =~ qr/ソ/ $^X $__FILE__\n};
}

# /g なしのリストコンテキスト
if (my($c1,$c2,$c3,$c4) = "サシスセソタチツテト" =~ qr/^...(.)(.)(.)(.)...$/) {
    if ("($c1)($c2)($c3)($c4)" eq "(セ)(ソ)(タ)(チ)") {
        print "ok - 2 ($c1)($c2)($c3)($c4) $^X $__FILE__\n";
    }
    else {
        print "not ok - 2 ($c1)($c2)($c3)($c4) $^X $__FILE__\n";
    }
}
else {
    print "not ok - 2 ($c1)($c2)($c3)($c4) $^X $__FILE__\n";
}

__END__
