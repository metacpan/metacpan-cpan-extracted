# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{¤¢} ne "\xa4\xa2";

use strict;
use EUCTW;
print "1..12\n";

my $__FILE__ = __FILE__;

my @split = ();

@split = split(/A/, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 1 split(/A/, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 split(/A/, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/i, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 2 split(/a/i, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 split(/a/i, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 3 split(/A/, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 3 split(/A/, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/i, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 4 split(/a/i, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 split(/a/i, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/¢¢/, join('¡¢¢¡', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 5 split(/¢¢/, join('¡¢¢¡', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 5 split(/¢¢/, join('¡¢¢¡', 1..10)) $^X $__FILE__\n};
}

@split = split(/¢¢/i, join('¡¢¢¡', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 6 split(/¢¢/i, join('¡¢¢¡', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 6 split(/¢¢/i, join('¡¢¢¡', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/b, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 7 split(/A/b, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 split(/A/b, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/A/b, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 8 split(/A/b, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 8 split(/A/b, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/¢¢/b, join('¡¢¢¡', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 9 split(/¢¢/b, join('¡¢¢¡', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 split(/¢¢/b, join('¡¢¢¡', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/ib, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 10 split(/a/ib, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 split(/a/ib, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(/a/ib, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 11 split(/a/ib, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 split(/a/ib, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(/¢¢/ib, join('¡¢¢¡', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 12 split(/¢¢/ib, join('¡¢¢¡', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 split(/¢¢/ib, join('¡¢¢¡', 1..10)) $^X $__FILE__\n};
}

__END__

