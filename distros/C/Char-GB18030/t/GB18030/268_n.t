# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use strict;
use GB18030;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = "偁\n偐偒偔偗偙";

if (/(\N{3})/ and ("<$1>" eq "<偐偒偔>")) {
    print qq{ok - 1 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 1 $^X $__FILE__ ($1)\n};
}

if (/(\N{3,5})/ and ("<$1>" eq "<偐偒偔偗偙>")) {
    print qq{ok - 2 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 2 $^X $__FILE__ ($1)\n};
}

$_ = "偁\n偐偒\n偔偗偙";

if (/(\N{3,})/ and ("<$1>" eq "<偔偗偙>")) {
    print qq{ok - 3 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 3 $^X $__FILE__ ($1)\n};
}

$_ = "\n\n\n偐偒\n偔偗偙";

if (/(\N+)/ and ("<$1>" eq "<偐偒>")) {
    print qq{ok - 4 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 4 $^X $__FILE__ ($1)\n};
}

__END__
