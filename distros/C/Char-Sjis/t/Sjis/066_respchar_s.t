# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use Sjis;
print "1..1\n";

my $__FILE__ = __FILE__;

$a = "ソアア";
if ($a =~ s/^ソ//) {
    print qq{ok - 1 "ソアア" =~ s/^ソ// $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "ソアア" =~ s/^ソ// $^X $__FILE__\n};
}

__END__
