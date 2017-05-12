# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{‚ } ne "\x82\xa0";

use KPS9566;
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
