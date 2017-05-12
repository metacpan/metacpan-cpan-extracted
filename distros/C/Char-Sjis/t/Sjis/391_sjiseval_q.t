# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use Sjis;

print "1..12\n";

# Sjis::eval q{...} has Sjis::eval "..."
if (Sjis::eval q{ Sjis::eval " if ('アソ' !~ /A/) { return 1 } else { return 0 } " }) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Sjis::eval q{...} has Sjis::eval qq{...}
if (Sjis::eval q{ Sjis::eval qq{ if ('アソ' !~ /A/) { return 1 } else { return 0 } } }) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Sjis::eval q{...} has Sjis::eval '...'
if (Sjis::eval q{ Sjis::eval ' if ("アソ" !~ /A/) { return 1 } else { return 0 } ' }) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Sjis::eval q{...} has Sjis::eval q{...}
if (Sjis::eval q{ Sjis::eval q{ if ('アソ' !~ /A/) { return 1 } else { return 0 } } }) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Sjis::eval q{...} has Sjis::eval $var
my $var = q{ if ('アソ' !~ /A/) { return 1 } else { return 0 } };
if (Sjis::eval q{ Sjis::eval $var }) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Sjis::eval q{...} has Sjis::eval (omit)
$_ = "if ('アソ' !~ /A/) { return 1 } else { return 0 }";
if (Sjis::eval q{ Sjis::eval }) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Sjis::eval q{...} has Sjis::eval {...}
if (Sjis::eval q{ Sjis::eval { if ('アソ' !~ /A/) { return 1 } else { return 0 } } }) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Sjis::eval q{...} has "..."
if (Sjis::eval q{ if ('アソ' !~ /A/) { return "1" } else { return "0" } }) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Sjis::eval q{...} has qq{...}
if (Sjis::eval q{ if ('アソ' !~ /A/) { return qq{1} } else { return qq{0} } }) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Sjis::eval q{...} has '...'
if (Sjis::eval q{ if ('アソ' !~ /A/) { return '1' } else { return '0' } }) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Sjis::eval q{...} has q{...}
if (Sjis::eval q{ if ('アソ' !~ /A/) { return q{1} } else { return q{0} } }) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Sjis::eval q{...} has $var
my $var1 = 1;
my $var0 = 0;
if (Sjis::eval q{ if ('アソ' !~ /A/) { return $var1 } else { return $var0 } }) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
