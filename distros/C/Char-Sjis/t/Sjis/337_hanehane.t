# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{ } ne "\x82\xa0";

use Sjis;
print "1..1\n";

my $__FILE__ = __FILE__;

# [96 FB] [92 4A]
$_ = "ϋJ";

# [FB 92] [89 48]
if ($_ =~ s/ϋ/H/g) {
    print qq{not ok - 1 \$_ !~ s/ϋ/H/ --> ($_) $^X $__FILE__\n};
}
else {
    if ($_ eq "ϋJ") {
        print qq{ok - 1 \$_ !~ s/ϋ/H/ --> ($_) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$_ !~ s/ϋ/H/ --> ($_) $^X $__FILE__\n};
    }
}

__END__

kog*2*20 ³ρ

perlΕsjisΜΆu·BΌpASpΜ1oCgΪ2oCgΪΙImΙ³K\»πqbg³Ήιp
http://blogs.yahoo.co.jp/koga2020/40579992.html

ζθ
