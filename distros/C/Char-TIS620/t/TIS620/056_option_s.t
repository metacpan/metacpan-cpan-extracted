# encoding: TIS620
# This file is encoded in TIS-620.
die "This file is not encoded in TIS-620.\n" if q{ } ne "\x82\xa0";

use TIS620;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///m
$a = "ABCDEFG\nHIJKLMNOPQRSTUVWXYZ";
if ($a =~ s/^HI/ฝฟย/m) {
    if ($a eq "ABCDEFG\nฝฟยJKLMNOPQRSTUVWXYZ") {
        print qq{ok - 1 \$a =~ s/^HI/ฝฟย/m ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/^HI/ฝฟย/m ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/^HI/ฝฟย/m ($a) $^X $__FILE__\n};
}

__END__
