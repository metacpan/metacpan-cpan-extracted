# encoding: Greek
# This file is encoded in Greek.
die "This file is not encoded in Greek.\n" if q{ } ne "\x82\xa0";

use Greek;
print "1..1\n";

my $__FILE__ = __FILE__;

if (' x€' =~ /( .€)/) {
    if ("$1" eq " x€") {
        print "ok - 1 $^X $__FILE__ (' x€' =~ / .€/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ (' x€' =~ / .€/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ (' x€' =~ / .€/).\n";
}

__END__
