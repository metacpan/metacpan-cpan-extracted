# encoding: Latin10
# This file is encoded in Latin-10.
die "This file is not encoded in Latin-10.\n" if q{ } ne "\x82\xa0";

use Latin10;
print "1..3\n";

my $__FILE__ = __FILE__;

$text = 'hnDrxrFQQTTTWFXT|PO|ORF||F';

local $^W = 0;

# 7.7 splitZq(XgReLXg)
@_ = split(/F/, $text);
if (join('', map {"($_)"} @_) eq "(hnDrxr)(QQTTTW)(XT|PO|OR)(||)()") {
    print qq{ok - 1 \@_ = split(/F/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \@_ = split(/F/, \$text); $^X $__FILE__\n};
}

# 7.7 splitZq(XJReLXg)
my $a = split(/F/, $text);
if (join('', map {"($_)"} @_) eq "(hnDrxr)(QQTTTW)(XT|PO|OR)(||)()") {
    print qq{ok - 2 \$a = split(/F/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$a = split(/F/, \$text); $^X $__FILE__\n};
}

# 7.7 splitZq(voidReLXg)
split(/F/, $text);
if (join('', map {"($_)"} @_) eq "(hnDrxr)(QQTTTW)(XT|PO|OR)(||)()") {
    print qq{ok - 3 (void) split(/F/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 (void) split(/F/, \$text); $^X $__FILE__\n};
}

__END__
