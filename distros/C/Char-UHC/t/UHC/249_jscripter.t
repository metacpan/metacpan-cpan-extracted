# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

use strict;
use UHC;
print "1..1\n";

my $__FILE__ = __FILE__;

my $a = 'aaa_123';
$a =~ s/^[a-z]+_([0-9]+)$/$1/;
if ($a eq '123') {
    print "ok - 1 ($a) s/// (with 'use strict') $^X $__FILE__\n";
}
else {
    print "not ok - 1 ($a) s/// (with 'use strict') $^X $__FILE__\n";
}

__END__
