# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{‚ } ne "\x82\xa0";

# ˆø”‚ªÈ—ª‚³‚ê‚½ê‡‚ÌƒeƒXƒg

my $__FILE__ = __FILE__;

use Ehp15;
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
if ((Ehp15::r_ ne '') == (-r ne '')) {
    print "ok - 1 Ehp15::r_ == -r  $^X $__FILE__\n";
}
else {
    print "not ok - 1 Ehp15::r_ == -r  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::w_ ne '') == (-w ne '')) {
    print "ok - 2 Ehp15::w_ == -w  $^X $__FILE__\n";
}
else {
    print "not ok - 2 Ehp15::w_ == -w  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::x_ ne '') == (-x ne '')) {
    print "ok - 3 Ehp15::x_ == -x  $^X $__FILE__\n";
}
else {
    print "not ok - 3 Ehp15::x_ == -x  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::o_ ne '') == (-o ne '')) {
    print "ok - 4 Ehp15::o_ == -o  $^X $__FILE__\n";
}
else {
    print "not ok - 4 Ehp15::o_ == -o  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::R_ ne '') == (-R ne '')) {
    print "ok - 5 Ehp15::R_ == -R  $^X $__FILE__\n";
}
else {
    print "not ok - 5 Ehp15::R_ == -R  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::W_ ne '') == (-W ne '')) {
    print "ok - 6 Ehp15::W_ == -W  $^X $__FILE__\n";
}
else {
    print "not ok - 6 Ehp15::W_ == -W  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::X_ ne '') == (-X ne '')) {
    print "ok - 7 Ehp15::X_ == -X  $^X $__FILE__\n";
}
else {
    print "not ok - 7 Ehp15::X_ == -X  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::O_ ne '') == (-O ne '')) {
    print "ok - 8 Ehp15::O_ == -O  $^X $__FILE__\n";
}
else {
    print "not ok - 8 Ehp15::O_ == -O  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::e_ ne '') == (-e ne '')) {
    print "ok - 9 Ehp15::e_ == -e  $^X $__FILE__\n";
}
else {
    print "not ok - 9 Ehp15::e_ == -e  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::z_ ne '') == (-z ne '')) {
    print "ok - 10 Ehp15::z_ == -z  $^X $__FILE__\n";
}
else {
    print "not ok - 10 Ehp15::z_ == -z  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::s_ ne '') == (-s ne '')) {
    print "ok - 11 Ehp15::s_ == -s  $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ehp15::s_ == -s  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::f_ ne '') == (-f ne '')) {
    print "ok - 12 Ehp15::f_ == -f  $^X $__FILE__\n";
}
else {
    print "not ok - 12 Ehp15::f_ == -f  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::d_ ne '') == (-d ne '')) {
    print "ok - 13 Ehp15::d_ == -d  $^X $__FILE__\n";
}
else {
    print "not ok - 13 Ehp15::d_ == -d  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::p_ ne '') == (-p ne '')) {
    print "ok - 14 Ehp15::p_ == -p  $^X $__FILE__\n";
}
else {
    print "not ok - 14 Ehp15::p_ == -p  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::S_ ne '') == (-S ne '')) {
    print "ok - 15 Ehp15::S_ == -S  $^X $__FILE__\n";
}
else {
    print "not ok - 15 Ehp15::S_ == -S  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::b_ ne '') == (-b ne '')) {
    print "ok - 16 Ehp15::b_ == -b  $^X $__FILE__\n";
}
else {
    print "not ok - 16 Ehp15::b_ == -b  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::c_ ne '') == (-c ne '')) {
    print "ok - 17 Ehp15::c_ == -c  $^X $__FILE__\n";
}
else {
    print "not ok - 17 Ehp15::c_ == -c  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::u_ ne '') == (-u ne '')) {
    print "ok - 18 Ehp15::u_ == -u  $^X $__FILE__\n";
}
else {
    print "not ok - 18 Ehp15::u_ == -u  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::g_ ne '') == (-g ne '')) {
    print "ok - 19 Ehp15::g_ == -g  $^X $__FILE__\n";
}
else {
    print "not ok - 19 Ehp15::g_ == -g  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::T_ ne '') == (-T ne '')) {
    print "ok - 20 Ehp15::T_ == -T  $^X $__FILE__\n";
}
else {
    print "not ok - 20 Ehp15::T_ == -T  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::B_ ne '') == (-B ne '')) {
    print "ok - 21 Ehp15::B_ == -B  $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ehp15::B_ == -B  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::M_ ne '') == (-M ne '')) {
    print "ok - 22 Ehp15::M_ == -M  $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ehp15::M_ == -M  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::A_ ne '') == (-A ne '')) {
    print "ok - 23 Ehp15::A_ == -A  $^X $__FILE__\n";
}
else {
    print "not ok - 23 Ehp15::A_ == -A  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ehp15::C_ ne '') == (-C ne '')) {
    print "ok - 24 Ehp15::C_ == -C  $^X $__FILE__\n";
}
else {
    print "not ok - 24 Ehp15::C_ == -C  $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
