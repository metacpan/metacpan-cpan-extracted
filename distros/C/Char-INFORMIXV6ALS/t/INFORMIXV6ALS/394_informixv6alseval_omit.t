# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

use INFORMIXV6ALS;

print "1..12\n";

# INFORMIXV6ALS::eval (omit) has INFORMIXV6ALS::eval "..."
$_ = <<'END';
INFORMIXV6ALS::eval " if ('アソ' !~ /A/) { return 1 } else { return 0 } "
END
if (INFORMIXV6ALS::eval) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# INFORMIXV6ALS::eval (omit) has INFORMIXV6ALS::eval qq{...}
$_ = <<'END';
INFORMIXV6ALS::eval qq{ if ('アソ' !~ /A/) { return 1 } else { return 0 } }
END
if (INFORMIXV6ALS::eval) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# INFORMIXV6ALS::eval (omit) has INFORMIXV6ALS::eval '...'
$_ = <<'END';
INFORMIXV6ALS::eval ' if (qq{アソ} !~ /A/) { return 1 } else { return 0 } '
END
if (INFORMIXV6ALS::eval) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# INFORMIXV6ALS::eval (omit) has INFORMIXV6ALS::eval q{...}
$_ = <<'END';
INFORMIXV6ALS::eval q{ if ('アソ' !~ /A/) { return 1 } else { return 0 } }
END
if (INFORMIXV6ALS::eval) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# INFORMIXV6ALS::eval (omit) has INFORMIXV6ALS::eval $var
$_ = <<'END';
INFORMIXV6ALS::eval $var2
END
my $var2 = q{ if ('アソ' !~ /A/) { return 1 } else { return 0 } };
if (INFORMIXV6ALS::eval) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# INFORMIXV6ALS::eval (omit) has INFORMIXV6ALS::eval (omit)
$_ = <<'END';
$_ = "if ('アソ' !~ /A/) { return 1 } else { return 0 }";
INFORMIXV6ALS::eval
END
if (INFORMIXV6ALS::eval) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# INFORMIXV6ALS::eval (omit) has INFORMIXV6ALS::eval {...}
$_ = <<'END';
INFORMIXV6ALS::eval { if ('アソ' !~ /A/) { return 1 } else { return 0 } }
END
if (INFORMIXV6ALS::eval) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# INFORMIXV6ALS::eval (omit) has "..."
$_ = <<'END';
if ('アソ' !~ /A/) { return "1" } else { return "0" }
END
if (INFORMIXV6ALS::eval) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# INFORMIXV6ALS::eval (omit) has qq{...}
$_ = <<'END';
if ('アソ' !~ /A/) { return qq{1} } else { return qq{0} }
END
if (INFORMIXV6ALS::eval) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# INFORMIXV6ALS::eval (omit) has '...'
$_ = <<'END';
if ('アソ' !~ /A/) { return '1' } else { return '0' }
END
if (INFORMIXV6ALS::eval) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# INFORMIXV6ALS::eval (omit) has q{...}
$_ = <<'END';
if ('アソ' !~ /A/) { return q{1} } else { return q{0} }
END
if (INFORMIXV6ALS::eval) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# INFORMIXV6ALS::eval (omit) has $var
$_ = <<'END';
if ('アソ' !~ /A/) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (INFORMIXV6ALS::eval) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
