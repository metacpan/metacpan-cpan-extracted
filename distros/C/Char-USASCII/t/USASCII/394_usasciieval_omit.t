# encoding: USASCII
# This file is encoded in US-ASCII.
die "This file is not encoded in US-ASCII.\n" if q{‚ } ne "\x82\xa0";

use USASCII;

print "1..12\n";

# USASCII::eval (omit) has USASCII::eval "..."
$_ = <<'END';
USASCII::eval " if (USASCII::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } "
END
if (USASCII::eval) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# USASCII::eval (omit) has USASCII::eval qq{...}
$_ = <<'END';
USASCII::eval qq{ if (USASCII::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } }
END
if (USASCII::eval) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# USASCII::eval (omit) has USASCII::eval '...'
$_ = <<'END';
USASCII::eval ' if (USASCII::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } '
END
if (USASCII::eval) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# USASCII::eval (omit) has USASCII::eval q{...}
$_ = <<'END';
USASCII::eval q{ if (USASCII::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } }
END
if (USASCII::eval) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# USASCII::eval (omit) has USASCII::eval $var
$_ = <<'END';
USASCII::eval $var2
END
my $var2 = q{ if (USASCII::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } };
if (USASCII::eval) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# USASCII::eval (omit) has USASCII::eval (omit)
$_ = <<'END';
$_ = "if (USASCII::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 }";
USASCII::eval
END
if (USASCII::eval) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# USASCII::eval (omit) has USASCII::eval {...}
$_ = <<'END';
USASCII::eval { if (USASCII::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } }
END
if (USASCII::eval) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# USASCII::eval (omit) has "..."
$_ = <<'END';
if (USASCII::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return "1" } else { return "0" }
END
if (USASCII::eval) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# USASCII::eval (omit) has qq{...}
$_ = <<'END';
if (USASCII::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return qq{1} } else { return qq{0} }
END
if (USASCII::eval) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# USASCII::eval (omit) has '...'
$_ = <<'END';
if (USASCII::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return '1' } else { return '0' }
END
if (USASCII::eval) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# USASCII::eval (omit) has q{...}
$_ = <<'END';
if (USASCII::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return q{1} } else { return q{0} }
END
if (USASCII::eval) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# USASCII::eval (omit) has $var
$_ = <<'END';
if (USASCII::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (USASCII::eval) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
