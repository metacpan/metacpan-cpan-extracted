# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{Ç†} ne "\x82\xa0";

use strict;
use INFORMIXV6ALS;
print "1..18\n";

my $__FILE__ = __FILE__;

if ('A' =~ /(A)/) {
    if ($1 eq 'A') {
        print qq{ok - 1 'A' =~ /(A)/ $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 'A' =~ /(A)/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 'A' =~ /(A)/ $^X $__FILE__\n};
}

if ('A' =~ /(A)/b) {
    if ($1 eq 'A') {
        print qq{ok - 2 'A' =~ /(A)/b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 'A' =~ /(A)/b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 'A' =~ /(A)/b $^X $__FILE__\n};
}

if ('A' =~ /(a)/i) {
    if ($1 eq 'A') {
        print qq{ok - 3 'A' =~ /(a)/i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 'A' =~ /(a)/i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 'A' =~ /(a)/i $^X $__FILE__\n};
}

if ('A' =~ /(a)/ib) {
    if ($1 eq 'A') {
        print qq{ok - 4 'A' =~ /(a)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 'A' =~ /(a)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 'A' =~ /(a)/ib $^X $__FILE__\n};
}

if ('a' =~ /(a)/i) {
    if ($1 eq 'a') {
        print qq{ok - 5 'a' =~ /(a)/i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 'a' =~ /(a)/i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 'a' =~ /(a)/i $^X $__FILE__\n};
}

if ('a' =~ /(a)/ib) {
    if ($1 eq 'a') {
        print qq{ok - 6 'a' =~ /(a)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 'a' =~ /(a)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 'a' =~ /(a)/ib $^X $__FILE__\n};
}

if ('ÉA' =~ /(A)/b) {
    if ($1 eq 'A') {
        print qq{ok - 7 'ÉA' =~ /(A)/b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 7 'ÉA' =~ /(A)/b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 'ÉA' =~ /(A)/b $^X $__FILE__\n};
}

if ('ÉA' =~ /(A)/ib) {
    if ($1 eq 'A') {
        print qq{ok - 8 'ÉA' =~ /(A)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 'ÉA' =~ /(A)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 'ÉA' =~ /(A)/ib $^X $__FILE__\n};
}

if ('ÉA' =~ /(a)/ib) {
    if ($1 eq 'A') {
        print qq{ok - 9 'ÉA' =~ /(a)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 'ÉA' =~ /(a)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 'ÉA' =~ /(a)/ib $^X $__FILE__\n};
}

if ('Éa' =~ /(A)/ib) {
    if ($1 eq 'a') {
        print qq{ok - 10 'Éa' =~ /(A)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 'Éa' =~ /(A)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 'Éa' =~ /(A)/ib $^X $__FILE__\n};
}

if ('Éa' =~ /(a)/b) {
    if ($1 eq 'a') {
        print qq{ok - 11 'Éa' =~ /(a)/b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 'Éa' =~ /(a)/b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 'Éa' =~ /(a)/b $^X $__FILE__\n};
}

if ('Éa' =~ /(a)/ib) {
    if ($1 eq 'a') {
        print qq{ok - 12 'Éa' =~ /(a)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 12 'Éa' =~ /(a)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 12 'Éa' =~ /(a)/ib $^X $__FILE__\n};
}

if ('ÉÉA' =~ /(ÉA)/b) {
    if ($1 eq 'ÉA') {
        print qq{ok - 13 'ÉÉA' =~ /(ÉA)/b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 13 'ÉÉA' =~ /(ÉA)/b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 13 'ÉÉA' =~ /(ÉA)/b $^X $__FILE__\n};
}

if ('ÉÉA' =~ /(ÉA)/ib) {
    if ($1 eq 'ÉA') {
        print qq{ok - 14 'ÉÉA' =~ /(ÉA)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 14 'ÉÉA' =~ /(ÉA)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 14 'ÉÉA' =~ /(ÉA)/ib $^X $__FILE__\n};
}

if ('ÉÉA' =~ /(Éa)/ib) {
    if ($1 eq 'ÉA') {
        print qq{ok - 15 'ÉÉA' =~ /(Éa)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 15 'ÉÉA' =~ /(Éa)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 15 'ÉÉA' =~ /(Éa)/ib $^X $__FILE__\n};
}

if ('ÉÉa' =~ /(ÉA)/ib) {
    if ($1 eq 'Éa') {
        print qq{ok - 16 'ÉÉa' =~ /(ÉA)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 16 'ÉÉa' =~ /(ÉA)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 16 'ÉÉa' =~ /(ÉA)/ib $^X $__FILE__\n};
}

if ('ÉÉa' =~ /(Éa)/b) {
    if ($1 eq 'Éa') {
        print qq{ok - 17 'ÉÉa' =~ /(Éa)/b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 17 'ÉÉa' =~ /(Éa)/b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 17 'ÉÉa' =~ /(Éa)/b $^X $__FILE__\n};
}

if ('ÉÉa' =~ /(Éa)/ib) {
    if ($1 eq 'Éa') {
        print qq{ok - 18 'ÉÉa' =~ /(Éa)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 18 'ÉÉa' =~ /(Éa)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 18 'ÉÉa' =~ /(Éa)/ib $^X $__FILE__\n};
}

__END__

