# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{дв} ne "\xa4\xa2";

use strict;
use EUCTW;
print "1..1\n";

my $__FILE__ = __FILE__;

my $var1 = 'ABCDEFGH';
my $re = 'dEf';
if ($var1 =~ /C($re)g/i) {
    print qq{ok - 1 \$var1=~/C(\$re)g/i, \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \$var1=~/C(\$re)g/i, \$1=($1) $^X $__FILE__\n};
}

__END__
