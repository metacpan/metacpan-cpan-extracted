# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

use INFORMIXV6ALS;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('ああいう' =~ /^(あいう)$/) {
    print "not ok - 1 $^X $__FILE__ not ('ああいう' =~ /^あいう\$/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('ああいう' =~ /^あいう\$/).\n";
}

__END__
