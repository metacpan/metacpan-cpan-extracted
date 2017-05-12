# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{‚ } ne "\x82\xa0";

# ˆø”‚ªÈ—ª‚³‚ê‚½ê‡‚ÌƒeƒXƒg

my $__FILE__ = __FILE__;

use Einformixv6als;
print "1..24\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..24) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);

open(FILE,'file');

$_ = 'file';
if ((Einformixv6als::r_ ne '') == (-r ne '')) {
    print "ok - 1 Einformixv6als::r_ == -r  $^X $__FILE__\n";
}
else {
    print "not ok - 1 Einformixv6als::r_ == -r  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::w_ ne '') == (-w ne '')) {
    print "ok - 2 Einformixv6als::w_ == -w  $^X $__FILE__\n";
}
else {
    print "not ok - 2 Einformixv6als::w_ == -w  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::x_ ne '') == (-x ne '')) {
    print "ok - 3 Einformixv6als::x_ == -x  $^X $__FILE__\n";
}
else {
    print "not ok - 3 Einformixv6als::x_ == -x  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::o_ ne '') == (-o ne '')) {
    print "ok - 4 Einformixv6als::o_ == -o  $^X $__FILE__\n";
}
else {
    print "not ok - 4 Einformixv6als::o_ == -o  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::R_ ne '') == (-R ne '')) {
    print "ok - 5 Einformixv6als::R_ == -R  $^X $__FILE__\n";
}
else {
    print "not ok - 5 Einformixv6als::R_ == -R  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::W_ ne '') == (-W ne '')) {
    print "ok - 6 Einformixv6als::W_ == -W  $^X $__FILE__\n";
}
else {
    print "not ok - 6 Einformixv6als::W_ == -W  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::X_ ne '') == (-X ne '')) {
    print "ok - 7 Einformixv6als::X_ == -X  $^X $__FILE__\n";
}
else {
    print "not ok - 7 Einformixv6als::X_ == -X  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::O_ ne '') == (-O ne '')) {
    print "ok - 8 Einformixv6als::O_ == -O  $^X $__FILE__\n";
}
else {
    print "not ok - 8 Einformixv6als::O_ == -O  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::e_ ne '') == (-e ne '')) {
    print "ok - 9 Einformixv6als::e_ == -e  $^X $__FILE__\n";
}
else {
    print "not ok - 9 Einformixv6als::e_ == -e  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::z_ ne '') == (-z ne '')) {
    print "ok - 10 Einformixv6als::z_ == -z  $^X $__FILE__\n";
}
else {
    print "not ok - 10 Einformixv6als::z_ == -z  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::s_ ne '') == (-s ne '')) {
    print "ok - 11 Einformixv6als::s_ == -s  $^X $__FILE__\n";
}
else {
    print "not ok - 11 Einformixv6als::s_ == -s  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::f_ ne '') == (-f ne '')) {
    print "ok - 12 Einformixv6als::f_ == -f  $^X $__FILE__\n";
}
else {
    print "not ok - 12 Einformixv6als::f_ == -f  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::d_ ne '') == (-d ne '')) {
    print "ok - 13 Einformixv6als::d_ == -d  $^X $__FILE__\n";
}
else {
    print "not ok - 13 Einformixv6als::d_ == -d  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::p_ ne '') == (-p ne '')) {
    print "ok - 14 Einformixv6als::p_ == -p  $^X $__FILE__\n";
}
else {
    print "not ok - 14 Einformixv6als::p_ == -p  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::S_ ne '') == (-S ne '')) {
    print "ok - 15 Einformixv6als::S_ == -S  $^X $__FILE__\n";
}
else {
    print "not ok - 15 Einformixv6als::S_ == -S  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::b_ ne '') == (-b ne '')) {
    print "ok - 16 Einformixv6als::b_ == -b  $^X $__FILE__\n";
}
else {
    print "not ok - 16 Einformixv6als::b_ == -b  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::c_ ne '') == (-c ne '')) {
    print "ok - 17 Einformixv6als::c_ == -c  $^X $__FILE__\n";
}
else {
    print "not ok - 17 Einformixv6als::c_ == -c  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::u_ ne '') == (-u ne '')) {
    print "ok - 18 Einformixv6als::u_ == -u  $^X $__FILE__\n";
}
else {
    print "not ok - 18 Einformixv6als::u_ == -u  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::g_ ne '') == (-g ne '')) {
    print "ok - 19 Einformixv6als::g_ == -g  $^X $__FILE__\n";
}
else {
    print "not ok - 19 Einformixv6als::g_ == -g  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::T_ ne '') == (-T ne '')) {
    print "ok - 20 Einformixv6als::T_ == -T  $^X $__FILE__\n";
}
else {
    print "not ok - 20 Einformixv6als::T_ == -T  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::B_ ne '') == (-B ne '')) {
    print "ok - 21 Einformixv6als::B_ == -B  $^X $__FILE__\n";
}
else {
    print "not ok - 21 Einformixv6als::B_ == -B  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::M_ ne '') == (-M ne '')) {
    print "ok - 22 Einformixv6als::M_ == -M  $^X $__FILE__\n";
}
else {
    print "not ok - 22 Einformixv6als::M_ == -M  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::A_ ne '') == (-A ne '')) {
    print "ok - 23 Einformixv6als::A_ == -A  $^X $__FILE__\n";
}
else {
    print "not ok - 23 Einformixv6als::A_ == -A  $^X $__FILE__\n";
}

$_ = 'file';
if ((Einformixv6als::C_ ne '') == (-C ne '')) {
    print "ok - 24 Einformixv6als::C_ == -C  $^X $__FILE__\n";
}
else {
    print "not ok - 24 Einformixv6als::C_ == -C  $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
