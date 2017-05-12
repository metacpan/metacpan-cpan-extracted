# encoding: Big5Plus
# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{‚ } ne "\x82\xa0";

# ˆø”‚ªÈ—ª‚³‚ê‚½ê‡‚ÌƒeƒXƒg

my $__FILE__ = __FILE__;

use Ebig5plus;
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
if ((Ebig5plus::r_ ne '') == (-r ne '')) {
    print "ok - 1 Ebig5plus::r_ == -r  $^X $__FILE__\n";
}
else {
    print "not ok - 1 Ebig5plus::r_ == -r  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::w_ ne '') == (-w ne '')) {
    print "ok - 2 Ebig5plus::w_ == -w  $^X $__FILE__\n";
}
else {
    print "not ok - 2 Ebig5plus::w_ == -w  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::x_ ne '') == (-x ne '')) {
    print "ok - 3 Ebig5plus::x_ == -x  $^X $__FILE__\n";
}
else {
    print "not ok - 3 Ebig5plus::x_ == -x  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::o_ ne '') == (-o ne '')) {
    print "ok - 4 Ebig5plus::o_ == -o  $^X $__FILE__\n";
}
else {
    print "not ok - 4 Ebig5plus::o_ == -o  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::R_ ne '') == (-R ne '')) {
    print "ok - 5 Ebig5plus::R_ == -R  $^X $__FILE__\n";
}
else {
    print "not ok - 5 Ebig5plus::R_ == -R  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::W_ ne '') == (-W ne '')) {
    print "ok - 6 Ebig5plus::W_ == -W  $^X $__FILE__\n";
}
else {
    print "not ok - 6 Ebig5plus::W_ == -W  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::X_ ne '') == (-X ne '')) {
    print "ok - 7 Ebig5plus::X_ == -X  $^X $__FILE__\n";
}
else {
    print "not ok - 7 Ebig5plus::X_ == -X  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::O_ ne '') == (-O ne '')) {
    print "ok - 8 Ebig5plus::O_ == -O  $^X $__FILE__\n";
}
else {
    print "not ok - 8 Ebig5plus::O_ == -O  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::e_ ne '') == (-e ne '')) {
    print "ok - 9 Ebig5plus::e_ == -e  $^X $__FILE__\n";
}
else {
    print "not ok - 9 Ebig5plus::e_ == -e  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::z_ ne '') == (-z ne '')) {
    print "ok - 10 Ebig5plus::z_ == -z  $^X $__FILE__\n";
}
else {
    print "not ok - 10 Ebig5plus::z_ == -z  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::s_ ne '') == (-s ne '')) {
    print "ok - 11 Ebig5plus::s_ == -s  $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ebig5plus::s_ == -s  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::f_ ne '') == (-f ne '')) {
    print "ok - 12 Ebig5plus::f_ == -f  $^X $__FILE__\n";
}
else {
    print "not ok - 12 Ebig5plus::f_ == -f  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::d_ ne '') == (-d ne '')) {
    print "ok - 13 Ebig5plus::d_ == -d  $^X $__FILE__\n";
}
else {
    print "not ok - 13 Ebig5plus::d_ == -d  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::p_ ne '') == (-p ne '')) {
    print "ok - 14 Ebig5plus::p_ == -p  $^X $__FILE__\n";
}
else {
    print "not ok - 14 Ebig5plus::p_ == -p  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::S_ ne '') == (-S ne '')) {
    print "ok - 15 Ebig5plus::S_ == -S  $^X $__FILE__\n";
}
else {
    print "not ok - 15 Ebig5plus::S_ == -S  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::b_ ne '') == (-b ne '')) {
    print "ok - 16 Ebig5plus::b_ == -b  $^X $__FILE__\n";
}
else {
    print "not ok - 16 Ebig5plus::b_ == -b  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::c_ ne '') == (-c ne '')) {
    print "ok - 17 Ebig5plus::c_ == -c  $^X $__FILE__\n";
}
else {
    print "not ok - 17 Ebig5plus::c_ == -c  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::u_ ne '') == (-u ne '')) {
    print "ok - 18 Ebig5plus::u_ == -u  $^X $__FILE__\n";
}
else {
    print "not ok - 18 Ebig5plus::u_ == -u  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::g_ ne '') == (-g ne '')) {
    print "ok - 19 Ebig5plus::g_ == -g  $^X $__FILE__\n";
}
else {
    print "not ok - 19 Ebig5plus::g_ == -g  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::T_ ne '') == (-T ne '')) {
    print "ok - 20 Ebig5plus::T_ == -T  $^X $__FILE__\n";
}
else {
    print "not ok - 20 Ebig5plus::T_ == -T  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::B_ ne '') == (-B ne '')) {
    print "ok - 21 Ebig5plus::B_ == -B  $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ebig5plus::B_ == -B  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::M_ ne '') == (-M ne '')) {
    print "ok - 22 Ebig5plus::M_ == -M  $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ebig5plus::M_ == -M  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::A_ ne '') == (-A ne '')) {
    print "ok - 23 Ebig5plus::A_ == -A  $^X $__FILE__\n";
}
else {
    print "not ok - 23 Ebig5plus::A_ == -A  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ebig5plus::C_ ne '') == (-C ne '')) {
    print "ok - 24 Ebig5plus::C_ == -C  $^X $__FILE__\n";
}
else {
    print "not ok - 24 Ebig5plus::C_ == -C  $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
