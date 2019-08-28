# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{あ} ne "\x82\xa0";

use Big5;
print "1..1\n";

my $__FILE__ = __FILE__;

$a = "アソソ";
if ($a !~ s/(イソ*)//) {
    print qq{ok - 1 "アソソ" !~ s/(イソ*)// \$1=() $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "アソソ" !~ s/(イソ*)// \$1=($1) $^X $__FILE__\n};
}

__END__
