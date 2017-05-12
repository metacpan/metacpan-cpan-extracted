# encoding: TIS620
# This file is encoded in TIS-620.
die "This file is not encoded in TIS-620.\n" if q{ } ne "\x82\xa0";

use TIS620;

print "1..12\n";

my $var = '';

# eval $var has eval "..."
$var = <<'END';
eval TIS620::escape " if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 } "
END
if (eval TIS620::escape $var) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# eval $var has eval qq{...}
$var = <<'END';
eval TIS620::escape qq{ if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 } }
END
if (eval TIS620::escape $var) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# eval $var has eval '...'
$var = <<'END';
eval TIS620::escape ' if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 } '
END
if (eval TIS620::escape $var) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# eval $var has eval q{...}
$var = <<'END';
eval TIS620::escape q{ if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 } }
END
if (eval TIS620::escape $var) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# eval $var has eval $var
$var = <<'END';
eval TIS620::escape $var2
END
my $var2 = q{ if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 } };
if (eval TIS620::escape $var) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# eval $var has eval (omit)
$var = <<'END';
eval TIS620::escape
END
$_ = "if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 }";
if (eval TIS620::escape $var) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# eval $var has eval {...}
$var = <<'END';
eval { if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 } }
END
if (eval TIS620::escape $var) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# eval $var has "..."
$var = <<'END';
if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return "1" } else { return "0" }
END
if (eval TIS620::escape $var) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# eval $var has qq{...}
$var = <<'END';
if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return qq{1} } else { return qq{0} }
END
if (eval TIS620::escape $var) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# eval $var has '...'
$var = <<'END';
if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return '1' } else { return '0' }
END
if (eval TIS620::escape $var) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# eval $var has q{...}
$var = <<'END';
if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return q{1} } else { return q{0} }
END
if (eval TIS620::escape $var) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# eval $var has $var
$var = <<'END';
if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (eval TIS620::escape $var) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
