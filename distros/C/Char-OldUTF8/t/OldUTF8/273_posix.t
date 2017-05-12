# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use strict;
use OldUTF8;
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
