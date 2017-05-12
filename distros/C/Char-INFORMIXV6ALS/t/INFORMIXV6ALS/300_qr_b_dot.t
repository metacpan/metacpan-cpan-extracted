# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{‚ } ne "\x82\xa0";

use strict;
use INFORMIXV6ALS;
print "1..2\n";

my $__FILE__ = __FILE__;

if ('‚ ' =~ qr/(.)/b) {
    if (length($1) == 1) {
        print qq{ok - 1 '‚ '=~qr/(.)/b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 '‚ '=~qr/(.)/b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 '‚ '=~qr/(.)/b; length(\$1)==1 $^X $__FILE__\n};
}

if ('‚ ' =~ qr'(.)'b) {
    if (length($1) == 1) {
        print qq{ok - 2 '‚ '=~qr'(.)'b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 '‚ '=~qr'(.)'b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 '‚ '=~qr'(.)'b; length(\$1)==1 $^X $__FILE__\n};
}

__END__

