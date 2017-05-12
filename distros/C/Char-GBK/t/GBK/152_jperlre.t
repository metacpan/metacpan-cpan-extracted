# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('偁]' =~ /(偁])/) {
    if ("$1" eq "偁]") {
        print "ok - 1 $^X $__FILE__ ('偁]' =~ /偁]/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('偁]' =~ /偁]/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('偁]' =~ /偁]/).\n";
}

__END__
