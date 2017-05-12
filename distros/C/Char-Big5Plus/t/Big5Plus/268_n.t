# encoding: Big5Plus
# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{‚ } ne "\x82\xa0";

use strict;
use Big5Plus;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = "‚ \n‚©‚«‚­‚¯‚±";

if (/(\N{3})/ and ("<$1>" eq "<‚©‚«‚­>")) {
    print qq{ok - 1 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 1 $^X $__FILE__ ($1)\n};
}

if (/(\N{3,5})/ and ("<$1>" eq "<‚©‚«‚­‚¯‚±>")) {
    print qq{ok - 2 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 2 $^X $__FILE__ ($1)\n};
}

$_ = "‚ \n‚©‚«\n‚­‚¯‚±";

if (/(\N{3,})/ and ("<$1>" eq "<‚­‚¯‚±>")) {
    print qq{ok - 3 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 3 $^X $__FILE__ ($1)\n};
}

$_ = "\n\n\n‚©‚«\n‚­‚¯‚±";

if (/(\N+)/ and ("<$1>" eq "<‚©‚«>")) {
    print qq{ok - 4 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 4 $^X $__FILE__ ($1)\n};
}

__END__
