# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{Ç†} ne "\x82\xa0";

use HP15;
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
