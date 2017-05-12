# encoding: Latin9
# This file is encoded in Latin-9.
die "This file is not encoded in Latin-9.\n" if q{ } ne "\x82\xa0";

use Latin9;
print "1..1\n";

my $__FILE__ = __FILE__;

$a = "A\A";
if ($a !~ s/\$//) {
    print qq{ok - 1 "A\A" !~ s/\\$// $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "A\A" !~ s/\\$// $^X $__FILE__\n};
}

__END__
