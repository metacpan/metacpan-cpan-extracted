# encoding: Hebrew
# This file is encoded in Hebrew.
die "This file is not encoded in Hebrew.\n" if q{ } ne "\x82\xa0";

use Hebrew;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///x 
$a = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
if ($a =~ s/ J K L /©«­/x) {
    if ($a eq "ABCDEFGHI©«­MNOPQRSTUVWXYZ") {
        print qq{ok - 1 \$a =~ s/ J K L /©«­/x ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/ J K L /©«­/x ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/ J K L /©«­/x ($a) $^X $__FILE__\n};
}

__END__
