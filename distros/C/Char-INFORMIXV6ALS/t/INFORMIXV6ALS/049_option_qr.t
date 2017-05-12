# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

use INFORMIXV6ALS;
print "1..8\n";

my $__FILE__ = __FILE__;

my $tno = 1;

# qr//i
if ("アイウエオ" !~ /a/i) {
    print qq{ok - $tno "アイウエオ" !~ /a/i $^X $__FILE__\n}
}
else {
    print qq{not ok - $tno "アイウエオ" !~ /a/i $^X $__FILE__\n}
}
$tno++;

# qr//m
if ("サシスセ\nソタチツテト" =~ qr/^ソ/m) {
    print qq{ok - $tno "サシスセ\\nソタチツテト" =~ qr/^ソ/m $^X $__FILE__\n};
}
else {
    print qq{not ok - $tno "サシスセ\\nソタチツテト" =~ qr/^ソ/m $^X $__FILE__\n};
}
$tno++;

# qr//o
@re = ("ソ","イ");
for $i (1 .. 2) {
    $re = shift @re;
    if ("ソアア" =~ qr/\Q$re\E/o) {
        print qq{ok - $tno "ソアア" =~ qr/\\Q\$re\\E/o $^X $__FILE__\n};
    }
    else {
        if ($] =~ /^5\.006/) {
            print qq{ok - $tno # SKIP "ソアア" =~ qr/\\Q\$re\\E/o $^X $__FILE__\n};
        }
        else {
            print qq{not ok - $tno "ソアア" =~ qr/\\Q\$re\\E/o $^X $__FILE__\n};
        }
    }
    $tno++;
}

@re = ("イ","ソ");
for $i (1 .. 2) {
    $re = shift @re;
    if ("ソアア" !~ qr/\Q$re\E/o) {
        print qq{ok - $tno "ソアア" !~ qr/\\Q\$re\\E/o $^X $__FILE__\n};
    }
    else {
        if ($] =~ /^5\.006/) {
            print qq{ok - $tno # SKIP "ソアア" !~ qr/\\Q\$re\\E/o $^X $__FILE__\n};
        }
        else {
            print qq{not ok - $tno "ソアア" !~ qr/\\Q\$re\\E/o $^X $__FILE__\n};
        }
    }
    $tno++;
}

# qr//s
if ("ア\nソ" =~ qr/ア.ソ/s) {
    print qq{ok - $tno "ア\\nソ" =~ qr/ア.ソ/s $^X $__FILE__\n};
}
else {
    print qq{not ok - $tno "ア\\nソ" =~ qr/ア.ソ/s $^X $__FILE__\n};
}
$tno++;

# qr//x
if ("アソソ" =~ qr/  ソ  /x) {
    print qq{ok - $tno "アソソ" =~ qr/  ソ  /x $^X $__FILE__\n};
}
else {
    print qq{not ok - $tno "アソソ" =~ qr/  ソ  /x $^X $__FILE__\n};
}
$tno++;

__END__
