# encoding: KOI8U
# This file is encoded in KOI8-U.
die "This file is not encoded in KOI8-U.\n" if q{‚ } ne "\x82\xa0";

use KOI8U;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('‚ -' =~ /(‚ [‚¢-])/) {
    if ("$1" eq "‚ -") {
        print "ok - 1 $^X $__FILE__ ('‚ -' =~ /‚ [‚¢-]/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('‚ -' =~ /‚ [‚¢-]/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('‚ -' =~ /‚ [‚¢-]/).\n";
}

__END__
