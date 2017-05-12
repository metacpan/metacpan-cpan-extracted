# encoding: Latin3
# This file is encoded in Latin-3.
die "This file is not encoded in Latin-3.\n" if q{ } ne "\x82\xa0";

use Latin3;
print "1..1\n";

my $__FILE__ = __FILE__;

if (' -˘' =~ /( [\s]˘)/) {
    print "not ok - 1 $^X $__FILE__ not (' -˘' =~ / [\\s]˘/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not (' -˘' =~ / [\\s]˘/).\n";
}

__END__
