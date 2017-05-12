# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use strict;
use Sjis;
print "1..18\n";

my $__FILE__ = __FILE__;

if ('A' =~ m'(A)') {
    if ($1 eq 'A') {
        print qq{ok - 1 'A' =~ m'(A)' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 'A' =~ m'(A)' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 'A' =~ m'(A)' $^X $__FILE__\n};
}

if ('A' =~ m'(A)'b) {
    if ($1 eq 'A') {
        print qq{ok - 2 'A' =~ m'(A)'b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 'A' =~ m'(A)'b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 'A' =~ m'(A)'b $^X $__FILE__\n};
}

if ('A' =~ m'(a)'i) {
    if ($1 eq 'A') {
        print qq{ok - 3 'A' =~ m'(a)'i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 'A' =~ m'(a)'i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 'A' =~ m'(a)'i $^X $__FILE__\n};
}

if ('A' =~ m'(a)'ib) {
    if ($1 eq 'A') {
        print qq{ok - 4 'A' =~ m'(a)'ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 'A' =~ m'(a)'ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 'A' =~ m'(a)'ib $^X $__FILE__\n};
}

if ('a' =~ m'(a)'i) {
    if ($1 eq 'a') {
        print qq{ok - 5 'a' =~ m'(a)'i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 'a' =~ m'(a)'i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 'a' =~ m'(a)'i $^X $__FILE__\n};
}

if ('a' =~ m'(a)'ib) {
    if ($1 eq 'a') {
        print qq{ok - 6 'a' =~ m'(a)'ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 'a' =~ m'(a)'ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 'a' =~ m'(a)'ib $^X $__FILE__\n};
}

if ('ア' =~ m'(A)'b) {
    if ($1 eq 'A') {
        print qq{ok - 7 'ア' =~ m'(A)'b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 7 'ア' =~ m'(A)'b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 'ア' =~ m'(A)'b $^X $__FILE__\n};
}

if ('ア' =~ m'(A)'ib) {
    if ($1 eq 'A') {
        print qq{ok - 8 'ア' =~ m'(A)'ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 'ア' =~ m'(A)'ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 'ア' =~ m'(A)'ib $^X $__FILE__\n};
}

if ('ア' =~ m'(a)'ib) {
    if ($1 eq 'A') {
        print qq{ok - 9 'ア' =~ m'(a)'ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 'ア' =~ m'(a)'ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 'ア' =~ m'(a)'ib $^X $__FILE__\n};
}

if ('ヂ' =~ m'(A)'ib) {
    if ($1 eq 'a') {
        print qq{ok - 10 'ヂ' =~ m'(A)'ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 'ヂ' =~ m'(A)'ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 'ヂ' =~ m'(A)'ib $^X $__FILE__\n};
}

if ('ヂ' =~ m'(a)'b) {
    if ($1 eq 'a') {
        print qq{ok - 11 'ヂ' =~ m'(a)'b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 'ヂ' =~ m'(a)'b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 'ヂ' =~ m'(a)'b $^X $__FILE__\n};
}

if ('ヂ' =~ m'(a)'ib) {
    if ($1 eq 'a') {
        print qq{ok - 12 'ヂ' =~ m'(a)'ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 12 'ヂ' =~ m'(a)'ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 12 'ヂ' =~ m'(a)'ib $^X $__FILE__\n};
}

if ('ャA' =~ m'(ア)'b) {
    if ($1 eq 'ア') {
        print qq{ok - 13 'ャA' =~ m'(ア)'b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 13 'ャA' =~ m'(ア)'b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 13 'ャA' =~ m'(ア)'b $^X $__FILE__\n};
}

if ('ャA' =~ m'(ア)'ib) {
    if ($1 eq 'ア') {
        print qq{ok - 14 'ャA' =~ m'(ア)'ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 14 'ャA' =~ m'(ア)'ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 14 'ャA' =~ m'(ア)'ib $^X $__FILE__\n};
}

if ('ャA' =~ m'(ヂ)'ib) {
    if ($1 eq 'ア') {
        print qq{ok - 15 'ャA' =~ m'(ヂ)'ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 15 'ャA' =~ m'(ヂ)'ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 15 'ャA' =~ m'(ヂ)'ib $^X $__FILE__\n};
}

if ('ャa' =~ m'(ア)'ib) {
    if ($1 eq 'ヂ') {
        print qq{ok - 16 'ャa' =~ m'(ア)'ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 16 'ャa' =~ m'(ア)'ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 16 'ャa' =~ m'(ア)'ib $^X $__FILE__\n};
}

if ('ャa' =~ m'(ヂ)'b) {
    if ($1 eq 'ヂ') {
        print qq{ok - 17 'ャa' =~ m'(ヂ)'b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 17 'ャa' =~ m'(ヂ)'b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 17 'ャa' =~ m'(ヂ)'b $^X $__FILE__\n};
}

if ('ャa' =~ m'(ヂ)'ib) {
    if ($1 eq 'ヂ') {
        print qq{ok - 18 'ャa' =~ m'(ヂ)'ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 18 'ャa' =~ m'(ヂ)'ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 18 'ャa' =~ m'(ヂ)'ib $^X $__FILE__\n};
}

__END__

