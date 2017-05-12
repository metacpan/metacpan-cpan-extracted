# encoding: Latin2
# This file is encoded in Latin-2.
die "This file is not encoded in Latin-2.\n" if q{ } ne "\x82\xa0";

# use strict;
use Latin2;
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
