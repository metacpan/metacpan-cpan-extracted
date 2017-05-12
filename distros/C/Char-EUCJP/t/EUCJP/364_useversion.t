# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

my $__FILE__ = __FILE__;

use 5.005;
use EUCJP;
print "1..1\n";

print "ok - 1 $^X $__FILE__\n";

__END__
