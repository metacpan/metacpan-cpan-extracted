# encoding: TIS620
# This file is encoded in TIS-620.
die "This file is not encoded in TIS-620.\n" if q{ } ne "\x82\xa0";

use TIS620;
print "1..1\n";

my $__FILE__ = __FILE__;

if (' ขขขขค' =~ /( ข{4,5}ขค)/) {
    print "not ok - 1 $^X $__FILE__ not (' ขขขขค' =~ / ข{4,5}ขค/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not (' ขขขขค' =~ / ข{4,5}ขค/).\n";
}

__END__
