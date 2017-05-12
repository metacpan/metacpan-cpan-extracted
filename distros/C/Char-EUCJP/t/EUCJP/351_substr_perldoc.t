# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;
print "1..5\n";

my $__FILE__ = __FILE__;

my $s = "The black cat climbed the green tree";
my $color  = EUCJP::substr $s, 4, 5;   # black
my $middle = EUCJP::substr $s, 4, -11; # black cat climbed the
my $end    = EUCJP::substr $s, 14;     # climebed the green tree
my $tail   = EUCJP::substr $s, -4;     # tree
my $z      = EUCJP::substr $s, -4, 2;  # tr

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
