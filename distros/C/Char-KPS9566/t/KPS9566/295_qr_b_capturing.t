# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{Ç†} ne "\x82\xa0";

use strict;
use KPS9566;
print "1..18\n";

my $__FILE__ = __FILE__;

if ('A' =~ qr/(A)/) {
    if ($1 eq 'A') {
        print qq{ok - 1 'A' =~ qr/(A)/ $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 'A' =~ qr/(A)/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 'A' =~ qr/(A)/ $^X $__FILE__\n};
}

if ('A' =~ qr/(A)/b) {
    if ($1 eq 'A') {
        print qq{ok - 2 'A' =~ qr/(A)/b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 'A' =~ qr/(A)/b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 'A' =~ qr/(A)/b $^X $__FILE__\n};
}

if ('A' =~ qr/(a)/i) {
    if ($1 eq 'A') {
        print qq{ok - 3 'A' =~ qr/(a)/i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 'A' =~ qr/(a)/i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 'A' =~ qr/(a)/i $^X $__FILE__\n};
}

if ('A' =~ qr/(a)/ib) {
    if ($1 eq 'A') {
        print qq{ok - 4 'A' =~ qr/(a)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 'A' =~ qr/(a)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 'A' =~ qr/(a)/ib $^X $__FILE__\n};
}

if ('a' =~ qr/(a)/i) {
    if ($1 eq 'a') {
        print qq{ok - 5 'a' =~ qr/(a)/i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 'a' =~ qr/(a)/i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 'a' =~ qr/(a)/i $^X $__FILE__\n};
}

if ('a' =~ qr/(a)/ib) {
    if ($1 eq 'a') {
        print qq{ok - 6 'a' =~ qr/(a)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 'a' =~ qr/(a)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 'a' =~ qr/(a)/ib $^X $__FILE__\n};
}

if ('ÉA' =~ qr/(A)/b) {
    if ($1 eq 'A') {
        print qq{ok - 7 'ÉA' =~ qr/(A)/b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 7 'ÉA' =~ qr/(A)/b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 'ÉA' =~ qr/(A)/b $^X $__FILE__\n};
}

if ('ÉA' =~ qr/(A)/ib) {
    if ($1 eq 'A') {
        print qq{ok - 8 'ÉA' =~ qr/(A)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 'ÉA' =~ qr/(A)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 'ÉA' =~ qr/(A)/ib $^X $__FILE__\n};
}

if ('ÉA' =~ qr/(a)/ib) {
    if ($1 eq 'A') {
        print qq{ok - 9 'ÉA' =~ qr/(a)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 'ÉA' =~ qr/(a)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 'ÉA' =~ qr/(a)/ib $^X $__FILE__\n};
}

if ('Éa' =~ qr/(A)/ib) {
    if ($1 eq 'a') {
        print qq{ok - 10 'Éa' =~ qr/(A)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 'Éa' =~ qr/(A)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 'Éa' =~ qr/(A)/ib $^X $__FILE__\n};
}

if ('Éa' =~ qr/(a)/b) {
    if ($1 eq 'a') {
        print qq{ok - 11 'Éa' =~ qr/(a)/b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 'Éa' =~ qr/(a)/b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 'Éa' =~ qr/(a)/b $^X $__FILE__\n};
}

if ('Éa' =~ qr/(a)/ib) {
    if ($1 eq 'a') {
        print qq{ok - 12 'Éa' =~ qr/(a)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 12 'Éa' =~ qr/(a)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 12 'Éa' =~ qr/(a)/ib $^X $__FILE__\n};
}

if ('ÉÉA' =~ qr/(ÉA)/b) {
    if ($1 eq 'ÉA') {
        print qq{ok - 13 'ÉÉA' =~ qr/(ÉA)/b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 13 'ÉÉA' =~ qr/(ÉA)/b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 13 'ÉÉA' =~ qr/(ÉA)/b $^X $__FILE__\n};
}

if ('ÉÉA' =~ qr/(ÉA)/ib) {
    if ($1 eq 'ÉA') {
        print qq{ok - 14 'ÉÉA' =~ qr/(ÉA)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 14 'ÉÉA' =~ qr/(ÉA)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 14 'ÉÉA' =~ qr/(ÉA)/ib $^X $__FILE__\n};
}

if ('ÉÉA' =~ qr/(Éa)/ib) {
    if ($1 eq 'ÉA') {
        print qq{ok - 15 'ÉÉA' =~ qr/(Éa)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 15 'ÉÉA' =~ qr/(Éa)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 15 'ÉÉA' =~ qr/(Éa)/ib $^X $__FILE__\n};
}

if ('ÉÉa' =~ qr/(ÉA)/ib) {
    if ($1 eq 'Éa') {
        print qq{ok - 16 'ÉÉa' =~ qr/(ÉA)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 16 'ÉÉa' =~ qr/(ÉA)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 16 'ÉÉa' =~ qr/(ÉA)/ib $^X $__FILE__\n};
}

if ('ÉÉa' =~ qr/(Éa)/b) {
    if ($1 eq 'Éa') {
        print qq{ok - 17 'ÉÉa' =~ qr/(Éa)/b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 17 'ÉÉa' =~ qr/(Éa)/b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 17 'ÉÉa' =~ qr/(Éa)/b $^X $__FILE__\n};
}

if ('ÉÉa' =~ qr/(Éa)/ib) {
    if ($1 eq 'Éa') {
        print qq{ok - 18 'ÉÉa' =~ qr/(Éa)/ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 18 'ÉÉa' =~ qr/(Éa)/ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 18 'ÉÉa' =~ qr/(Éa)/ib $^X $__FILE__\n};
}

__END__

