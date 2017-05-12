# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use OldUTF8;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///g
$a = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

if ($a =~ s/CD|JK|UV/あいう/g) {
    if ($a eq "ABあいうEFGHIあいうLMNOPQRSTあいうWXYZ") {
        print qq{ok - 1 \$a =~ s/CD|JK|UV/あいう/g ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/CD|JK|UV/あいう/g ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/CD|JK|UV/あいう/g ($a) $^X $__FILE__\n};
}

__END__
