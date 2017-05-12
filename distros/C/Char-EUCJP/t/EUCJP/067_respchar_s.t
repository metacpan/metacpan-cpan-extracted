# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;
print "1..1\n";

my $__FILE__ = __FILE__;

$a = "アソア";
if ($a !~ s/^ソ//) {
    print qq{ok - 1 "アソア" !~ s/^ソ// $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "アソア" !~ s/^ソ// $^X $__FILE__\n};
}

__END__
