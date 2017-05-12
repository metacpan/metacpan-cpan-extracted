# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{あ} ne "\xa4\xa2";

use EUCTW;
print "1..1\n";

my $__FILE__ = __FILE__;

eval q< '-' =~ /((*)い)/ >;
if ($@) {
    print "ok - 1 $^X $__FILE__ die ('-' =~ /(*)い/).\n";
}
else {
    print "not ok - 1 $^X $__FILE__ die ('-' =~ /(*)い/).\n";
}

__END__
