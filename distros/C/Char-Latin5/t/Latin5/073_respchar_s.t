# encoding: Latin5
# This file is encoded in Latin-5.
die "This file is not encoded in Latin-5.\n" if q{‚ } ne "\x82\xa0";

use Latin5;
print "1..1\n";

my $__FILE__ = __FILE__;

$a = "ƒAƒ\ƒA";
if ($a !~ s/(ƒAƒC|ƒCƒE)//) {
    print qq{ok - 1 "ƒAƒ\ƒA" !~ s/(ƒAƒC|ƒCƒE)// \$1=() $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "ƒAƒ\ƒA" !~ s/(ƒAƒC|ƒCƒE)// \$1=($1) $^X $__FILE__\n};
}

__END__
