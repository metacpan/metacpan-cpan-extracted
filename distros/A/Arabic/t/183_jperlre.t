# encoding: Arabic
# This file is encoded in Arabic.
die "This file is not encoded in Arabic.\n" if q{‚ } ne "\x82\xa0";

use Arabic;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('‚ (‚¢' =~ /(‚ \(‚¢)/) {
    local $^W = 0;
    if ("$&-$2" eq "‚ (‚¢-") {
        print "ok - 1 $^X $__FILE__ ('‚ (‚¢' =~ /‚ \(‚¢/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('‚ (‚¢' =~ /‚ \(‚¢/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('‚ (‚¢' =~ /‚ \(‚¢/).\n";
}

__END__
