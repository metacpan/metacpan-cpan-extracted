# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///g
$a = "ABCDEFGHIJCLMNOPQRSTUVWXYZ";

if ($a =~ s/[CC]/偁偄偆/g) {
    if ($a eq "AB偁偄偆DEFGHIJ偁偄偆LMNOPQRSTUVWXYZ") {
        print qq{ok - 1 \$a =~ s/[CC]/偁偄偆/g ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/[CC]/偁偄偆/g ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/[CC]/偁偄偆/g ($a) $^X $__FILE__\n};
}

__END__
