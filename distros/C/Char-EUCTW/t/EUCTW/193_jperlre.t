# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{дв} ne "\xa4\xa2";

use EUCTW;
print "1..1\n";

my $__FILE__ = __FILE__;

eval q!'AAA' =~ /[]/!;
if ($@) {
    print "ok - 1 $^X $__FILE__ (!'AAA' =~ /[]/!)\n";
}
else {
    print "not ok - 1 $^X $__FILE__ (!'AAA' =~ /[]/!)\n";
}

__END__
