# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;
print "1..8\n";

my $__FILE__ = __FILE__;

$line   = "AAAAA";
$before = "B";
$after  = "C";

# マッチしないのが正しい
if ($line !~ s/$before/$after/) {
    if ($line eq "AAAAA") {
        print qq{ok - 1 \$line !~ s/\$before/\$after/ --> ($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$line !~ s/\$before/\$after/ --> ($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$line !~ s/\$before/\$after/ --> ($line) $^X $__FILE__\n};
}

$line   = "AAAAA";
$before = "A";
$after  = "B";

# マッチするのが正しい
if ($line =~ s/$before/$after/) {
    if ($line eq "BAAAA") {
        print qq{ok - 2 \$line =~ s/\$before/\$after/ --> ($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 \$line =~ s/\$before/\$after/ --> ($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 \$line =~ s/\$before/\$after/ --> ($line) $^X $__FILE__\n};
}

$line = "CCCCC";
$ret = $line =~ s/A/B/g;

if (not $ret) {
    if ($line eq "CCCCC") {
        print qq{ok - 3 "CCCCC" =~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 "CCCCC" =~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 "CCCCC" =~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
}

$line = "ACCCC";
$ret = $line =~ s/A/B/g;

if ($ret == 1) {
    if ($line eq "BCCCC") {
        print qq{ok - 4 "ACCCC" =~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 "ACCCC" =~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 "ACCCC" =~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
}

$line = "ACACA";
$ret = $line =~ s/A/B/g;

if ($ret == 3) {
    if ($line eq "BCBCB") {
        print qq{ok - 5 "ACACA" =~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 "ACACA" =~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 "ACACA" =~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
}

$line = "CCCCC";
$ret = $line !~ s/A/B/g;

if ($ret == 1) {
    if ($line eq "CCCCC") {
        print qq{ok - 6 "CCCCC" !~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 "CCCCC" !~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 "CCCCC" !~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
}

$line = "ACCCC";
$ret = $line !~ s/A/B/g;

if (not $ret) {
    if ($line eq "BCCCC") {
        print qq{ok - 7 "ACCCC" !~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 7 "ACCCC" !~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 "ACCCC" !~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
}

$line = "ACACA";
$ret = $line !~ s/A/B/g;

if (not $ret) {
    if ($line eq "BCBCB") {
        print qq{ok - 8 "ACACA" !~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 "ACACA" !~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 "ACACA" !~ s/A/B/ --> ($ret)($line) $^X $__FILE__\n};
}

__END__
