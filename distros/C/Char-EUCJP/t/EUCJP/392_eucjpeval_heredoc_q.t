# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;

print "1..12\n";

# EUCJP::eval <<'END' has EUCJP::eval "..."
if (EUCJP::eval <<'END') {
EUCJP::eval " if ('□●' !~ /◆/) { return 1 } else { return 0 } "
END
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# EUCJP::eval <<'END' has EUCJP::eval qq{...}
if (EUCJP::eval <<'END') {
EUCJP::eval qq{ if ('□●' !~ /◆/) { return 1 } else { return 0 } }
END
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# EUCJP::eval <<'END' has EUCJP::eval '...'
if (EUCJP::eval <<'END') {
EUCJP::eval ' if (qq{□●} !~ /◆/) { return 1 } else { return 0 } '
END
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# EUCJP::eval <<'END' has EUCJP::eval q{...}
if (EUCJP::eval <<'END') {
EUCJP::eval q{ if ('□●' !~ /◆/) { return 1 } else { return 0 } }
END
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# EUCJP::eval <<'END' has EUCJP::eval $var
my $var = q{ if ('□●' !~ /◆/) { return 1 } else { return 0 } };
if (EUCJP::eval <<'END') {
EUCJP::eval $var
END
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# EUCJP::eval <<'END' has EUCJP::eval (omit)
$_ = "if ('□●' !~ /◆/) { return 1 } else { return 0 }";
if (EUCJP::eval <<'END') {
EUCJP::eval
END
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# EUCJP::eval <<'END' has EUCJP::eval {...}
if (EUCJP::eval <<'END') {
EUCJP::eval { if ('□●' !~ /◆/) { return 1 } else { return 0 } }
END
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# EUCJP::eval <<'END' has "..."
if (EUCJP::eval <<'END') {
if ('□●' !~ /◆/) { return "1" } else { return "0" }
END
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# EUCJP::eval <<'END' has qq{...}
if (EUCJP::eval <<'END') {
if ('□●' !~ /◆/) { return qq{1} } else { return qq{0} }
END
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# EUCJP::eval <<'END' has '...'
if (EUCJP::eval <<'END') {
if ('□●' !~ /◆/) { return '1' } else { return '0' }
END
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# EUCJP::eval <<'END' has q{...}
if (EUCJP::eval <<'END') {
if ('□●' !~ /◆/) { return q{1} } else { return q{0} }
END
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# EUCJP::eval <<'END' has $var
my $var1 = 1;
my $var0 = 0;
if (EUCJP::eval <<'END') {
if ('□●' !~ /◆/) { return $var1 } else { return $var0 }
END
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
