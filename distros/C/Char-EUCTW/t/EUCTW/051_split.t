# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{¤¢} ne "\xa4\xa2";

use EUCTW;
print "1..6\n";

my $__FILE__ = __FILE__;

# ¡Ö^¡×¤È¤¤¤¦Àµµ¬É½¸½¤ò»È¤Ã¤¿¾ì¹ç

$_ = "£Á£Á£Á\n£Â£Â£Â\n£Ã£Ã£Ã";
@_ = split(m/^/, $_);
if (join('', map {"($_)"} @_) eq "(£Á£Á£Á\n)(£Â£Â£Â\n)(£Ã£Ã£Ã)") {
    print qq{ok - 1 \@_ = split(m/^/, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \@_ = split(m/^/, \$\_) $^X $__FILE__\n};
}

$_ = "£Á£Á£Á1\n2£Â£Â£Â1\n2£Ã£Ã£Ã";
@_ = split(m/^2/, $_);
if (join('', map {"($_)"} @_) eq "(£Á£Á£Á1\n)(£Â£Â£Â1\n)(£Ã£Ã£Ã)") {
    print qq{ok - 2 \@_ = split(m/^2/, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \@_ = split(m/^2/, \$\_) $^X $__FILE__\n};
    print "<<", join('', map {"($_)"} @_), ">>\n";
}

$_ = "£Á£Á£Á1\n2£Â£Â£Â1\n2£Ã£Ã£Ã";
@_ = split(m/^2/m, $_);
if (join('', map {"($_)"} @_) eq "(£Á£Á£Á1\n)(£Â£Â£Â1\n)(£Ã£Ã£Ã)") {
    print qq{ok - 3 \@_ = split(m/^2/m, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 \@_ = split(m/^2/m, \$\_) $^X $__FILE__\n};
    print "<<", join('', map {"($_)"} @_), ">>\n";
}

$_ = "£Á£Á£Á1\n2£Â£Â£Â1\n2£Ã£Ã£Ã";
@_ = split(m/1^/, $_);
if (join('', map {"($_)"} @_) eq "(£Á£Á£Á1\n2£Â£Â£Â1\n2£Ã£Ã£Ã)") {
    print qq{ok - 4 \@_ = split(m/1^/, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 \@_ = split(m/1^/, \$\_) $^X $__FILE__\n};
}

$_ = "£Á£Á£Á1\n2£Â£Â£Â1\n2£Ã£Ã£Ã";
@_ = split(m/1\n^2/, $_);
if (join('', map {"($_)"} @_) eq "(£Á£Á£Á)(£Â£Â£Â)(£Ã£Ã£Ã)") {
    print qq{ok - 5 \@_ = split(m/1\\n^2/, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 \@_ = split(m/1\\n^2/, \$\_) $^X $__FILE__\n};
    print "<<", join('', map {"($_)"} @_), ">>\n";
}

$_ = "£Á£Á£Á1\n2£Â£Â£Â1\n2£Ã£Ã£Ã";
@_ = split(m/1\n^2/m, $_);
if (join('', map {"($_)"} @_) eq "(£Á£Á£Á)(£Â£Â£Â)(£Ã£Ã£Ã)") {
    print qq{ok - 6 \@_ = split(m/1\\n^2/m, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 \@_ = split(m/1\\n^2/m, \$\_) $^X $__FILE__\n};
    print "<<", join('', map {"($_)"} @_), ">>\n";
}

__END__
