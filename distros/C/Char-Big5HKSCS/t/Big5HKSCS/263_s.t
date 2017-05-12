# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{�栂 ne "\x82\xa0";

use strict;
use Big5HKSCS;
print "1..1\n";

my $__FILE__ = __FILE__;

$_ = 'C:/Perl/site/lib';
$_ =~ s#/#\\#g;

if ($_ eq 'C:\\Perl\\site\\lib') {
    print qq{ok - 1 \$_ =~ s#/#\\\\#g; $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \$_ =~ s#/#\\\\#g; $^X $__FILE__\n};
}

__END__
