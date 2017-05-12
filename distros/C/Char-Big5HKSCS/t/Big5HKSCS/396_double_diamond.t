# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{�栂 ne "\x82\xa0";

use Big5HKSCS;

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
