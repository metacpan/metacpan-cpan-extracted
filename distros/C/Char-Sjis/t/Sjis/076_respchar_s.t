# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use Sjis;
print "1..1\n";

my $__FILE__ = __FILE__;

$a = "アソソ";
if ($a =~ s/(アソソ?)//) {
    if ($1 eq "アソソ") {
        print qq{ok - 1 "アソソ" =~ s/(アソソ?)// \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 "アソソ" =~ s/(アソソ?)// \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 "アソソ" =~ s/(アソソ?)// \$1=($1) $^X $__FILE__\n};
}

__END__
