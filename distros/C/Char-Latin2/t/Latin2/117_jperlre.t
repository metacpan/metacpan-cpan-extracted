# encoding: Latin2
# This file is encoded in Latin-2.
die "This file is not encoded in Latin-2.\n" if q{ } ne "\x82\xa0";

use Latin2;
print "1..1\n";

my $__FILE__ = __FILE__;

if (' ˘q' =~ /( ˘+˘¤)/) {
    print "not ok - 1 $^X $__FILE__ not (' ˘q' =~ / ˘+˘¤/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not (' ˘q' =~ / ˘+˘¤/).\n";
}

__END__
