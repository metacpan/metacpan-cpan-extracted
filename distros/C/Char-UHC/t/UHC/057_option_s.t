# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

use UHC;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///g
$a = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

if ($a =~ s/CD|JK|UV/궇궋궎/g) {
    if ($a eq "AB궇궋궎EFGHI궇궋궎LMNOPQRST궇궋궎WXYZ") {
        print qq{ok - 1 \$a =~ s/CD|JK|UV/궇궋궎/g ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/CD|JK|UV/궇궋궎/g ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/CD|JK|UV/궇궋궎/g ($a) $^X $__FILE__\n};
}

__END__
