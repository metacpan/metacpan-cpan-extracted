# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{¤¢} ne "\xa4\xa2";

use strict;
use EUCTW;
print "1..4\n";

my $__FILE__ = __FILE__;

if ('¡¢¢¡' =~ m'¢¢') {
    print qq{not ok - 1 '¡¢¢¡' =~ m'¢¢' $^X $__FILE__\n};
}
else {
    print qq{ok - 1 '¡¢¢¡' =~ m'¢¢' $^X $__FILE__\n};
}

if ('¡¢¢¡' =~ m'¢¢'b) {
    print qq{ok - 2 '¡¢¢¡' =~ m'¢¢'b $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 '¡¢¢¡' =~ m'¢¢'b $^X $__FILE__\n};
}

if ('¡¢¢¡' =~ m'¢¢'i) {
    print qq{not ok - 3 '¡¢¢¡' =~ m'¢¢'i $^X $__FILE__\n};
}
else {
    print qq{ok - 3 '¡¢¢¡' =~ m'¢¢'i $^X $__FILE__\n};
}

if ('¡¢¢¡' =~ m'¢¢'ib) {
    print qq{ok - 4 '¡¢¢¡' =~ m'¢¢'ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 '¡¢¢¡' =~ m'¢¢'ib $^X $__FILE__\n};
}

__END__

