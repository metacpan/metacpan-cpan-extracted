# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

my $__FILE__ = __FILE__;

use 5.00503;
use OldUTF8;
print "1..1\n";

print "ok - 1 $^X $__FILE__\n";

__END__
