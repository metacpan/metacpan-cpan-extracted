# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use strict;
use EUCJP;
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
