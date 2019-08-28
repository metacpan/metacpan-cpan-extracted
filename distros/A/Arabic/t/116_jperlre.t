# encoding: Arabic
# This file is encoded in Arabic.
die "This file is not encoded in Arabic.\n" if q{‚ } ne "\x82\xa0";

use Arabic;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('‚ ‚¢‚¤' =~ /(‚ ‚¢+‚¢‚¤)/) {
    print "not ok - 1 $^X $__FILE__ not ('‚ ‚¢‚¤' =~ /‚ ‚¢+‚¢‚¤/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('‚ ‚¢‚¤' =~ /‚ ‚¢+‚¢‚¤/).\n";
}

__END__
