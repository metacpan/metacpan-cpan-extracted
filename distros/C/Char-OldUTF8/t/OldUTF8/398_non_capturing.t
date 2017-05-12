# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use OldUTF8;

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
