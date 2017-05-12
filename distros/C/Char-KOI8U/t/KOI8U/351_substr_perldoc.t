# encoding: KOI8U
# This file is encoded in KOI8-U.
die "This file is not encoded in KOI8-U.\n" if q{‚ } ne "\x82\xa0";

use KOI8U;
print "1..5\n";

my $__FILE__ = __FILE__;

my $s = "The black cat climbed the green tree";
my $color  = KOI8U::substr $s, 4, 5;   # black
my $middle = KOI8U::substr $s, 4, -11; # black cat climbed the
my $end    = KOI8U::substr $s, 14;     # climebed the green tree
my $tail   = KOI8U::substr $s, -4;     # tree
my $z      = KOI8U::substr $s, -4, 2;  # tr

if ($color eq 'black') {
    print "ok - 1 $^X $__FILE__\n";
}
else {
    print "not ok - 1 $^X $__FILE__\n";
}

if ($middle eq 'black cat climbed the') {
    print "ok - 2 $^X $__FILE__\n";
}
else {
    print "not ok - 2 $^X $__FILE__\n";
}

if ($end eq 'climbed the green tree') {
    print "ok - 3 $^X $__FILE__\n";
}
else {
    print "not ok - 3 $^X $__FILE__\n";
}

if ($tail eq 'tree') {
    print "ok - 4 $^X $__FILE__\n";
}
else {
    print "not ok - 4 $^X $__FILE__\n";
}

if ($z eq 'tr') {
    print "ok - 5 $^X $__FILE__\n";
}
else {
    print "not ok - 5 $^X $__FILE__\n";
}

__END__
http://perldoc.perl.org/functions/substr.html

1.    my $s = "The black cat climbed the green tree";
2.    my $color  = substr $s, 4, 5;      # black
3.    my $middle = substr $s, 4, -11;    # black cat climbed the
4.    my $end    = substr $s, 14;        # climbed the green tree
5.    my $tail   = substr $s, -4;        # tree
6.    my $z      = substr $s, -4, 2;     # tr
