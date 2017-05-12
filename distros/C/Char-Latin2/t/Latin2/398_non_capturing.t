# encoding: Latin2
# This file is encoded in Latin-2.
die "This file is not encoded in Latin-2.\n" if q{ } ne "\x82\xa0";

use Latin2;

print "1..1\n";
if ($] < 5.022) {
    for my $tno (1..1) {
        print qq{ok - $tno SKIP $^X @{[__FILE__]}\n};
    }
    exit;
}

local $_ = eval q{ '' =~ /(re|regexp)/n };
if (not $@) {
    print qq{ok - 1 /(re|regexp)/n $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 /(re|regexp)/n $^X @{[__FILE__]}\n};
}

__END__
