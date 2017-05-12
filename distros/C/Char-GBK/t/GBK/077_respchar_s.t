# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..1\n";

my $__FILE__ = __FILE__;

$a = "傾僜僜";
if ($a !~ s/(僀僜僜?)//) {
    print qq{ok - 1 "傾僜僜" !~ s/(僀僜僜?)// \$1=() $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "傾僜僜" !~ s/(僀僜僜?)// \$1=($1) $^X $__FILE__\n};
}

__END__
