# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

# use strict;
use OldUTF8;
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
