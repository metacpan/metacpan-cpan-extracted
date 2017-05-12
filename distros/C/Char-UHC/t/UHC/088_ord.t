# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

use UHC;
print "1..2\n";

my $__FILE__ = __FILE__;

if (UHC::ord('궇') == 0x82A0) {
    print qq{ok - 1 UHC::ord('궇') == 0x82A0 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 UHC::ord('궇') == 0x82A0 $^X $__FILE__\n};
}

$_ = '궋';
if (UHC::ord == 0x82A2) {
    print qq{ok - 2 \$_ = '궋'; UHC::ord == 0x82A2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ = '궋'; UHC::ord == 0x82A2 $^X $__FILE__\n};
}

__END__
