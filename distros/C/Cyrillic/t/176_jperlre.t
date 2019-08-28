# encoding: Cyrillic
# This file is encoded in Cyrillic.
die "This file is not encoded in Cyrillic.\n" if q{ } ne "\x82\xa0";

use Cyrillic;
print "1..1\n";

my $__FILE__ = __FILE__;

if (' ЂЄ' =~ /( Ђ|ЄІ)/) {
    if ("$1" eq " Ђ") {
        print "ok - 1 $^X $__FILE__ (' ЂЄ' =~ / Ђ|ЄІ/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ (' ЂЄ' =~ / Ђ|ЄІ/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ (' ЂЄ' =~ / Ђ|ЄІ/).\n";
}

__END__
