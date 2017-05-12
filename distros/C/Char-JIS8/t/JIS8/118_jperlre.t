# encoding: JIS8
# This file is encoded in JIS8.
die "This file is not encoded in JIS8.\n" if q{‚ } ne "\x82\xa0";

use JIS8;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('‚ ‚¢q' =~ /(‚ ‚¢{1,}‚¢‚¤)/) {
    print "not ok - 1 $^X $__FILE__ not ('‚ ‚¢q' =~ /‚ ‚¢{1,}‚¢‚¤/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('‚ ‚¢q' =~ /‚ ‚¢{1,}‚¢‚¤/).\n";
}

__END__
