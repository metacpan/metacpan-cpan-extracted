# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('偁偄偄偆' =~ /(偁偄?偄偆)/) {
    if ("$1" eq "偁偄偄偆") {
        print "ok - 1 $^X $__FILE__ ('偁偄偄偆' =~ /偁偄?偄偆/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('偁偄偄偆' =~ /偁偄?偄偆/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('偁偄偄偆' =~ /偁偄?偄偆/).\n";
}

__END__
