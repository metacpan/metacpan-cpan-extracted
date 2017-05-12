# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use strict;
use EUCJP;
print "1..12\n";

my $__FILE__ = __FILE__;

my @split = ();

@split = split(qr'A', join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 1 split(qr'A', join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 split(qr'A', join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(qr'a'i, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 2 split(qr'a'i, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 split(qr'a'i, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(qr'A', join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 3 split(qr'A', join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 3 split(qr'A', join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(qr'a'i, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 4 split(qr'a'i, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 split(qr'a'i, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(qr'□', join('、◆', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 5 split(qr'□', join('、◆', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 5 split(qr'□', join('、◆', 1..10)) $^X $__FILE__\n};
}

@split = split(qr'□'i, join('、◆', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 6 split(qr'□'i, join('、◆', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 6 split(qr'□'i, join('、◆', 1..10)) $^X $__FILE__\n};
}

@split = split(qr'A'b, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 7 split(qr'A'b, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 split(qr'A'b, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(qr'A'b, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 8 split(qr'A'b, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 8 split(qr'A'b, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(qr'□'b, join('、◆', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 9 split(qr'□'b, join('、◆', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 split(qr'□'b, join('、◆', 1..10)) $^X $__FILE__\n};
}

@split = split(qr'a'ib, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 10 split(qr'a'ib, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 split(qr'a'ib, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(qr'a'ib, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 11 split(qr'a'ib, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 split(qr'a'ib, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(qr'□'ib, join('、◆', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 12 split(qr'□'ib, join('、◆', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 split(qr'□'ib, join('、◆', 1..10)) $^X $__FILE__\n};
}

__END__

