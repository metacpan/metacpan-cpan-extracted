# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{‚ } ne "\x82\xa0";

# ˆø”‚ªÈ—ª‚³‚ê‚½ê‡‚ÌƒeƒXƒg

my $__FILE__ = __FILE__;

use Ebig5hkscs;
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
if ((Ebig5hkscs::r_ ne '') == (-r ne '')) {
    print "ok - 1 Ebig5hkscs::r_ == -r  $^X $__FILE__\n";
}
else {
    print "not ok - 1 Ebig5hkscs::r_ == -r  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::w_ ne '') == (-w ne '')) {
    print "ok - 2 Ebig5hkscs::w_ == -w  $^X $__FILE__\n";
}
else {
    print "not ok - 2 Ebig5hkscs::w_ == -w  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::x_ ne '') == (-x ne '')) {
    print "ok - 3 Ebig5hkscs::x_ == -x  $^X $__FILE__\n";
}
else {
    print "not ok - 3 Ebig5hkscs::x_ == -x  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::o_ ne '') == (-o ne '')) {
    print "ok - 4 Ebig5hkscs::o_ == -o  $^X $__FILE__\n";
}
else {
    print "not ok - 4 Ebig5hkscs::o_ == -o  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::R_ ne '') == (-R ne '')) {
    print "ok - 5 Ebig5hkscs::R_ == -R  $^X $__FILE__\n";
}
else {
    print "not ok - 5 Ebig5hkscs::R_ == -R  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::W_ ne '') == (-W ne '')) {
    print "ok - 6 Ebig5hkscs::W_ == -W  $^X $__FILE__\n";
}
else {
    print "not ok - 6 Ebig5hkscs::W_ == -W  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::X_ ne '') == (-X ne '')) {
    print "ok - 7 Ebig5hkscs::X_ == -X  $^X $__FILE__\n";
}
else {
    print "not ok - 7 Ebig5hkscs::X_ == -X  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::O_ ne '') == (-O ne '')) {
    print "ok - 8 Ebig5hkscs::O_ == -O  $^X $__FILE__\n";
}
else {
    print "not ok - 8 Ebig5hkscs::O_ == -O  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::e_ ne '') == (-e ne '')) {
    print "ok - 9 Ebig5hkscs::e_ == -e  $^X $__FILE__\n";
}
else {
    print "not ok - 9 Ebig5hkscs::e_ == -e  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::z_ ne '') == (-z ne '')) {
    print "ok - 10 Ebig5hkscs::z_ == -z  $^X $__FILE__\n";
}
else {
    print "not ok - 10 Ebig5hkscs::z_ == -z  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::s_ ne '') == (-s ne '')) {
    print "ok - 11 Ebig5hkscs::s_ == -s  $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ebig5hkscs::s_ == -s  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::f_ ne '') == (-f ne '')) {
    print "ok - 12 Ebig5hkscs::f_ == -f  $^X $__FILE__\n";
}
else {
    print "not ok - 12 Ebig5hkscs::f_ == -f  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::d_ ne '') == (-d ne '')) {
    print "ok - 13 Ebig5hkscs::d_ == -d  $^X $__FILE__\n";
}
else {
    print "not ok - 13 Ebig5hkscs::d_ == -d  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::p_ ne '') == (-p ne '')) {
    print "ok - 14 Ebig5hkscs::p_ == -p  $^X $__FILE__\n";
}
else {
    print "not ok - 14 Ebig5hkscs::p_ == -p  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::S_ ne '') == (-S ne '')) {
    print "ok - 15 Ebig5hkscs::S_ == -S  $^X $__FILE__\n";
}
else {
    print "not ok - 15 Ebig5hkscs::S_ == -S  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::b_ ne '') == (-b ne '')) {
    print "ok - 16 Ebig5hkscs::b_ == -b  $^X $__FILE__\n";
}
else {
    print "not ok - 16 Ebig5hkscs::b_ == -b  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::c_ ne '') == (-c ne '')) {
    print "ok - 17 Ebig5hkscs::c_ == -c  $^X $__FILE__\n";
}
else {
    print "not ok - 17 Ebig5hkscs::c_ == -c  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::u_ ne '') == (-u ne '')) {
    print "ok - 18 Ebig5hkscs::u_ == -u  $^X $__FILE__\n";
}
else {
    print "not ok - 18 Ebig5hkscs::u_ == -u  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::g_ ne '') == (-g ne '')) {
    print "ok - 19 Ebig5hkscs::g_ == -g  $^X $__FILE__\n";
}
else {
    print "not ok - 19 Ebig5hkscs::g_ == -g  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::T_ ne '') == (-T ne '')) {
    print "ok - 20 Ebig5hkscs::T_ == -T  $^X $__FILE__\n";
}
else {
    print "not ok - 20 Ebig5hkscs::T_ == -T  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::B_ ne '') == (-B ne '')) {
    print "ok - 21 Ebig5hkscs::B_ == -B  $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ebig5hkscs::B_ == -B  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::M_ ne '') == (-M ne '')) {
    print "ok - 22 Ebig5hkscs::M_ == -M  $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ebig5hkscs::M_ == -M  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::A_ ne '') == (-A ne '')) {
    print "ok - 23 Ebig5hkscs::A_ == -A  $^X $__FILE__\n";
}
else {
    print "not ok - 23 Ebig5hkscs::A_ == -A  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5hkscs::C_ ne '') == (-C ne '')) {
    print "ok - 24 Ebig5hkscs::C_ == -C  $^X $__FILE__\n";
}
else {
    print "not ok - 24 Ebig5hkscs::C_ == -C  $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
