# encoding: Cyrillic
# This file is encoded in Cyrillic.
die "This file is not encoded in Cyrillic.\n" if q{ } ne "\x82\xa0";

use Cyrillic;
print "1..1\n";

my $__FILE__ = __FILE__;

if (' ЂЄ' =~ /( Ђ+ЂЄ)/) {
    print "not ok - 1 $^X $__FILE__ not (' ЂЄ' =~ / Ђ+ЂЄ/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not (' ЂЄ' =~ / Ђ+ЂЄ/).\n";
}

__END__
