# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

use UHC;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('궇궋궋궋궋궎' =~ /(.{1})/) {
    if ("$1" eq "궇") {
        print "ok - 1 $^X $__FILE__ ('궇궋궋궋궋궎' =~ /.{1}/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('궇궋궋궋궋궎' =~ /.{1}/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('궇궋궋궋궋궎' =~ /.{1}/).\n";
}

__END__
