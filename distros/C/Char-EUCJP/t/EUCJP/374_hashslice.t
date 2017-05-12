# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;

BEGIN {
    print "1..2\n";
    if ($] < 5.020) {
        for my $tno (1..2) {
            print qq{ok - $tno SKIP $^X @{[__FILE__]}\n};
        }
        exit;
    }
}

@array = (qw(あか あお き むらさきいろ));
if (join(',',%array[0,1]) eq join(',',%array[0,1])) {
    print qq{ok - 1 join(',',%array[0,1]) eq join(',',%array[0,1]) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 join(',',%array[0,1]) eq join(',',%array[0,1]) $^X @{[__FILE__]}\n};
}

%hash = (red => 1, blue => 2, yellow => 3, violet => 4);
if (join(',',%hash{qw(blue yellow)}) eq join(',',%hash{qw(blue yellow)})) {
    print qq{ok - 2 join(',',%hash{qw(blue yellow)}) eq join(',',%hash{qw(blue yellow)}) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 join(',',%hash{qw(blue yellow)}) eq join(',',%hash{qw(blue yellow)}) $^X @{[__FILE__]}\n};
}

__END__
