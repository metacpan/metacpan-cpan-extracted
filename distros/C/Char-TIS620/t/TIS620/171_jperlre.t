# encoding: TIS620
# This file is encoded in TIS-620.
die "This file is not encoded in TIS-620.\n" if q{ } ne "\x82\xa0";

use TIS620;
print "1..1\n";

my $__FILE__ = __FILE__;

if (' -ข' =~ /( [\S]ข)/) {
    if ("-" eq "-") {
        print "ok - 1 $^X $__FILE__ (' -ข' =~ / [\\S]ข/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ (' -ข' =~ / [\\S]ข/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ (' -ข' =~ / [\\S]ข/).\n";
}

__END__
