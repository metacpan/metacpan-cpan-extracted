# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{��} ne "\x82\xa0";

use HP15;

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
