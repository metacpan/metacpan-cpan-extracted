# encoding: Latin4
# This file is encoded in Latin-4.
die "This file is not encoded in Latin-4.\n" if q{‚ } ne "\x82\xa0";

use Latin4;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('‚  ‚¢' =~ /(‚ [\s]‚¢)/) {
    if ("-" eq "-") {
        print "ok - 1 $^X $__FILE__ ('‚  ‚¢' =~ /‚ [\\s]‚¢/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('‚  ‚¢' =~ /‚ [\\s]‚¢/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('‚  ‚¢' =~ /‚ [\\s]‚¢/).\n";
}

__END__
