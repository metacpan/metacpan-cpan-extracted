# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;
print "1..10\n";

my $__FILE__ = __FILE__;

my $tno = 1;

# m//i
if ("アイウエオ" !~ /a/i) {
    print qq{ok - $tno "アイウエオ" !~ /a/i $^X $__FILE__\n}
}
else {
    print qq{not ok - $tno "アイウエオ" !~ /a/i $^X $__FILE__\n}
}
$tno++;

# m//m
if ("サシスセ\nソタチツテト" =~ m/^ソ/m) {
    print qq{ok - $tno "サシスセ\\nソタチツテト" =~ m/^ソ/m $^X $__FILE__\n};
}
else {
    print qq{not ok - $tno "サシスセ\\nソタチツテト" =~ m/^ソ/m $^X $__FILE__\n};
}
$tno++;

if ("サシスセソ\nタチツテト" =~ m/ソ$/m) {
    print qq{ok - $tno "サシスセソ\\nタチツテト" =~ m/ソ\$/m $^X $__FILE__\n};
}
else {
    print qq{not ok - $tno "サシスセソ\\nタチツテト" =~ m/ソ\$/m $^X $__FILE__\n};
}
$tno++;

if ("サシスセ\nソ\nタチツテト" =~ m/^ソ$/m) {
    print qq{ok - $tno "サシスセ\\nソ\\nタチツテト" =~ m/^ソ\$/m $^X $__FILE__\n};
}
else {
    print qq{not ok - $tno "サシスセ\\nソ\\nタチツテト" =~ m/^ソ\$/m $^X $__FILE__\n};
}
$tno++;

# m//o
@re = ("ソ","イ");
for $i (1 .. 2) {
    $re = shift @re;
    if ("ソアア" =~ m/\Q$re\E/o) {
        print qq{ok - $tno "ソアア" =~ m/\\Q\$re\\E/o $^X $__FILE__\n};
    }
    else {
        if ($] =~ /^5\.006/) {
            print qq{ok - $tno # SKIP "ソアア" =~ m/\\Q\$re\\E/o $^X $__FILE__\n};
        }
        else {
            print qq{not ok - $tno "ソアア" =~ m/\\Q\$re\\E/o $^X $__FILE__\n};
        }
    }
    $tno++;
}

@re = ("イ","ソ");
for $i (1 .. 2) {
    $re = shift @re;
    if ("ソアア" !~ m/\Q$re\E/o) {
        print qq{ok - $tno "ソアア" !~ m/\\Q\$re\\E/o $^X $__FILE__\n};
    }
    else {
        if ($] =~ /^5\.006/) {
            print qq{ok - $tno # SKIP "ソアア" !~ m/\\Q\$re\\E/o $^X $__FILE__\n};
        }
        else {
            print qq{not ok - $tno "ソアア" !~ m/\\Q\$re\\E/o $^X $__FILE__\n};
        }
    }
    $tno++;
}

# m//s
if ("ア\nソ" =~ m/ア.ソ/s) {
    print qq{ok - $tno "ア\\nソ" =~ m/ア.ソ/s $^X $__FILE__\n};
}
else {
    print qq{not ok - $tno "ア\\nソ" =~ m/ア.ソ/s $^X $__FILE__\n};
}
$tno++;

# m//x
if ("アソソ" =~ m/  ソ  /x) {
    print qq{ok - $tno "アソソ" =~ m/  ソ  /x $^X $__FILE__\n};
}
else {
    print qq{not ok - $tno "アソソ" =~ m/  ソ  /x $^X $__FILE__\n};
}
$tno++;

__END__
