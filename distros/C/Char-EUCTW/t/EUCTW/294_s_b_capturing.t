# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{¤¢} ne "\xa4\xa2";

use strict;
use EUCTW;
print "1..8\n";

my $__FILE__ = __FILE__;

$_ = 'A';
if ($_ =~ s'(A)'') {
    if ($1 eq 'A') {
        print qq{ok - 1 'A' =~ s'(A)'' 1:($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 'A' =~ s'(A)'' 2:($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 'A' =~ s'(A)'' 3:($1) $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s'(A)''b) {
    if ($1 eq 'A') {
        print qq{ok - 2 'A' =~ s'(A)''b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 'A' =~ s'(A)''b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 'A' =~ s'(A)''b $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s'(a)''i) {
    if ($1 eq 'A') {
        print qq{ok - 3 'A' =~ s'(a)''i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 'A' =~ s'(a)''i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 'A' =~ s'(a)''i $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s'(a)''ib) {
    if ($1 eq 'A') {
        print qq{ok - 4 'A' =~ s'(a)''ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 'A' =~ s'(a)''ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 'A' =~ s'(a)''ib $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s'(a)''i) {
    if ($1 eq 'a') {
        print qq{ok - 5 'a' =~ s'(a)''i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 'a' =~ s'(a)''i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 'a' =~ s'(a)''i $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s'(a)''ib) {
    if ($1 eq 'a') {
        print qq{ok - 6 'a' =~ s'(a)''ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 'a' =~ s'(a)''ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 'a' =~ s'(a)''ib $^X $__FILE__\n};
}

$_ = '¡¢¢¡';
if ($_ =~ s'(¢¢)''b) {
    if ($1 eq '¢¢') {
        print qq{ok - 7 '¡¢¢¡' =~ s'(¢¢)''b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 7 '¡¢¢¡' =~ s'(¢¢)''b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 '¡¢¢¡' =~ s'(¢¢)''b $^X $__FILE__\n};
}

$_ = '¡¢¢¡';
if ($_ =~ s'(¢¢)''ib) {
    if ($1 eq '¢¢') {
        print qq{ok - 8 '¡¢¢¡' =~ s'(¢¢)''ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 '¡¢¢¡' =~ s'(¢¢)''ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 '¡¢¢¡' =~ s'(¢¢)''ib $^X $__FILE__\n};
}

__END__

