# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use strict;
use EUCJP;
print "1..8\n";

my $__FILE__ = __FILE__;

if ('A' =~ qr'(A)') {
    if ($1 eq 'A') {
        print qq{ok - 1 'A' =~ qr'(A)' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 'A' =~ qr'(A)' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 'A' =~ qr'(A)' $^X $__FILE__\n};
}

if ('A' =~ qr'(A)'b) {
    if ($1 eq 'A') {
        print qq{ok - 2 'A' =~ qr'(A)'b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 'A' =~ qr'(A)'b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 'A' =~ qr'(A)'b $^X $__FILE__\n};
}

if ('A' =~ qr'(a)'i) {
    if ($1 eq 'A') {
        print qq{ok - 3 'A' =~ qr'(a)'i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 'A' =~ qr'(a)'i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 'A' =~ qr'(a)'i $^X $__FILE__\n};
}

if ('A' =~ qr'(a)'ib) {
    if ($1 eq 'A') {
        print qq{ok - 4 'A' =~ qr'(a)'ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 'A' =~ qr'(a)'ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 'A' =~ qr'(a)'ib $^X $__FILE__\n};
}

if ('a' =~ qr'(a)'i) {
    if ($1 eq 'a') {
        print qq{ok - 5 'a' =~ qr'(a)'i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 'a' =~ qr'(a)'i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 'a' =~ qr'(a)'i $^X $__FILE__\n};
}

if ('a' =~ qr'(a)'ib) {
    if ($1 eq 'a') {
        print qq{ok - 6 'a' =~ qr'(a)'ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 'a' =~ qr'(a)'ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 'a' =~ qr'(a)'ib $^X $__FILE__\n};
}

if ('、◆' =~ qr'(□)'b) {
    if ($1 eq '□') {
        print qq{ok - 7 '、◆' =~ qr'(□)'b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 7 '、◆' =~ qr'(□)'b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 '、◆' =~ qr'(□)'b $^X $__FILE__\n};
}

if ('、◆' =~ qr'(□)'ib) {
    if ($1 eq '□') {
        print qq{ok - 8 '、◆' =~ qr'(□)'ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 '、◆' =~ qr'(□)'ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 '、◆' =~ qr'(□)'ib $^X $__FILE__\n};
}

__END__

