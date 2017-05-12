# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;

print "1..12\n";

# GBK::eval "..." has GBK::eval "..."
if (GBK::eval " GBK::eval \" if ('傾僜' !~ /A/) { return 1 } else { return 0 } \" ") {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# GBK::eval "..." has GBK::eval qq{...}
if (GBK::eval " GBK::eval qq{ if ('傾僜' !~ /A/) { return 1 } else { return 0 } } ") {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# GBK::eval "..." has GBK::eval '...'
if (GBK::eval " GBK::eval ' if (qq{傾僜} !~ /A/) { return 1 } else { return 0 } ' ") {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# GBK::eval "..." has GBK::eval q{...}
if (GBK::eval " GBK::eval q{ if ('傾僜' !~ /A/) { return 1 } else { return 0 } } ") {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# GBK::eval "..." has GBK::eval $var
my $var = q{q{ if ('傾僜' !~ /A/) { return 1 } else { return 0 } }};
if (GBK::eval " GBK::eval $var ") {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# GBK::eval "..." has GBK::eval (omit)
$_ = "if ('傾僜' !~ /A/) { return 1 } else { return 0 }";
if (GBK::eval " GBK::eval ") {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# GBK::eval "..." has GBK::eval {...}
if (GBK::eval " GBK::eval { if ('傾僜' !~ /A/) { return 1 } else { return 0 } } ") {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# GBK::eval "..." has "..."
if (GBK::eval " if ('傾僜' !~ /A/) { return \"1\" } else { return \"0\" } ") {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# GBK::eval "..." has qq{...}
if (GBK::eval " if ('傾僜' !~ /A/) { return qq{1} } else { return qq{0} } ") {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# GBK::eval "..." has '...'
if (GBK::eval " if ('傾僜' !~ /A/) { return '1' } else { return '0' } ") {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# GBK::eval "..." has q{...}
if (GBK::eval " if ('傾僜' !~ /A/) { return q{1} } else { return q{0} } ") {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# GBK::eval "..." has $var
my $var1 = 1;
my $var0 = 0;
if (GBK::eval " if ('傾僜' !~ /A/) { return $var1 } else { return $var0 } ") {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
