# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use strict;
use UTF2;
print "1..2\n";

my $__FILE__ = __FILE__;

if ('ABC' =~ /(\X)/) {
    print qq{not ok - 1 'ABC' =~ /(\\X)/ ($1) $^X $__FILE__\n};
}
else {
    print qq{ok - 1 'ABC' =~ /(\\X)/ $^X $__FILE__\n};
}

if ('ABCXYZ' =~ /(\X)/) {
    print qq{ok - 2 'ABCXYZ' =~ /(\\X)/ ($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 'ABCXYZ' =~ /(\\X)/ $^X $__FILE__\n};
}

__END__
