# encoding: Latin5
# This file is encoded in Latin-5.
die "This file is not encoded in Latin-5.\n" if q{‚ } ne "\x82\xa0";

use Latin5;

print "1..12\n";

my $var = '';

# Latin5::eval $var has Latin5::eval "..."
$var = <<'END';
Latin5::eval " if ('éÁ' =~ /[Šá]/i) { return 1 } else { return 0 } "
END
if (Latin5::eval $var) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Latin5::eval $var has Latin5::eval qq{...}
$var = <<'END';
Latin5::eval qq{ if ('éÁ' =~ /[Šá]/i) { return 1 } else { return 0 } }
END
if (Latin5::eval $var) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Latin5::eval $var has Latin5::eval '...'
$var = <<'END';
Latin5::eval ' if (qq{éÁ} =~ /[Šá]/i) { return 1 } else { return 0 } '
END
if (Latin5::eval $var) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Latin5::eval $var has Latin5::eval q{...}
$var = <<'END';
Latin5::eval q{ if ('éÁ' =~ /[Šá]/i) { return 1 } else { return 0 } }
END
if (Latin5::eval $var) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Latin5::eval $var has Latin5::eval $var
$var = <<'END';
Latin5::eval $var2
END
my $var2 = q{ if ('éÁ' =~ /[Šá]/i) { return 1 } else { return 0 } };
if (Latin5::eval $var) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Latin5::eval $var has Latin5::eval (omit)
$var = <<'END';
Latin5::eval
END
$_ = "if ('éÁ' =~ /[Šá]/i) { return 1 } else { return 0 }";
if (Latin5::eval $var) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Latin5::eval $var has Latin5::eval {...}
$var = <<'END';
Latin5::eval { if ('éÁ' =~ /[Šá]/i) { return 1 } else { return 0 } }
END
if (Latin5::eval $var) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Latin5::eval $var has "..."
$var = <<'END';
if ('éÁ' =~ /[Šá]/i) { return "1" } else { return "0" }
END
if (Latin5::eval $var) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Latin5::eval $var has qq{...}
$var = <<'END';
if ('éÁ' =~ /[Šá]/i) { return qq{1} } else { return qq{0} }
END
if (Latin5::eval $var) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Latin5::eval $var has '...'
$var = <<'END';
if ('éÁ' =~ /[Šá]/i) { return '1' } else { return '0' }
END
if (Latin5::eval $var) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Latin5::eval $var has q{...}
$var = <<'END';
if ('éÁ' =~ /[Šá]/i) { return q{1} } else { return q{0} }
END
if (Latin5::eval $var) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Latin5::eval $var has $var
$var = <<'END';
if ('éÁ' =~ /[Šá]/i) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (Latin5::eval $var) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
