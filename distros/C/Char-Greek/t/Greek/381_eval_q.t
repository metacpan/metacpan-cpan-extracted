# encoding: Greek
# This file is encoded in Greek.
die "This file is not encoded in Greek.\n" if q{ } ne "\x82\xa0";

use Greek;

print "1..12\n";

# eval q{...} has eval "..."
if (eval Greek::escape q{ eval Greek::escape " if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } " }) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# eval q{...} has eval qq{...}
if (eval Greek::escape q{ eval Greek::escape qq{ if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } } }) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# eval q{...} has eval '...'
if (eval Greek::escape q{ eval Greek::escape ' if ("ιΑ" =~ /[α]/i) { return 1 } else { return 0 } ' }) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# eval q{...} has eval q{...}
if (eval Greek::escape q{ eval Greek::escape q{ if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } } }) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# eval q{...} has eval $var
my $var = q{ if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } };
if (eval Greek::escape q{ eval Greek::escape $var }) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# eval q{...} has eval (omit)
$_ = "if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 }";
if (eval Greek::escape q{ eval Greek::escape }) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# eval q{...} has eval {...}
if (eval Greek::escape q{ eval { if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } } }) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# eval q{...} has "..."
if (eval Greek::escape q{ if ('ιΑ' =~ /[α]/i) { return "1" } else { return "0" } }) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# eval q{...} has qq{...}
if (eval Greek::escape q{ if ('ιΑ' =~ /[α]/i) { return qq{1} } else { return qq{0} } }) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# eval q{...} has '...'
if (eval Greek::escape q{ if ('ιΑ' =~ /[α]/i) { return '1' } else { return '0' } }) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# eval q{...} has q{...}
if (eval Greek::escape q{ if ('ιΑ' =~ /[α]/i) { return q{1} } else { return q{0} } }) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# eval q{...} has $var
my $var1 = 1;
my $var0 = 0;
if (eval Greek::escape q{ if ('ιΑ' =~ /[α]/i) { return $var1 } else { return $var0 } }) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
