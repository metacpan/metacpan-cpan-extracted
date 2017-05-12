# encoding: Hebrew
# This file is encoded in Hebrew.
die "This file is not encoded in Hebrew.\n" if q{ } ne "\x82\xa0";

my $__FILE__ = __FILE__;

use 5.005;
use Hebrew;
print "1..1\n";

print "ok - 1 $^X $__FILE__\n";

__END__
