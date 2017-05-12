# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use OldUTF8;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///x ●
$a = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
if ($a =~ s/ J K L /かきく/x) {
    if ($a eq "ABCDEFGHIかきくMNOPQRSTUVWXYZ") {
        print qq{ok - 1 \$a =~ s/ J K L /かきく/x ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/ J K L /かきく/x ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/ J K L /かきく/x ($a) $^X $__FILE__\n};
}

__END__
