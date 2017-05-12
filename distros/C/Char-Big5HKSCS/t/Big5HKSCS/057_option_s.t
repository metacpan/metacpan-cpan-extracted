# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{‚ } ne "\x82\xa0";

use Big5HKSCS;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///g
$a = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

if ($a =~ s/CD|JK|UV/‚ ‚¢‚¤/g) {
    if ($a eq "AB‚ ‚¢‚¤EFGHI‚ ‚¢‚¤LMNOPQRST‚ ‚¢‚¤WXYZ") {
        print qq{ok - 1 \$a =~ s/CD|JK|UV/‚ ‚¢‚¤/g ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/CD|JK|UV/‚ ‚¢‚¤/g ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/CD|JK|UV/‚ ‚¢‚¤/g ($a) $^X $__FILE__\n};
}

__END__
