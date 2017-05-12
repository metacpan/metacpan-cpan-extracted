# encoding: KOI8U
# This file is encoded in KOI8-U.
die "This file is not encoded in KOI8-U.\n" if q{‚ } ne "\x82\xa0";

use strict;
use KOI8U;
print "1..1306\n";

my $__FILE__ = __FILE__;

my $tno = 1;

for my $ord (0x30..0x39, 0x41..0x5A, 0x61..0x7A) {
    $_ = chr($ord);
    if (/[[:alnum:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:alnum:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:alnum:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^alnum:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^alnum:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^alnum:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x41..0x5A, 0x61..0x7A) {
    $_ = chr($ord);
    if (/[[:alpha:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:alpha:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:alpha:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^alpha:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^alpha:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^alpha:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00..0x7F) {
    $_ = chr($ord);
    if (/[[:ascii:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:ascii:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:ascii:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^ascii:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^ascii:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^ascii:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x09, 0x20) {
    $_ = chr($ord);
    if (/[[:blank:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:blank:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:blank:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^blank:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^blank:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^blank:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00..0x1F, 0x7F) {
    $_ = chr($ord);
    if (/[[:cntrl:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:cntrl:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:cntrl:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^cntrl:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^cntrl:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^cntrl:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x30..0x39) {
    $_ = chr($ord);
    if (/[[:digit:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:digit:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:digit:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^digit:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^digit:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^digit:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x21..0x7F) {
    $_ = chr($ord);
    if (/[[:graph:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:graph:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:graph:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^graph:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^graph:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^graph:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x61..0x7A) {
    $_ = chr($ord);
    if (/[[:lower:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:lower:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:lower:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^lower:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^lower:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^lower:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x20..0x7F) {
    $_ = chr($ord);
    if (/[[:print:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:print:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:print:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^print:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^print:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^print:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x21..0x2F, 0x3A..0x3F, 0x40, 0x5B..0x5F, 0x60, 0x7B..0x7E) {
    $_ = chr($ord);
    if (/[[:punct:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:punct:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:punct:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^punct:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^punct:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^punct:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x20) {
    $_ = chr($ord);
    if (/[[:space:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:space:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:space:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^space:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^space:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^space:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x41..0x5A) {
    $_ = chr($ord);
    if (/[[:upper:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:upper:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:upper:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^upper:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^upper:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^upper:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x30..0x39, 0x41..0x5A, 0x5F, 0x61..0x7A) {
    $_ = chr($ord);
    if (/[[:word:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:word:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:word:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^word:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^word:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^word:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x30..0x39, 0x41..0x46, 0x61..0x66) {
    $_ = chr($ord);
    if (/[[:xdigit:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:xdigit:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:xdigit:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
    if (not /[[:^xdigit:]]/) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:^xdigit:]]/ $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:^xdigit:]]/ $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

__END__
