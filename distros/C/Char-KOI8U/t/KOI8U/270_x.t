# encoding: KOI8U
# This file is encoded in KOI8-U.
die "This file is not encoded in KOI8-U.\n" if q{‚ } ne "\x82\xa0";

use strict;
use KOI8U;
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
