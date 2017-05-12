# encoding: USASCII
# This file is encoded in US-ASCII.
die "This file is not encoded in US-ASCII.\n" if q{‚ } ne "\x82\xa0";

use USASCII;
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
