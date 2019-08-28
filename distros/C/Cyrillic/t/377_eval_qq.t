# encoding: Cyrillic
# This file is encoded in Cyrillic.
die "This file is not encoded in Cyrillic.\n" if q{ } ne "\x82\xa0";

use Cyrillic;

print "1..12\n";

# eval qq{...} has eval "..."
if (eval Cyrillic::escape qq{ eval Cyrillic::escape " if ('щС' =~ /[с]/i) { return 1 } else { return 0 } " }) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# eval qq{...} has eval qq{...}
if (eval Cyrillic::escape qq{ eval Cyrillic::escape qq{ if ('щС' =~ /[с]/i) { return 1 } else { return 0 } } }) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# eval qq{...} has eval '...'
if (eval Cyrillic::escape qq{ eval Cyrillic::escape ' if (qq{щС} =~ /[с]/i) { return 1 } else { return 0 } ' }) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# eval qq{...} has eval q{...}
if (eval Cyrillic::escape qq{ eval Cyrillic::escape q{ if ('щС' =~ /[с]/i) { return 1 } else { return 0 } } }) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# eval qq{...} has eval $var
my $var = q{q{ if ('щС' =~ /[с]/i) { return 1 } else { return 0 } }};
if (eval Cyrillic::escape qq{ eval Cyrillic::escape $var }) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# eval qq{...} has eval (omit)
$_ = "if ('щС' =~ /[с]/i) { return 1 } else { return 0 }";
if (eval Cyrillic::escape qq{ eval Cyrillic::escape }) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# eval qq{...} has eval {...}
if (eval Cyrillic::escape qq{ eval { if ('щС' =~ /[с]/i) { return 1 } else { return 0 } } }) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# eval qq{...} has "..."
if (eval Cyrillic::escape qq{ if ('щС' =~ /[с]/i) { return "1" } else { return "0" } }) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# eval qq{...} has qq{...}
if (eval Cyrillic::escape qq{ if ('щС' =~ /[с]/i) { return qq{1} } else { return qq{0} } }) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# eval qq{...} has '...'
if (eval Cyrillic::escape qq{ if ('щС' =~ /[с]/i) { return '1' } else { return '0' } }) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# eval qq{...} has q{...}
if (eval Cyrillic::escape qq{ if ('щС' =~ /[с]/i) { return q{1} } else { return q{0} } }) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# eval qq{...} has $var
my $var1 = 1;
my $var0 = 0;
if (eval Cyrillic::escape qq{ if ('щС' =~ /[с]/i) { return $var1 } else { return $var0 } }) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
