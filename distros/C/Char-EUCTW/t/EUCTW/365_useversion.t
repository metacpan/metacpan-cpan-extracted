# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{дв} ne "\xa4\xa2";

my $__FILE__ = __FILE__;

use 5.00503;
use EUCTW;
print "1..1\n";

print "ok - 1 $^X $__FILE__\n";

__END__
