# encoding: KOI8U
# This file is encoded in KOI8-U.
die "This file is not encoded in KOI8-U.\n" if q{‚ } ne "\x82\xa0";

use KOI8U;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///m
$a = "ABCDEFG\nHIJKLMNOPQRSTUVWXYZ";
if ($a =~ s/^HI/‚½‚¿‚Â/m) {
    if ($a eq "ABCDEFG\n‚½‚¿‚ÂJKLMNOPQRSTUVWXYZ") {
        print qq{ok - 1 \$a =~ s/^HI/‚½‚¿‚Â/m ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/^HI/‚½‚¿‚Â/m ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/^HI/‚½‚¿‚Â/m ($a) $^X $__FILE__\n};
}

__END__
