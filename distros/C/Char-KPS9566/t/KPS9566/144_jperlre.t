# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{‚ } ne "\x82\xa0";

use KPS9566;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('‚ ‚¢‚¦' =~ /(‚ [‚¢-‚¦]e)/) {
    print "not ok - 1 $^X $__FILE__ not ('‚ ‚¢‚¦' =~ /‚ [‚¢-‚¦]e/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('‚ ‚¢‚¦' =~ /‚ [‚¢-‚¦]e/).\n";
}

__END__
