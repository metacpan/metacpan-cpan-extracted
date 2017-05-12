# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{‚ } ne "\x82\xa0";

use HP15;
print "1..36\n";

my $__FILE__ = __FILE__;

if ("a" =~ /./) {
    print qq{ok - 1 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 $^X $__FILE__\n};
}

if ("." =~ /./) {
    print qq{ok - 2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 $^X $__FILE__\n};
}

if ("" =~ /./) {
    print qq{not ok - 3 $^X $__FILE__\n};
}
else {
    print qq{ok - 3 $^X $__FILE__\n};
}

if ("\n" =~ /./) {
    print qq{not ok - 4 $^X $__FILE__\n};
}
else {
    print qq{ok - 4 $^X $__FILE__\n};
}

if ("\n" =~ /./s) {
    print qq{ok - 5 $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 $^X $__FILE__\n};
}

if ("\n" =~ /(?s:.)/s) {
    print qq{ok - 6 $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 $^X $__FILE__\n};
}

if ("ab" =~ /^.$/) {
    print qq{not ok - 7 $^X $__FILE__\n};
}
else {
    print qq{ok - 7 $^X $__FILE__\n};
}

if ("a" =~ /\w/) {
    print qq{ok - 8 $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 $^X $__FILE__\n};
}

if ("7" =~ /\w/) {
    print qq{ok - 9 $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 $^X $__FILE__\n};
}

if ("a" =~ /\d/) {
    print qq{not ok - 10 $^X $__FILE__\n};
}
else {
    print qq{ok - 10 $^X $__FILE__\n};
}

if ("7" =~ /\d/) {
    print qq{ok - 11 $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 $^X $__FILE__\n};
}

if (" " =~ /\s/) {
    print qq{ok - 12 $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 $^X $__FILE__\n};
}

if ("a" =~ /\D/) {
    print qq{ok - 13 $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 $^X $__FILE__\n};
}

if ("7" =~ /\D/) {
    print qq{not ok - 14 $^X $__FILE__\n};
}
else {
    print qq{ok - 14 $^X $__FILE__\n};
}

if (" " =~ /\S/) {
    print qq{not ok - 15 $^X $__FILE__\n};
}
else {
    print qq{ok - 15 $^X $__FILE__\n};
}

if (" " =~ /\h/) {
    print qq{ok - 16 $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 $^X $__FILE__\n};
}

if (" " =~ /\v/) {
    print qq{not ok - 17 $^X $__FILE__\n};
}
else {
    print qq{ok - 17 $^X $__FILE__\n};
}

if ("\r" =~ /\v/) {
    print qq{ok - 18 $^X $__FILE__\n};
}
else {
    print qq{not ok - 18 $^X $__FILE__\n};
}

if ("e" =~ /[aeiou]/) {
    print qq{ok - 19 $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 $^X $__FILE__\n};
}

if ("p" =~ /[aeiou]/) {
    print qq{not ok - 20 $^X $__FILE__\n};
}
else {
    print qq{ok - 20 $^X $__FILE__\n};
}

if ("ae" =~ /^[aeiou]$/) {
    print qq{not ok - 21 $^X $__FILE__\n};
}
else {
    print qq{ok - 21 $^X $__FILE__\n};
}

if ("ae" =~ /^[aeiou]+$/) {
    print qq{ok - 22 $^X $__FILE__\n};
}
else {
    print qq{not ok - 22 $^X $__FILE__\n};
}

if ("+" =~ /[+?*]/) {
    print qq{ok - 23 $^X $__FILE__\n};
}
else {
    print qq{not ok - 23 $^X $__FILE__\n};
}

if ("\cH" =~ /[\b]/) {
    print qq{ok - 24 $^X $__FILE__\n};
}
else {
    print qq{not ok - 24 $^X $__FILE__\n};
}

if ("]" =~ /[][]/) {
    print qq{ok - 25 $^X $__FILE__\n};
}
else {
    print qq{not ok - 25 $^X $__FILE__\n};
}

if ("[]" =~ /[[]]/) {
    print qq{ok - 26 $^X $__FILE__\n};
}
else {
    print qq{not ok - 26 $^X $__FILE__\n};
}

if ("e" =~ /[^aeiou]/) {
    print qq{not ok - 27 $^X $__FILE__\n};
}
else {
    print qq{ok - 27 $^X $__FILE__\n};
}

if ("x" =~ /[^aeiou]/) {
    print qq{ok - 28 $^X $__FILE__\n};
}
else {
    print qq{not ok - 28 $^X $__FILE__\n};
}

if ("^" =~ /[^^]/) {
    print qq{not ok - 29 $^X $__FILE__\n};
}
else {
    print qq{ok - 29 $^X $__FILE__\n};
}

if ("^" =~ /[x^]/) {
    print qq{ok - 30 $^X $__FILE__\n};
}
else {
    print qq{not ok - 30 $^X $__FILE__\n};
}

if ("0" =~ /[01[:alpha:]%]/) {
    print qq{ok - 31 $^X $__FILE__\n};
}
else {
    print qq{not ok - 31 $^X $__FILE__\n};
}

if ("1" =~ /[01[:alpha:]%]/) {
    print qq{ok - 32 $^X $__FILE__\n};
}
else {
    print qq{not ok - 32 $^X $__FILE__\n};
}

if ("A" =~ /[01[:alpha:]%]/) {
    print qq{ok - 33 $^X $__FILE__\n};
}
else {
    print qq{not ok - 33 $^X $__FILE__\n};
}

if ("B" =~ /[01[:alpha:]%]/) {
    print qq{ok - 34 $^X $__FILE__\n};
}
else {
    print qq{not ok - 34 $^X $__FILE__\n};
}

if ("z" =~ /[01[:alpha:]%]/) {
    print qq{ok - 35 $^X $__FILE__\n};
}
else {
    print qq{not ok - 35 $^X $__FILE__\n};
}

if ("%" =~ /[01[:alpha:]%]/) {
    print qq{ok - 36 $^X $__FILE__\n};
}
else {
    print qq{not ok - 36 $^X $__FILE__\n};
}

__END__
