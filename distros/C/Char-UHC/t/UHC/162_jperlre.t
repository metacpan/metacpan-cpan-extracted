# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

use UHC;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('궇 궋' =~ /(궇\S궋)/) {
    print "not ok - 1 $^X $__FILE__ not ('궇 궋' =~ /궇\\S궋/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('궇 궋' =~ /궇\\S궋/).\n";
}

__END__
