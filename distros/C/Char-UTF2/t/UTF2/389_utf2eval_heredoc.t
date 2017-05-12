# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use UTF2;

print "1..12\n";

# UTF2::eval <<END has UTF2::eval "..."
if (UTF2::eval <<END) {
UTF2::eval " if ('□●' !~ /[◆]/) { return 1 } else { return 0 } "
END
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# UTF2::eval <<END has UTF2::eval qq{...}
if (UTF2::eval <<END) {
UTF2::eval qq{ if ('□●' !~ /[◆]/) { return 1 } else { return 0 } }
END
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# UTF2::eval <<END has UTF2::eval '...'
if (UTF2::eval <<END) {
UTF2::eval ' if (qq{□●} !~ /[◆]/) { return 1 } else { return 0 } '
END
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# UTF2::eval <<END has UTF2::eval q{...}
if (UTF2::eval <<END) {
UTF2::eval q{ if ('□●' !~ /[◆]/) { return 1 } else { return 0 } }
END
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# UTF2::eval <<END has UTF2::eval $var
my $var = q{q{ if ('□●' !~ /[◆]/) { return 1 } else { return 0 } }};
if (UTF2::eval <<END) {
UTF2::eval $var
END
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# UTF2::eval <<END has UTF2::eval (omit)
$_ = "if ('□●' !~ /[◆]/) { return 1 } else { return 0 }";
if (UTF2::eval <<END) {
UTF2::eval
END
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# UTF2::eval <<END has UTF2::eval {...}
if (UTF2::eval <<END) {
UTF2::eval { if ('□●' !~ /[◆]/) { return 1 } else { return 0 } }
END
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# UTF2::eval <<END has "..."
if (UTF2::eval <<END) {
if ('□●' !~ /[◆]/) { return \"1\" } else { return \"0\" }
END
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# UTF2::eval <<END has qq{...}
if (UTF2::eval <<END) {
if ('□●' !~ /[◆]/) { return qq{1} } else { return qq{0} }
END
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# UTF2::eval <<END has '...'
if (UTF2::eval <<END) {
if ('□●' !~ /[◆]/) { return '1' } else { return '0' }
END
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# UTF2::eval <<END has q{...}
if (UTF2::eval <<END) {
if ('□●' !~ /[◆]/) { return q{1} } else { return q{0} }
END
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# UTF2::eval <<END has $var
my $var1 = 1;
my $var0 = 0;
if (UTF2::eval <<END) {
if ('□●' !~ /[◆]/) { return $var1 } else { return $var0 }
END
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
