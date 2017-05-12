# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{‚ } ne "\x82\xa0";

# use strict;
use INFORMIXV6ALS;
print "1..1\n";

my $__FILE__ = __FILE__;

my $a = 'aaa_123';
$a =~ s/^[a-z]+_([0-9]+)$/$1/;
if ($a eq '123') {
    print "ok - 1 s/// (without 'use strict') ($a) $^X $__FILE__\n";
}
else {
    print "not ok - 1 s/// (without 'use strict') ($a) $^X $__FILE__\n";
}

__END__
