# encoding: TIS620
# This file is encoded in TIS-620.
die "This file is not encoded in TIS-620.\n" if q{ } ne "\x82\xa0";

use TIS620;

print "1..12\n";

# TIS620::eval qq{...} has TIS620::eval "..."
if (TIS620::eval qq{ TIS620::eval " if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 } " }) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# TIS620::eval qq{...} has TIS620::eval qq{...}
if (TIS620::eval qq{ TIS620::eval qq{ if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 } } }) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# TIS620::eval qq{...} has TIS620::eval '...'
if (TIS620::eval qq{ TIS620::eval ' if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 } ' }) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# TIS620::eval qq{...} has TIS620::eval q{...}
if (TIS620::eval qq{ TIS620::eval q{ if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 } } }) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# TIS620::eval qq{...} has TIS620::eval $var
my $var = q{q{ if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 } }};
if (TIS620::eval qq{ TIS620::eval $var }) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# TIS620::eval qq{...} has TIS620::eval (omit)
$_ = "if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 }";
if (TIS620::eval qq{ TIS620::eval }) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# TIS620::eval qq{...} has TIS620::eval {...}
if (TIS620::eval qq{ TIS620::eval { if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return 1 } else { return 0 } } }) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# TIS620::eval qq{...} has "..."
if (TIS620::eval qq{ if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return "1" } else { return "0" } }) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# TIS620::eval qq{...} has qq{...}
if (TIS620::eval qq{ if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return qq{1} } else { return qq{0} } }) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# TIS620::eval qq{...} has '...'
if (TIS620::eval qq{ if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return '1' } else { return '0' } }) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# TIS620::eval qq{...} has q{...}
if (TIS620::eval qq{ if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return q{1} } else { return q{0} } }) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# TIS620::eval qq{...} has $var
my $var1 = 1;
my $var0 = 0;
if (TIS620::eval qq{ if (TIS620::length(q{ฆฑฒฒณดดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮฯะัาำิีึืฺุูÛÜ}) == 47) { return $var1 } else { return $var0 } }) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
