# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{��} ne "\xa4\xa2";

use EUCJP;

print "1..1\n";
if ($] < 5.022) {
    for my $tno (1..1) {
        print qq{ok - $tno SKIP $^X @{[__FILE__]}\n};
    }
    exit;
}

eval q{ undef @ARGV; close STDIN; <<>> };
if (not $@) {
    print qq{ok - 1 <<>> $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 <<>> $^X @{[__FILE__]}\n};
}

__END__
