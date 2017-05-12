# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use Sjis;

print "1..12\n";

# Sjis::eval (omit) has Sjis::eval "..."
$_ = <<'END';
Sjis::eval " if ('アソ' !~ /A/) { return 1 } else { return 0 } "
END
if (Sjis::eval) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Sjis::eval (omit) has Sjis::eval qq{...}
$_ = <<'END';
Sjis::eval qq{ if ('アソ' !~ /A/) { return 1 } else { return 0 } }
END
if (Sjis::eval) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Sjis::eval (omit) has Sjis::eval '...'
$_ = <<'END';
Sjis::eval ' if (qq{アソ} !~ /A/) { return 1 } else { return 0 } '
END
if (Sjis::eval) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Sjis::eval (omit) has Sjis::eval q{...}
$_ = <<'END';
Sjis::eval q{ if ('アソ' !~ /A/) { return 1 } else { return 0 } }
END
if (Sjis::eval) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Sjis::eval (omit) has Sjis::eval $var
$_ = <<'END';
Sjis::eval $var2
END
my $var2 = q{ if ('アソ' !~ /A/) { return 1 } else { return 0 } };
if (Sjis::eval) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Sjis::eval (omit) has Sjis::eval (omit)
$_ = <<'END';
$_ = "if ('アソ' !~ /A/) { return 1 } else { return 0 }";
Sjis::eval
END
if (Sjis::eval) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Sjis::eval (omit) has Sjis::eval {...}
$_ = <<'END';
Sjis::eval { if ('アソ' !~ /A/) { return 1 } else { return 0 } }
END
if (Sjis::eval) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Sjis::eval (omit) has "..."
$_ = <<'END';
if ('アソ' !~ /A/) { return "1" } else { return "0" }
END
if (Sjis::eval) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Sjis::eval (omit) has qq{...}
$_ = <<'END';
if ('アソ' !~ /A/) { return qq{1} } else { return qq{0} }
END
if (Sjis::eval) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Sjis::eval (omit) has '...'
$_ = <<'END';
if ('アソ' !~ /A/) { return '1' } else { return '0' }
END
if (Sjis::eval) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Sjis::eval (omit) has q{...}
$_ = <<'END';
if ('アソ' !~ /A/) { return q{1} } else { return q{0} }
END
if (Sjis::eval) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Sjis::eval (omit) has $var
$_ = <<'END';
if ('アソ' !~ /A/) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (Sjis::eval) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
