# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あいえ' =~ /(あ[い-え]e)/) {
    print "not ok - 1 $^X $__FILE__ not ('あいえ' =~ /あ[い-え]e/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('あいえ' =~ /あ[い-え]e/).\n";
}

__END__
