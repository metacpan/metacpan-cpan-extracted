# encoding: Windows1258
# This file is encoded in Windows-1258.
die "This file is not encoded in Windows-1258.\n" if q{‚ } ne "\x82\xa0";

use Windows1258;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('‚¦ef' =~ /(()ef)/) {
    if ("$1-$2" eq "ef-") {
        print "ok - 1 $^X $__FILE__ ('‚¦ef' =~ /()ef/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('‚¦ef' =~ /()ef/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('‚¦ef' =~ /()ef/).\n";
}

__END__
