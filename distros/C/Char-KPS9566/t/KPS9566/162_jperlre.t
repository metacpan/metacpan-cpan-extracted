# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{‚ } ne "\x82\xa0";

use KPS9566;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('‚  ‚¢' =~ /(‚ \S‚¢)/) {
    print "not ok - 1 $^X $__FILE__ not ('‚  ‚¢' =~ /‚ \\S‚¢/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('‚  ‚¢' =~ /‚ \\S‚¢/).\n";
}

__END__
