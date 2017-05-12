# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{あ} ne "\x82\xa0";

use KPS9566;
print "1..1\n";

my $__FILE__ = __FILE__;

$a = "アアソ";
if ($a =~ s/ソ$//) {
    print qq{ok - 1 "アアソ" =~ s/ソ\$// $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "アアソ" =~ s/ソ\$// $^X $__FILE__\n};
}

__END__
