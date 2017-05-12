# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

# 堷悢偑徣棯偝傟偨応崌偺僥僗僩

my $__FILE__ = __FILE__;

use Egbk;
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
if ((Egbk::r_ ne '') == (-r ne '')) {
    print "ok - 1 Egbk::r_ == -r  $^X $__FILE__\n";
}
else {
    print "not ok - 1 Egbk::r_ == -r  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::w_ ne '') == (-w ne '')) {
    print "ok - 2 Egbk::w_ == -w  $^X $__FILE__\n";
}
else {
    print "not ok - 2 Egbk::w_ == -w  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::x_ ne '') == (-x ne '')) {
    print "ok - 3 Egbk::x_ == -x  $^X $__FILE__\n";
}
else {
    print "not ok - 3 Egbk::x_ == -x  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::o_ ne '') == (-o ne '')) {
    print "ok - 4 Egbk::o_ == -o  $^X $__FILE__\n";
}
else {
    print "not ok - 4 Egbk::o_ == -o  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::R_ ne '') == (-R ne '')) {
    print "ok - 5 Egbk::R_ == -R  $^X $__FILE__\n";
}
else {
    print "not ok - 5 Egbk::R_ == -R  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::W_ ne '') == (-W ne '')) {
    print "ok - 6 Egbk::W_ == -W  $^X $__FILE__\n";
}
else {
    print "not ok - 6 Egbk::W_ == -W  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::X_ ne '') == (-X ne '')) {
    print "ok - 7 Egbk::X_ == -X  $^X $__FILE__\n";
}
else {
    print "not ok - 7 Egbk::X_ == -X  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::O_ ne '') == (-O ne '')) {
    print "ok - 8 Egbk::O_ == -O  $^X $__FILE__\n";
}
else {
    print "not ok - 8 Egbk::O_ == -O  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::e_ ne '') == (-e ne '')) {
    print "ok - 9 Egbk::e_ == -e  $^X $__FILE__\n";
}
else {
    print "not ok - 9 Egbk::e_ == -e  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::z_ ne '') == (-z ne '')) {
    print "ok - 10 Egbk::z_ == -z  $^X $__FILE__\n";
}
else {
    print "not ok - 10 Egbk::z_ == -z  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::s_ ne '') == (-s ne '')) {
    print "ok - 11 Egbk::s_ == -s  $^X $__FILE__\n";
}
else {
    print "not ok - 11 Egbk::s_ == -s  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::f_ ne '') == (-f ne '')) {
    print "ok - 12 Egbk::f_ == -f  $^X $__FILE__\n";
}
else {
    print "not ok - 12 Egbk::f_ == -f  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::d_ ne '') == (-d ne '')) {
    print "ok - 13 Egbk::d_ == -d  $^X $__FILE__\n";
}
else {
    print "not ok - 13 Egbk::d_ == -d  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::p_ ne '') == (-p ne '')) {
    print "ok - 14 Egbk::p_ == -p  $^X $__FILE__\n";
}
else {
    print "not ok - 14 Egbk::p_ == -p  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::S_ ne '') == (-S ne '')) {
    print "ok - 15 Egbk::S_ == -S  $^X $__FILE__\n";
}
else {
    print "not ok - 15 Egbk::S_ == -S  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::b_ ne '') == (-b ne '')) {
    print "ok - 16 Egbk::b_ == -b  $^X $__FILE__\n";
}
else {
    print "not ok - 16 Egbk::b_ == -b  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::c_ ne '') == (-c ne '')) {
    print "ok - 17 Egbk::c_ == -c  $^X $__FILE__\n";
}
else {
    print "not ok - 17 Egbk::c_ == -c  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::u_ ne '') == (-u ne '')) {
    print "ok - 18 Egbk::u_ == -u  $^X $__FILE__\n";
}
else {
    print "not ok - 18 Egbk::u_ == -u  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::g_ ne '') == (-g ne '')) {
    print "ok - 19 Egbk::g_ == -g  $^X $__FILE__\n";
}
else {
    print "not ok - 19 Egbk::g_ == -g  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::T_ ne '') == (-T ne '')) {
    print "ok - 20 Egbk::T_ == -T  $^X $__FILE__\n";
}
else {
    print "not ok - 20 Egbk::T_ == -T  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::B_ ne '') == (-B ne '')) {
    print "ok - 21 Egbk::B_ == -B  $^X $__FILE__\n";
}
else {
    print "not ok - 21 Egbk::B_ == -B  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::M_ ne '') == (-M ne '')) {
    print "ok - 22 Egbk::M_ == -M  $^X $__FILE__\n";
}
else {
    print "not ok - 22 Egbk::M_ == -M  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::A_ ne '') == (-A ne '')) {
    print "ok - 23 Egbk::A_ == -A  $^X $__FILE__\n";
}
else {
    print "not ok - 23 Egbk::A_ == -A  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egbk::C_ ne '') == (-C ne '')) {
    print "ok - 24 Egbk::C_ == -C  $^X $__FILE__\n";
}
else {
    print "not ok - 24 Egbk::C_ == -C  $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
