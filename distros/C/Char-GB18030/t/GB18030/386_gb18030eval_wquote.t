# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;

print "1..12\n";

# GB18030::eval "..." has GB18030::eval "..."
if (GB18030::eval " GB18030::eval \" if ('傾僜' !~ /A/) { return 1 } else { return 0 } \" ") {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# GB18030::eval "..." has GB18030::eval qq{...}
if (GB18030::eval " GB18030::eval qq{ if ('傾僜' !~ /A/) { return 1 } else { return 0 } } ") {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# GB18030::eval "..." has GB18030::eval '...'
if (GB18030::eval " GB18030::eval ' if (qq{傾僜} !~ /A/) { return 1 } else { return 0 } ' ") {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# GB18030::eval "..." has GB18030::eval q{...}
if (GB18030::eval " GB18030::eval q{ if ('傾僜' !~ /A/) { return 1 } else { return 0 } } ") {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# GB18030::eval "..." has GB18030::eval $var
my $var = q{q{ if ('傾僜' !~ /A/) { return 1 } else { return 0 } }};
if (GB18030::eval " GB18030::eval $var ") {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# GB18030::eval "..." has GB18030::eval (omit)
$_ = "if ('傾僜' !~ /A/) { return 1 } else { return 0 }";
if (GB18030::eval " GB18030::eval ") {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# GB18030::eval "..." has GB18030::eval {...}
if (GB18030::eval " GB18030::eval { if ('傾僜' !~ /A/) { return 1 } else { return 0 } } ") {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# GB18030::eval "..." has "..."
if (GB18030::eval " if ('傾僜' !~ /A/) { return \"1\" } else { return \"0\" } ") {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# GB18030::eval "..." has qq{...}
if (GB18030::eval " if ('傾僜' !~ /A/) { return qq{1} } else { return qq{0} } ") {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# GB18030::eval "..." has '...'
if (GB18030::eval " if ('傾僜' !~ /A/) { return '1' } else { return '0' } ") {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# GB18030::eval "..." has q{...}
if (GB18030::eval " if ('傾僜' !~ /A/) { return q{1} } else { return q{0} } ") {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# GB18030::eval "..." has $var
my $var1 = 1;
my $var0 = 0;
if (GB18030::eval " if ('傾僜' !~ /A/) { return $var1 } else { return $var0 } ") {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
