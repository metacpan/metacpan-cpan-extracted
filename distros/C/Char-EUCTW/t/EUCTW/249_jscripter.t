# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{дв} ne "\xa4\xa2";

use strict;
use EUCTW;
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
