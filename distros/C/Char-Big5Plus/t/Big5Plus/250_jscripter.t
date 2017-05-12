# encoding: Big5Plus
# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{‚ } ne "\x82\xa0";

# use strict;
use Big5Plus;
print "1..1\n";

my $__FILE__ = __FILE__;

my $a = 'aaa_123';
$a =~ s/[a-z]+_([0-9]+)/$1/g;
if ($a eq '123') {
    print "ok - 1 s///g (without 'use strict') ($a) $^X $__FILE__\n";
}
else {
    print "not ok - 1 s///g (without 'use strict') ($a) $^X $__FILE__\n";
}

__END__
