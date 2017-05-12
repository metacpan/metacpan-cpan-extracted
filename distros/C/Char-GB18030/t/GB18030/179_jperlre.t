# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..1\n";

my $__FILE__ = __FILE__;

eval q< '-' =~ /(*偁)/ >;
if ($@) {
    print "ok - 1 $^X $__FILE__ die ('-' =~ /*偁/).\n";
}
else {
    print "not ok - 1 $^X $__FILE__ die ('-' =~ /*偁/).\n";
}

__END__
