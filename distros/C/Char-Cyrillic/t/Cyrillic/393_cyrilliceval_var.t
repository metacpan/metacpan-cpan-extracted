# encoding: Cyrillic
# This file is encoded in Cyrillic.
die "This file is not encoded in Cyrillic.\n" if q{ } ne "\x82\xa0";

use Cyrillic;

print "1..12\n";

my $var = '';

# Cyrillic::eval $var has Cyrillic::eval "..."
$var = <<'END';
Cyrillic::eval " if ('щС' =~ /[с]/i) { return 1 } else { return 0 } "
END
if (Cyrillic::eval $var) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Cyrillic::eval $var has Cyrillic::eval qq{...}
$var = <<'END';
Cyrillic::eval qq{ if ('щС' =~ /[с]/i) { return 1 } else { return 0 } }
END
if (Cyrillic::eval $var) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Cyrillic::eval $var has Cyrillic::eval '...'
$var = <<'END';
Cyrillic::eval ' if (qq{щС} =~ /[с]/i) { return 1 } else { return 0 } '
END
if (Cyrillic::eval $var) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Cyrillic::eval $var has Cyrillic::eval q{...}
$var = <<'END';
Cyrillic::eval q{ if ('щС' =~ /[с]/i) { return 1 } else { return 0 } }
END
if (Cyrillic::eval $var) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Cyrillic::eval $var has Cyrillic::eval $var
$var = <<'END';
Cyrillic::eval $var2
END
my $var2 = q{ if ('щС' =~ /[с]/i) { return 1 } else { return 0 } };
if (Cyrillic::eval $var) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Cyrillic::eval $var has Cyrillic::eval (omit)
$var = <<'END';
Cyrillic::eval
END
$_ = "if ('щС' =~ /[с]/i) { return 1 } else { return 0 }";
if (Cyrillic::eval $var) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Cyrillic::eval $var has Cyrillic::eval {...}
$var = <<'END';
Cyrillic::eval { if ('щС' =~ /[с]/i) { return 1 } else { return 0 } }
END
if (Cyrillic::eval $var) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Cyrillic::eval $var has "..."
$var = <<'END';
if ('щС' =~ /[с]/i) { return "1" } else { return "0" }
END
if (Cyrillic::eval $var) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Cyrillic::eval $var has qq{...}
$var = <<'END';
if ('щС' =~ /[с]/i) { return qq{1} } else { return qq{0} }
END
if (Cyrillic::eval $var) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Cyrillic::eval $var has '...'
$var = <<'END';
if ('щС' =~ /[с]/i) { return '1' } else { return '0' }
END
if (Cyrillic::eval $var) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Cyrillic::eval $var has q{...}
$var = <<'END';
if ('щС' =~ /[с]/i) { return q{1} } else { return q{0} }
END
if (Cyrillic::eval $var) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Cyrillic::eval $var has $var
$var = <<'END';
if ('щС' =~ /[с]/i) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (Cyrillic::eval $var) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
