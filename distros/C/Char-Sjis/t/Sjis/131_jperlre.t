# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use Sjis;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あいうう' =~ /^(あいう)$/) {
    print "not ok - 1 $^X $__FILE__ not ('あいうう' =~ /^あいう\$/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('あいうう' =~ /^あいう\$/).\n";
}

__END__
