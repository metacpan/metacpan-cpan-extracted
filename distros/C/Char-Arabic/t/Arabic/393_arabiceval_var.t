# encoding: Arabic
# This file is encoded in Arabic.
die "This file is not encoded in Arabic.\n" if q{‚ } ne "\x82\xa0";

use Arabic;

print "1..12\n";

my $var = '';

# Arabic::eval $var has Arabic::eval "..."
$var = <<'END';
Arabic::eval " if (Arabic::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } "
END
if (Arabic::eval $var) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Arabic::eval $var has Arabic::eval qq{...}
$var = <<'END';
Arabic::eval qq{ if (Arabic::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } }
END
if (Arabic::eval $var) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Arabic::eval $var has Arabic::eval '...'
$var = <<'END';
Arabic::eval ' if (Arabic::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } '
END
if (Arabic::eval $var) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Arabic::eval $var has Arabic::eval q{...}
$var = <<'END';
Arabic::eval q{ if (Arabic::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } }
END
if (Arabic::eval $var) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Arabic::eval $var has Arabic::eval $var
$var = <<'END';
Arabic::eval $var2
END
my $var2 = q{ if (Arabic::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } };
if (Arabic::eval $var) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Arabic::eval $var has Arabic::eval (omit)
$var = <<'END';
Arabic::eval
END
$_ = "if (Arabic::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 }";
if (Arabic::eval $var) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Arabic::eval $var has Arabic::eval {...}
$var = <<'END';
Arabic::eval { if (Arabic::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } }
END
if (Arabic::eval $var) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Arabic::eval $var has "..."
$var = <<'END';
if (Arabic::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return "1" } else { return "0" }
END
if (Arabic::eval $var) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Arabic::eval $var has qq{...}
$var = <<'END';
if (Arabic::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return qq{1} } else { return qq{0} }
END
if (Arabic::eval $var) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Arabic::eval $var has '...'
$var = <<'END';
if (Arabic::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return '1' } else { return '0' }
END
if (Arabic::eval $var) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Arabic::eval $var has q{...}
$var = <<'END';
if (Arabic::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return q{1} } else { return q{0} }
END
if (Arabic::eval $var) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Arabic::eval $var has $var
$var = <<'END';
if (Arabic::length(q{¦±²²³´´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (Arabic::eval $var) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
