# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{дв} ne "\xa4\xa2";

use EUCTW;
print "1..2\n";

my $__FILE__ = __FILE__;

my $s = "The black cat climbed the green tree";
my $z = EUCTW::substr $s, 14, 7, "jumped from"; # climbed

if ($z eq 'climbed') {
    print "ok - 1 $^X $__FILE__\n";
}
else {
    print "not ok - 1 $^X $__FILE__\n";
}

if ($s eq 'The black cat jumped from the green tree') {
    print "ok - 2 $^X $__FILE__\n";
}
else {
    print "not ok - 2 $^X $__FILE__\n";
}

__END__
http://perldoc.perl.org/functions/substr.html

1.    my $s = "The black cat climbed the green tree";
2.    my $z = substr $s, 14, 7, "jumped from";    # climbed
3.    # $s is now "The black cat jumped from the green tree"
