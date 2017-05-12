# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{‚ } ne "\x82\xa0";

use HP15;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = '‚ ‚¢‚¤‚¦‚¨‚ ‚¢‚¤‚¦‚¨';
if (index($_,'‚¤‚¦') == 4) {
    print qq{ok - 1 index(\$_,'‚¤‚¦') == 4 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 index(\$_,'‚¤‚¦') == 4 $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚ ‚¢‚¤‚¦‚¨';
if (index($_,'‚¤‚¦',6) == 14) {
    print qq{ok - 2 index(\$_,'‚¤‚¦',6) == 14 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 index(\$_,'‚¤‚¦',6) == 14 $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚ ‚¢‚¤‚¦‚¨';
if (HP15::index($_,'‚¤‚¦') == 2) {
    print qq{ok - 3 HP15::index(\$_,'‚¤‚¦') == 2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 HP15::index(\$_,'‚¤‚¦') == 2 $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚ ‚¢‚¤‚¦‚¨';
if (HP15::index($_,'‚¤‚¦',3) == 7) {
    print qq{ok - 4 HP15::index(\$_,'‚¤‚¦',3) == 7 $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 HP15::index(\$_,'‚¤‚¦',3) == 7 $^X $__FILE__\n};
}

__END__
