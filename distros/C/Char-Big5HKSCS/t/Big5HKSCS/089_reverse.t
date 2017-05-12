# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{‚ } ne "\x82\xa0";

use Big5HKSCS;
print "1..2\n";

my $__FILE__ = __FILE__;

@_ = Big5HKSCS::reverse('‚ ‚¢‚¤‚¦‚¨', '‚©‚«‚­‚¯‚±', '‚³‚µ‚·‚¹‚»');
if ("@_" eq "‚³‚µ‚·‚¹‚» ‚©‚«‚­‚¯‚± ‚ ‚¢‚¤‚¦‚¨") {
    print qq{ok - 1 \@_ = reverse('‚ ‚¢‚¤‚¦‚¨', '‚©‚«‚­‚¯‚±', '‚³‚µ‚·‚¹‚»') $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \@_ = reverse('‚ ‚¢‚¤‚¦‚¨', '‚©‚«‚­‚¯‚±', '‚³‚µ‚·‚¹‚»') $^X $__FILE__\n};
}

$_ = Big5HKSCS::reverse('‚ ‚¢‚¤‚¦‚¨', '‚©‚«‚­‚¯‚±', '‚³‚µ‚·‚¹‚»');
if ($_ eq "‚»‚¹‚·‚µ‚³‚±‚¯‚­‚«‚©‚¨‚¦‚¤‚¢‚ ") {
    print qq{ok - 2 \$_ = reverse('‚ ‚¢‚¤‚¦‚¨', '‚©‚«‚­‚¯‚±', '‚³‚µ‚·‚¹‚»') $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ = reverse('‚ ‚¢‚¤‚¦‚¨', '‚©‚«‚­‚¯‚±', '‚³‚µ‚·‚¹‚»') $^X $__FILE__\n};
}

__END__
