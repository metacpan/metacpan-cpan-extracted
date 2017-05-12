# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{‚ } ne "\x82\xa0";

use strict;
use INFORMIXV6ALS;
print "1..1024\n";

my $__FILE__ = __FILE__;

my $tno = 1;

for my $ord (0x00..0x7F) {
    $_ = chr($ord);
    if (/[abcdefghijklmnopqrstuvwxyz]/) {
        if (/[[:lower:]]/) {
            printf qq{ok - $tno "\\x%02X" =~ /[[:lower:]]/ $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:lower:]]/ $^X $__FILE__\n}, $ord;
        }
    }
    else {
        if (/[[:lower:]]/) {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:lower:]]/ $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{ok - $tno "\\x%02X" =~ /[[:lower:]]/ $^X $__FILE__\n}, $ord;
        }
    }
    $tno++;
}

for my $ord (0x00..0x7F) {
    $_ = chr($ord);
    if (/[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz]/) {
        if (/[[:lower:]]/i) {
            printf qq{ok - $tno "\\x%02X" =~ /[[:lower:]]/i $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:lower:]]/i $^X $__FILE__\n}, $ord;
        }
    }
    else {
        if (/[[:lower:]]/i) {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:lower:]]/i $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{ok - $tno "\\x%02X" =~ /[[:lower:]]/i $^X $__FILE__\n}, $ord;
        }
    }
    $tno++;
}

for my $ord (0x00..0x7F) {
    $_ = chr($ord);
    if (/[ABCDEFGHIJKLMNOPQRSTUVWXYZ]/) {
        if (/[[:upper:]]/) {
            printf qq{ok - $tno "\\x%02X" =~ /[[:upper:]]/ $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:upper:]]/ $^X $__FILE__\n}, $ord;
        }
    }
    else {
        if (/[[:upper:]]/) {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:upper:]]/ $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{ok - $tno "\\x%02X" =~ /[[:upper:]]/ $^X $__FILE__\n}, $ord;
        }
    }
    $tno++;
}

for my $ord (0x00..0x7F) {
    $_ = chr($ord);
    if (/[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz]/) {
        if (/[[:upper:]]/i) {
            printf qq{ok - $tno "\\x%02X" =~ /[[:upper:]]/i $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:upper:]]/i $^X $__FILE__\n}, $ord;
        }
    }
    else {
        if (/[[:upper:]]/i) {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:upper:]]/i $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{ok - $tno "\\x%02X" =~ /[[:upper:]]/i $^X $__FILE__\n}, $ord;
        }
    }
    $tno++;
}

for my $ord (0x00..0x7F) {
    $_ = chr($ord);
    if (/[abcdefghijklmnopqrstuvwxyz]/) {
        if (/[[:^lower:]]/) {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:^lower:]]/ $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{ok - $tno "\\x%02X" =~ /[[:^lower:]]/ $^X $__FILE__\n}, $ord;
        }
    }
    else {
        if (/[[:^lower:]]/) {
            printf qq{ok - $tno "\\x%02X" =~ /[[:^lower:]]/ $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:^lower:]]/ $^X $__FILE__\n}, $ord;
        }
    }
    $tno++;
}

for my $ord (0x00..0x7F) {
    $_ = chr($ord);
    if (/[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz]/) {
        if (/[[:^lower:]]/i) {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:^lower:]]/i $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{ok - $tno "\\x%02X" =~ /[[:^lower:]]/i $^X $__FILE__\n}, $ord;
        }
    }
    else {
        if (/[[:^lower:]]/i) {
            printf qq{ok - $tno "\\x%02X" =~ /[[:^lower:]]/i $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:^lower:]]/i $^X $__FILE__\n}, $ord;
        }
    }
    $tno++;
}

for my $ord (0x00..0x7F) {
    $_ = chr($ord);
    if (/[ABCDEFGHIJKLMNOPQRSTUVWXYZ]/) {
        if (/[[:^upper:]]/) {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:^upper:]]/ $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{ok - $tno "\\x%02X" =~ /[[:^upper:]]/ $^X $__FILE__\n}, $ord;
        }
    }
    else {
        if (/[[:^upper:]]/) {
            printf qq{ok - $tno "\\x%02X" =~ /[[:^upper:]]/ $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:^upper:]]/ $^X $__FILE__\n}, $ord;
        }
    }
    $tno++;
}

for my $ord (0x00..0x7F) {
    $_ = chr($ord);
    if (/[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz]/) {
        if (/[[:^upper:]]/i) {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:^upper:]]/i $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{ok - $tno "\\x%02X" =~ /[[:^upper:]]/i $^X $__FILE__\n}, $ord;
        }
    }
    else {
        if (/[[:^upper:]]/i) {
            printf qq{ok - $tno "\\x%02X" =~ /[[:^upper:]]/i $^X $__FILE__\n}, $ord;
        }
        else {
            printf qq{not ok - $tno "\\x%02X" =~ /[[:^upper:]]/i $^X $__FILE__\n}, $ord;
        }
    }
    $tno++;
}

__END__
