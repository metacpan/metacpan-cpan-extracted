# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;

print "1..12\n";

# EUCJP::eval '...' has EUCJP::eval "..."
if (EUCJP::eval ' EUCJP::eval " if (\'□●\' !~ /◆/) { return 1 } else { return 0 } " ') {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# EUCJP::eval '...' has EUCJP::eval qq{...}
if (EUCJP::eval ' EUCJP::eval qq{ if (\'□●\' !~ /◆/) { return 1 } else { return 0 } } ') {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# EUCJP::eval '...' has EUCJP::eval '...'
if (EUCJP::eval ' EUCJP::eval \' if (qq{□●} !~ /◆/) { return 1 } else { return 0 } \' ') {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# EUCJP::eval '...' has EUCJP::eval q{...}
if (EUCJP::eval ' EUCJP::eval q{ if (\'□●\' !~ /◆/) { return 1 } else { return 0 } } ') {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# EUCJP::eval '...' has EUCJP::eval $var
my $var = q{ if ('□●' !~ /◆/) { return 1 } else { return 0 } };
if (EUCJP::eval ' EUCJP::eval $var ') {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# EUCJP::eval '...' has EUCJP::eval (omit)
$_ = "if ('□●' !~ /◆/) { return 1 } else { return 0 }";
if (EUCJP::eval ' EUCJP::eval ') {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# EUCJP::eval '...' has EUCJP::eval {...}
if (EUCJP::eval ' EUCJP::eval { if (\'□●\' !~ /◆/) { return 1 } else { return 0 } } ') {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# EUCJP::eval '...' has "..."
if (EUCJP::eval ' if (\'□●\' !~ /◆/) { return "1" } else { return "0" } ') {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# EUCJP::eval '...' has qq{...}
if (EUCJP::eval ' if (\'□●\' !~ /◆/) { return qq{1} } else { return qq{0} } ') {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# EUCJP::eval '...' has '...'
if (EUCJP::eval ' if (\'□●\' !~ /◆/) { return \'1\' } else { return \'0\' } ') {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# EUCJP::eval '...' has q{...}
if (EUCJP::eval ' if (\'□●\' !~ /◆/) { return q{1} } else { return q{0} } ') {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# EUCJP::eval '...' has $var
my $var1 = 1;
my $var0 = 0;
if (EUCJP::eval ' if (\'□●\' !~ /◆/) { return $var1 } else { return $var0 } ') {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
