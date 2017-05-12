# encoding: JIS8
# This file is encoded in JIS8.
die "This file is not encoded in JIS8.\n" if q{Ç†} ne "\x82\xa0";

use JIS8;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///x Åú
$a = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
if ($a =~ s/ J K L /Ç©Ç´Ç≠/x) {
    if ($a eq "ABCDEFGHIÇ©Ç´Ç≠MNOPQRSTUVWXYZ") {
        print qq{ok - 1 \$a =~ s/ J K L /Ç©Ç´Ç≠/x ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/ J K L /Ç©Ç´Ç≠/x ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/ J K L /Ç©Ç´Ç≠/x ($a) $^X $__FILE__\n};
}

__END__
