# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use Sjis;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あうe' =~ /(あ[い-え]e)/) {
    if ("$1" eq "あうe") {
        print "ok - 1 $^X $__FILE__ ('あうe' =~ /あ[い-え]e/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('あうe' =~ /あ[い-え]e/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('あうe' =~ /あ[い-え]e/).\n";
}

__END__
