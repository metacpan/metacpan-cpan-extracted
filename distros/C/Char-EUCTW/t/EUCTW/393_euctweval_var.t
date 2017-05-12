# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{¤¢} ne "\xa4\xa2";

use EUCTW;

print "1..12\n";

my $var = '';

# EUCTW::eval $var has EUCTW::eval "..."
$var = <<'END';
EUCTW::eval " if ('¢¢¡ü' !~ /¢¡/) { return 1 } else { return 0 } "
END
if (EUCTW::eval $var) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# EUCTW::eval $var has EUCTW::eval qq{...}
$var = <<'END';
EUCTW::eval qq{ if ('¢¢¡ü' !~ /¢¡/) { return 1 } else { return 0 } }
END
if (EUCTW::eval $var) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# EUCTW::eval $var has EUCTW::eval '...'
$var = <<'END';
EUCTW::eval ' if (qq{¢¢¡ü} !~ /¢¡/) { return 1 } else { return 0 } '
END
if (EUCTW::eval $var) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# EUCTW::eval $var has EUCTW::eval q{...}
$var = <<'END';
EUCTW::eval q{ if ('¢¢¡ü' !~ /¢¡/) { return 1 } else { return 0 } }
END
if (EUCTW::eval $var) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# EUCTW::eval $var has EUCTW::eval $var
$var = <<'END';
EUCTW::eval $var2
END
my $var2 = q{ if ('¢¢¡ü' !~ /¢¡/) { return 1 } else { return 0 } };
if (EUCTW::eval $var) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# EUCTW::eval $var has EUCTW::eval (omit)
$var = <<'END';
EUCTW::eval
END
$_ = "if ('¢¢¡ü' !~ /¢¡/) { return 1 } else { return 0 }";
if (EUCTW::eval $var) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# EUCTW::eval $var has EUCTW::eval {...}
$var = <<'END';
EUCTW::eval { if ('¢¢¡ü' !~ /¢¡/) { return 1 } else { return 0 } }
END
if (EUCTW::eval $var) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# EUCTW::eval $var has "..."
$var = <<'END';
if ('¢¢¡ü' !~ /¢¡/) { return "1" } else { return "0" }
END
if (EUCTW::eval $var) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# EUCTW::eval $var has qq{...}
$var = <<'END';
if ('¢¢¡ü' !~ /¢¡/) { return qq{1} } else { return qq{0} }
END
if (EUCTW::eval $var) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# EUCTW::eval $var has '...'
$var = <<'END';
if ('¢¢¡ü' !~ /¢¡/) { return '1' } else { return '0' }
END
if (EUCTW::eval $var) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# EUCTW::eval $var has q{...}
$var = <<'END';
if ('¢¢¡ü' !~ /¢¡/) { return q{1} } else { return q{0} }
END
if (EUCTW::eval $var) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# EUCTW::eval $var has $var
$var = <<'END';
if ('¢¢¡ü' !~ /¢¡/) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (EUCTW::eval $var) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
