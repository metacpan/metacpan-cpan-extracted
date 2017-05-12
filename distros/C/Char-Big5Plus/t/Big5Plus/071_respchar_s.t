# encoding: Big5Plus
# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{あ} ne "\x82\xa0";

use Big5Plus;
print "1..1\n";

my $__FILE__ = __FILE__;

$a = "アソア";
if ($a !~ s/(ア([イウエ])ア)//) {
    print qq{ok - 1 "アソア" !~ s/(ア([イウエ])ア)// \$1=(), \$2=() $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "アソア" !~ s/(ア([イソウ])ア)// \$1=($1), \$2=($2) $^X $__FILE__\n};
}

__END__
