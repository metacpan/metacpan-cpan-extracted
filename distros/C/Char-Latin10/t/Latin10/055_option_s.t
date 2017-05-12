# encoding: Latin10
# This file is encoded in Latin-10.
die "This file is not encoded in Latin-10.\n" if q{‚ } ne "\x82\xa0";

use Latin10;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///s
$a = "ABCDEFG\nHIJKLMNOPQRSTUVWXYZ";
if ($a =~ s/FG.HI/‚³‚µ‚·/s) {
    if ($a eq "ABCDE‚³‚µ‚·JKLMNOPQRSTUVWXYZ") {
        print qq{ok - 1 \$a =~ s/FG.HI/‚³‚µ‚·/s ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/FG.HI/‚³‚µ‚·/s ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/FG.HI/‚³‚µ‚·/s ($a) $^X $__FILE__\n};
}

__END__
