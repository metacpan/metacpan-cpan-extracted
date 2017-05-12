# encoding: USASCII
# This file is encoded in US-ASCII.
die "This file is not encoded in US-ASCII.\n" if q{‚ } ne "\x82\xa0";

my $__FILE__ = __FILE__;

use 5.005;
use USASCII;
print "1..1\n";

print "ok - 1 $^X $__FILE__\n";

__END__
