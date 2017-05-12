# encoding: Big5Plus
# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{‚ } ne "\x82\xa0";

use Big5Plus;
print "1..2\n";

my $__FILE__ = __FILE__;

if (Big5Plus::ord('‚ ') == 0x82A0) {
    print qq{ok - 1 Big5Plus::ord('‚ ') == 0x82A0 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 Big5Plus::ord('‚ ') == 0x82A0 $^X $__FILE__\n};
}

$_ = '‚¢';
if (Big5Plus::ord == 0x82A2) {
    print qq{ok - 2 \$_ = '‚¢'; Big5Plus::ord == 0x82A2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ = '‚¢'; Big5Plus::ord == 0x82A2 $^X $__FILE__\n};
}

__END__
