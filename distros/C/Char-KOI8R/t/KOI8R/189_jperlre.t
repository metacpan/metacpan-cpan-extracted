# encoding: KOI8R
# This file is encoded in KOI8-R.
die "This file is not encoded in KOI8-R.\n" if q{‚ } ne "\x82\xa0";

use KOI8R;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('‚ -‚¢' =~ /‚ [^-]‚¢/) {
    print "not ok - 1 $^X $__FILE__ ('‚ -‚¢' =~ /‚ [^-]‚¢/)\n";
}
else {
    print "ok - 1 $^X $__FILE__ ('‚ -‚¢' =~ /‚ [^-]‚¢/)\n";
}

__END__
