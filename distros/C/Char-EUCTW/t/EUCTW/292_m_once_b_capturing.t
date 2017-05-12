# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{¤¢} ne "\xa4\xa2";

use strict;
use EUCTW;
print "1..8\n";

my $__FILE__ = __FILE__;

if ('A' =~ m?(A)?) {
    if ($1 eq 'A') {
        print qq{ok - 1 'A' =~ m?(A)? $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 'A' =~ m?(A)? $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 'A' =~ m?(A)? $^X $__FILE__\n};
}

if ('A' =~ m?(A)?b) {
    if ($1 eq 'A') {
        print qq{ok - 2 'A' =~ m?(A)?b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 'A' =~ m?(A)?b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 'A' =~ m?(A)?b $^X $__FILE__\n};
}

if ('A' =~ m?(a)?i) {
    if ($1 eq 'A') {
        print qq{ok - 3 'A' =~ m?(a)?i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 'A' =~ m?(a)?i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 'A' =~ m?(a)?i $^X $__FILE__\n};
}

if ('A' =~ m?(a)?ib) {
    if ($1 eq 'A') {
        print qq{ok - 4 'A' =~ m?(a)?ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 'A' =~ m?(a)?ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 'A' =~ m?(a)?ib $^X $__FILE__\n};
}

if ('a' =~ m?(a)?i) {
    if ($1 eq 'a') {
        print qq{ok - 5 'a' =~ m?(a)?i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 'a' =~ m?(a)?i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 'a' =~ m?(a)?i $^X $__FILE__\n};
}

if ('a' =~ m?(a)?ib) {
    if ($1 eq 'a') {
        print qq{ok - 6 'a' =~ m?(a)?ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 'a' =~ m?(a)?ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 'a' =~ m?(a)?ib $^X $__FILE__\n};
}

if ('¡¢¢¡' =~ m?(¢¢)?b) {
    if ($1 eq '¢¢') {
        print qq{ok - 7 '¡¢¢¡' =~ m?(¢¢)?b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 7 '¡¢¢¡' =~ m?(¢¢)?b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 '¡¢¢¡' =~ m?(¢¢)?b $^X $__FILE__\n};
}

if ('¡¢¢¡' =~ m?(¢¢)?ib) {
    if ($1 eq '¢¢') {
        print qq{ok - 8 '¡¢¢¡' =~ m?(¢¢)?ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 '¡¢¢¡' =~ m?(¢¢)?ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 '¡¢¢¡' =~ m?(¢¢)?ib $^X $__FILE__\n};
}

__END__

