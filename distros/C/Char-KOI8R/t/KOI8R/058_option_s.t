# encoding: KOI8R
# This file is encoded in KOI8-R.
die "This file is not encoded in KOI8-R.\n" if q{‚ } ne "\x82\xa0";

use KOI8R;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///e
$a = "‚ ‚¢‚¤‚¦‚¨H41‚©‚«‚­‚¯‚±";
if ($a =~ s/H([0-9A-Fa-f]{2})/sprintf('[%c]',hex($1))/e) {
    if ($a eq "‚ ‚¢‚¤‚¦‚¨[A]‚©‚«‚­‚¯‚±") {
        print qq{ok - 1 \$a =~ s/H([0-9A-Fa-f]{2})/sprintf('[%c]',hex(\$1))/e ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/H([0-9A-Fa-f]{2})/sprintf('[%c]',hex(\$1))/e ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/H([0-9A-Fa-f]{2})/sprintf('[%c]',hex(\$1))/e ($a) $^X $__FILE__\n};
}

__END__
