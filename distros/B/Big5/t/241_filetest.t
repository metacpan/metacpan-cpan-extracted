# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{‚ } ne "\x82\xa0";

# ˆø”‚ªÈ—ª‚³‚ê‚½ê‡‚ÌƒeƒXƒg

my $__FILE__ = __FILE__;

use Ebig5;
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
if ((Ebig5::r_ ne '') == (-r ne '')) {
    print "ok - 1 Ebig5::r_ == -r  $^X $__FILE__\n";
}
else {
    print "not ok - 1 Ebig5::r_ == -r  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::w_ ne '') == (-w ne '')) {
    print "ok - 2 Ebig5::w_ == -w  $^X $__FILE__\n";
}
else {
    print "not ok - 2 Ebig5::w_ == -w  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::x_ ne '') == (-x ne '')) {
    print "ok - 3 Ebig5::x_ == -x  $^X $__FILE__\n";
}
else {
    print "not ok - 3 Ebig5::x_ == -x  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::o_ ne '') == (-o ne '')) {
    print "ok - 4 Ebig5::o_ == -o  $^X $__FILE__\n";
}
else {
    print "not ok - 4 Ebig5::o_ == -o  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::R_ ne '') == (-R ne '')) {
    print "ok - 5 Ebig5::R_ == -R  $^X $__FILE__\n";
}
else {
    print "not ok - 5 Ebig5::R_ == -R  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::W_ ne '') == (-W ne '')) {
    print "ok - 6 Ebig5::W_ == -W  $^X $__FILE__\n";
}
else {
    print "not ok - 6 Ebig5::W_ == -W  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::X_ ne '') == (-X ne '')) {
    print "ok - 7 Ebig5::X_ == -X  $^X $__FILE__\n";
}
else {
    print "not ok - 7 Ebig5::X_ == -X  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::O_ ne '') == (-O ne '')) {
    print "ok - 8 Ebig5::O_ == -O  $^X $__FILE__\n";
}
else {
    print "not ok - 8 Ebig5::O_ == -O  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::e_ ne '') == (-e ne '')) {
    print "ok - 9 Ebig5::e_ == -e  $^X $__FILE__\n";
}
else {
    print "not ok - 9 Ebig5::e_ == -e  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::z_ ne '') == (-z ne '')) {
    print "ok - 10 Ebig5::z_ == -z  $^X $__FILE__\n";
}
else {
    print "not ok - 10 Ebig5::z_ == -z  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::s_ ne '') == (-s ne '')) {
    print "ok - 11 Ebig5::s_ == -s  $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ebig5::s_ == -s  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::f_ ne '') == (-f ne '')) {
    print "ok - 12 Ebig5::f_ == -f  $^X $__FILE__\n";
}
else {
    print "not ok - 12 Ebig5::f_ == -f  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::d_ ne '') == (-d ne '')) {
    print "ok - 13 Ebig5::d_ == -d  $^X $__FILE__\n";
}
else {
    print "not ok - 13 Ebig5::d_ == -d  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::p_ ne '') == (-p ne '')) {
    print "ok - 14 Ebig5::p_ == -p  $^X $__FILE__\n";
}
else {
    print "not ok - 14 Ebig5::p_ == -p  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::S_ ne '') == (-S ne '')) {
    print "ok - 15 Ebig5::S_ == -S  $^X $__FILE__\n";
}
else {
    print "not ok - 15 Ebig5::S_ == -S  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::b_ ne '') == (-b ne '')) {
    print "ok - 16 Ebig5::b_ == -b  $^X $__FILE__\n";
}
else {
    print "not ok - 16 Ebig5::b_ == -b  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::c_ ne '') == (-c ne '')) {
    print "ok - 17 Ebig5::c_ == -c  $^X $__FILE__\n";
}
else {
    print "not ok - 17 Ebig5::c_ == -c  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::u_ ne '') == (-u ne '')) {
    print "ok - 18 Ebig5::u_ == -u  $^X $__FILE__\n";
}
else {
    print "not ok - 18 Ebig5::u_ == -u  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::g_ ne '') == (-g ne '')) {
    print "ok - 19 Ebig5::g_ == -g  $^X $__FILE__\n";
}
else {
    print "not ok - 19 Ebig5::g_ == -g  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::T_ ne '') == (-T ne '')) {
    print "ok - 20 Ebig5::T_ == -T  $^X $__FILE__\n";
}
else {
    print "not ok - 20 Ebig5::T_ == -T  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::B_ ne '') == (-B ne '')) {
    print "ok - 21 Ebig5::B_ == -B  $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ebig5::B_ == -B  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::M_ ne '') == (-M ne '')) {
    print "ok - 22 Ebig5::M_ == -M  $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ebig5::M_ == -M  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::A_ ne '') == (-A ne '')) {
    print "ok - 23 Ebig5::A_ == -A  $^X $__FILE__\n";
}
else {
    print "not ok - 23 Ebig5::A_ == -A  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5::C_ ne '') == (-C ne '')) {
    print "ok - 24 Ebig5::C_ == -C  $^X $__FILE__\n";
}
else {
    print "not ok - 24 Ebig5::C_ == -C  $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
