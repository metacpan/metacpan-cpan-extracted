# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..1\n";

my $__FILE__ = __FILE__;

$a = "傾僜傾";
if ($a =~ s/(傾僜|僀僜)/$1<$1>/) {
    if ($1 eq "傾僜") {
        print qq{ok - 1 "傾僜傾" =~ s/(傾僜|僀僜)// \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 "傾僜傾" =~ s/(傾僜|僀僜)// \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 "傾僜傾" =~ s/(傾僜|僀僜)// \$1=($1) $^X $__FILE__\n};
}

__END__
