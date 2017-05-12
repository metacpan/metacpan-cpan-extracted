# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;

print "1..12\n";

# eval q{...} has eval "..."
if (eval GB18030::escape q{ eval GB18030::escape " if ('傾僜' !~ /A/) { return 1 } else { return 0 } " }) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# eval q{...} has eval qq{...}
if (eval GB18030::escape q{ eval GB18030::escape qq{ if ('傾僜' !~ /A/) { return 1 } else { return 0 } } }) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# eval q{...} has eval '...'
if (eval GB18030::escape q{ eval GB18030::escape ' if ("傾僜" !~ /A/) { return 1 } else { return 0 } ' }) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# eval q{...} has eval q{...}
if (eval GB18030::escape q{ eval GB18030::escape q{ if ('傾僜' !~ /A/) { return 1 } else { return 0 } } }) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# eval q{...} has eval $var
my $var = q{ if ('傾僜' !~ /A/) { return 1 } else { return 0 } };
if (eval GB18030::escape q{ eval GB18030::escape $var }) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# eval q{...} has eval (omit)
$_ = "if ('傾僜' !~ /A/) { return 1 } else { return 0 }";
if (eval GB18030::escape q{ eval GB18030::escape }) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# eval q{...} has eval {...}
if (eval GB18030::escape q{ eval { if ('傾僜' !~ /A/) { return 1 } else { return 0 } } }) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# eval q{...} has "..."
if (eval GB18030::escape q{ if ('傾僜' !~ /A/) { return "1" } else { return "0" } }) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# eval q{...} has qq{...}
if (eval GB18030::escape q{ if ('傾僜' !~ /A/) { return qq{1} } else { return qq{0} } }) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# eval q{...} has '...'
if (eval GB18030::escape q{ if ('傾僜' !~ /A/) { return '1' } else { return '0' } }) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# eval q{...} has q{...}
if (eval GB18030::escape q{ if ('傾僜' !~ /A/) { return q{1} } else { return q{0} } }) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# eval q{...} has $var
my $var1 = 1;
my $var0 = 0;
if (eval GB18030::escape q{ if ('傾僜' !~ /A/) { return $var1 } else { return $var0 } }) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
