# encoding: Windows1258
# This file is encoded in Windows-1258.
die "This file is not encoded in Windows-1258.\n" if q{‚ } ne "\x82\xa0";

use Windows1258;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('‚ ‚¢‚¤' =~ /()$/) {
    if ("$1" eq "") {
        print "ok - 1 $^X $__FILE__ ('‚ ‚¢‚¤' =~ /\$/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('‚ ‚¢‚¤' =~ /\$/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('‚ ‚¢‚¤' =~ /\$/).\n";
}

__END__
