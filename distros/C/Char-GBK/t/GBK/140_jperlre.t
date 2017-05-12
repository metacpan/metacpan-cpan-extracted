# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('偁xyz偆' =~ /(偁.*偆)/) {
    if ("$1" eq "偁xyz偆") {
        print "ok - 1 $^X $__FILE__ ('偁xyz偆' =~ /偁.*偆/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('偁xyz偆' =~ /偁.*偆/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('偁xyz偆' =~ /偁.*偆/).\n";
}

__END__
