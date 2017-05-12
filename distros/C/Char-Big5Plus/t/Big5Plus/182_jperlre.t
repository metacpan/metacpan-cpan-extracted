# encoding: Big5Plus
# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{‚ } ne "\x82\xa0";

use Big5Plus;
print "1..1\n";

my $__FILE__ = __FILE__;

eval q< '-' =~ /‚ \/ >;
if ($@) {
    print "ok - 1 $^X $__FILE__ die ('-' =~ /‚ \\/).\n";
}
else {
    print "not ok - 1 $^X $__FILE__ die ('-' =~ /‚ \\/).\n";
}

__END__
