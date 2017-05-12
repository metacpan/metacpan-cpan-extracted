# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..2\n";

my $__FILE__ = __FILE__;

if (GB18030::ord('偁') == 0x82A0) {
    print qq{ok - 1 GB18030::ord('偁') == 0x82A0 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 GB18030::ord('偁') == 0x82A0 $^X $__FILE__\n};
}

$_ = '偄';
if (GB18030::ord == 0x82A2) {
    print qq{ok - 2 \$_ = '偄'; GB18030::ord == 0x82A2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ = '偄'; GB18030::ord == 0x82A2 $^X $__FILE__\n};
}

__END__
