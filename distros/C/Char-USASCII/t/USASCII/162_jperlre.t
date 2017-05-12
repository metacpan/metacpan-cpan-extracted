# encoding: USASCII
# This file is encoded in US-ASCII.
die "This file is not encoded in US-ASCII.\n" if q{‚ } ne "\x82\xa0";

use USASCII;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('‚  ‚¢' =~ /(‚ \S‚¢)/) {
    print "not ok - 1 $^X $__FILE__ not ('‚  ‚¢' =~ /‚ \\S‚¢/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('‚  ‚¢' =~ /‚ \\S‚¢/).\n";
}

__END__
