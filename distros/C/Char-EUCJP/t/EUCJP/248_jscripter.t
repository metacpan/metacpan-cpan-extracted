# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

# use strict;
use EUCJP;
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
