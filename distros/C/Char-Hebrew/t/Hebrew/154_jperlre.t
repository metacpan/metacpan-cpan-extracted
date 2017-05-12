# encoding: Hebrew
# This file is encoded in Hebrew.
die "This file is not encoded in Hebrew.\n" if q{ } ne "\x82\xa0";

use Hebrew;
print "1..1\n";

my $__FILE__ = __FILE__;

if (' e¦' =~ /( [^¢¤]¦)/) {
    if ("$1" eq " e¦") {
        print "ok - 1 $^X $__FILE__ (' e¦' =~ / [^¢¤]¦/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ (' e¦' =~ / [^¢¤]¦/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ (' e¦' =~ / [^¢¤]¦/).\n";
}

__END__
