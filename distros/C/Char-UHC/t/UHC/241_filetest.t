# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

# 덙릶궕뤙뿪궠귢궫뤾뜃궻긡긚긣

my $__FILE__ = __FILE__;

use Euhc;
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
if ((Euhc::r_ ne '') == (-r ne '')) {
    print "ok - 1 Euhc::r_ == -r  $^X $__FILE__\n";
}
else {
    print "not ok - 1 Euhc::r_ == -r  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::w_ ne '') == (-w ne '')) {
    print "ok - 2 Euhc::w_ == -w  $^X $__FILE__\n";
}
else {
    print "not ok - 2 Euhc::w_ == -w  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::x_ ne '') == (-x ne '')) {
    print "ok - 3 Euhc::x_ == -x  $^X $__FILE__\n";
}
else {
    print "not ok - 3 Euhc::x_ == -x  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::o_ ne '') == (-o ne '')) {
    print "ok - 4 Euhc::o_ == -o  $^X $__FILE__\n";
}
else {
    print "not ok - 4 Euhc::o_ == -o  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::R_ ne '') == (-R ne '')) {
    print "ok - 5 Euhc::R_ == -R  $^X $__FILE__\n";
}
else {
    print "not ok - 5 Euhc::R_ == -R  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::W_ ne '') == (-W ne '')) {
    print "ok - 6 Euhc::W_ == -W  $^X $__FILE__\n";
}
else {
    print "not ok - 6 Euhc::W_ == -W  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::X_ ne '') == (-X ne '')) {
    print "ok - 7 Euhc::X_ == -X  $^X $__FILE__\n";
}
else {
    print "not ok - 7 Euhc::X_ == -X  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::O_ ne '') == (-O ne '')) {
    print "ok - 8 Euhc::O_ == -O  $^X $__FILE__\n";
}
else {
    print "not ok - 8 Euhc::O_ == -O  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::e_ ne '') == (-e ne '')) {
    print "ok - 9 Euhc::e_ == -e  $^X $__FILE__\n";
}
else {
    print "not ok - 9 Euhc::e_ == -e  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::z_ ne '') == (-z ne '')) {
    print "ok - 10 Euhc::z_ == -z  $^X $__FILE__\n";
}
else {
    print "not ok - 10 Euhc::z_ == -z  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::s_ ne '') == (-s ne '')) {
    print "ok - 11 Euhc::s_ == -s  $^X $__FILE__\n";
}
else {
    print "not ok - 11 Euhc::s_ == -s  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::f_ ne '') == (-f ne '')) {
    print "ok - 12 Euhc::f_ == -f  $^X $__FILE__\n";
}
else {
    print "not ok - 12 Euhc::f_ == -f  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::d_ ne '') == (-d ne '')) {
    print "ok - 13 Euhc::d_ == -d  $^X $__FILE__\n";
}
else {
    print "not ok - 13 Euhc::d_ == -d  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::p_ ne '') == (-p ne '')) {
    print "ok - 14 Euhc::p_ == -p  $^X $__FILE__\n";
}
else {
    print "not ok - 14 Euhc::p_ == -p  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::S_ ne '') == (-S ne '')) {
    print "ok - 15 Euhc::S_ == -S  $^X $__FILE__\n";
}
else {
    print "not ok - 15 Euhc::S_ == -S  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::b_ ne '') == (-b ne '')) {
    print "ok - 16 Euhc::b_ == -b  $^X $__FILE__\n";
}
else {
    print "not ok - 16 Euhc::b_ == -b  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::c_ ne '') == (-c ne '')) {
    print "ok - 17 Euhc::c_ == -c  $^X $__FILE__\n";
}
else {
    print "not ok - 17 Euhc::c_ == -c  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::u_ ne '') == (-u ne '')) {
    print "ok - 18 Euhc::u_ == -u  $^X $__FILE__\n";
}
else {
    print "not ok - 18 Euhc::u_ == -u  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::g_ ne '') == (-g ne '')) {
    print "ok - 19 Euhc::g_ == -g  $^X $__FILE__\n";
}
else {
    print "not ok - 19 Euhc::g_ == -g  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::T_ ne '') == (-T ne '')) {
    print "ok - 20 Euhc::T_ == -T  $^X $__FILE__\n";
}
else {
    print "not ok - 20 Euhc::T_ == -T  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::B_ ne '') == (-B ne '')) {
    print "ok - 21 Euhc::B_ == -B  $^X $__FILE__\n";
}
else {
    print "not ok - 21 Euhc::B_ == -B  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::M_ ne '') == (-M ne '')) {
    print "ok - 22 Euhc::M_ == -M  $^X $__FILE__\n";
}
else {
    print "not ok - 22 Euhc::M_ == -M  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::A_ ne '') == (-A ne '')) {
    print "ok - 23 Euhc::A_ == -A  $^X $__FILE__\n";
}
else {
    print "not ok - 23 Euhc::A_ == -A  $^X $__FILE__\n";
}

$_ = 'file';
if ((Euhc::C_ ne '') == (-C ne '')) {
    print "ok - 24 Euhc::C_ == -C  $^X $__FILE__\n";
}
else {
    print "not ok - 24 Euhc::C_ == -C  $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
