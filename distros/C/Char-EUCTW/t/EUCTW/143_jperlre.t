# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{あ} ne "\xa4\xa2";

use EUCTW;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あいえ' =~ /(あ[いう]え)/) {
    if ("$1" eq "あいえ") {
        print "ok - 1 $^X $__FILE__ ('あいえ' =~ /あ[いう]え/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('あいえ' =~ /あ[いう]え/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('あいえ' =~ /あ[いう]え/).\n";
}

__END__
