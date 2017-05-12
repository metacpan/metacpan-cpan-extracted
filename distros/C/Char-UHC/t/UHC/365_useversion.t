# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use 5.00503;
use UHC;
print "1..1\n";

print "ok - 1 $^X $__FILE__\n";

__END__
