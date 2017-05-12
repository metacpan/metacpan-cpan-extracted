# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{あ} ne "\x82\xa0";

use KPS9566;
print "1..1\n";

my $__FILE__ = __FILE__;

$a = "アソソ";
if ($a =~ s/(ア.)//) {
    if ($1 eq "アソ") {
        print qq{ok - 1 "アソソ" =~ s/(ア.)// \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 "アソソ" =~ s/(ア.)// \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 "アソソ" =~ s/(ア.)// \$1=($1) $^X $__FILE__\n};
}

__END__
