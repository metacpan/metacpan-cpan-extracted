# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

# 堷悢偑徣棯偝傟偨応崌偺僥僗僩

my $__FILE__ = __FILE__;

use Egb18030;
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
if ((Egb18030::r_ ne '') == (-r ne '')) {
    print "ok - 1 Egb18030::r_ == -r  $^X $__FILE__\n";
}
else {
    print "not ok - 1 Egb18030::r_ == -r  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::w_ ne '') == (-w ne '')) {
    print "ok - 2 Egb18030::w_ == -w  $^X $__FILE__\n";
}
else {
    print "not ok - 2 Egb18030::w_ == -w  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::x_ ne '') == (-x ne '')) {
    print "ok - 3 Egb18030::x_ == -x  $^X $__FILE__\n";
}
else {
    print "not ok - 3 Egb18030::x_ == -x  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::o_ ne '') == (-o ne '')) {
    print "ok - 4 Egb18030::o_ == -o  $^X $__FILE__\n";
}
else {
    print "not ok - 4 Egb18030::o_ == -o  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::R_ ne '') == (-R ne '')) {
    print "ok - 5 Egb18030::R_ == -R  $^X $__FILE__\n";
}
else {
    print "not ok - 5 Egb18030::R_ == -R  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::W_ ne '') == (-W ne '')) {
    print "ok - 6 Egb18030::W_ == -W  $^X $__FILE__\n";
}
else {
    print "not ok - 6 Egb18030::W_ == -W  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::X_ ne '') == (-X ne '')) {
    print "ok - 7 Egb18030::X_ == -X  $^X $__FILE__\n";
}
else {
    print "not ok - 7 Egb18030::X_ == -X  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::O_ ne '') == (-O ne '')) {
    print "ok - 8 Egb18030::O_ == -O  $^X $__FILE__\n";
}
else {
    print "not ok - 8 Egb18030::O_ == -O  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::e_ ne '') == (-e ne '')) {
    print "ok - 9 Egb18030::e_ == -e  $^X $__FILE__\n";
}
else {
    print "not ok - 9 Egb18030::e_ == -e  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::z_ ne '') == (-z ne '')) {
    print "ok - 10 Egb18030::z_ == -z  $^X $__FILE__\n";
}
else {
    print "not ok - 10 Egb18030::z_ == -z  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::s_ ne '') == (-s ne '')) {
    print "ok - 11 Egb18030::s_ == -s  $^X $__FILE__\n";
}
else {
    print "not ok - 11 Egb18030::s_ == -s  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::f_ ne '') == (-f ne '')) {
    print "ok - 12 Egb18030::f_ == -f  $^X $__FILE__\n";
}
else {
    print "not ok - 12 Egb18030::f_ == -f  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::d_ ne '') == (-d ne '')) {
    print "ok - 13 Egb18030::d_ == -d  $^X $__FILE__\n";
}
else {
    print "not ok - 13 Egb18030::d_ == -d  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::p_ ne '') == (-p ne '')) {
    print "ok - 14 Egb18030::p_ == -p  $^X $__FILE__\n";
}
else {
    print "not ok - 14 Egb18030::p_ == -p  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::S_ ne '') == (-S ne '')) {
    print "ok - 15 Egb18030::S_ == -S  $^X $__FILE__\n";
}
else {
    print "not ok - 15 Egb18030::S_ == -S  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::b_ ne '') == (-b ne '')) {
    print "ok - 16 Egb18030::b_ == -b  $^X $__FILE__\n";
}
else {
    print "not ok - 16 Egb18030::b_ == -b  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::c_ ne '') == (-c ne '')) {
    print "ok - 17 Egb18030::c_ == -c  $^X $__FILE__\n";
}
else {
    print "not ok - 17 Egb18030::c_ == -c  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::u_ ne '') == (-u ne '')) {
    print "ok - 18 Egb18030::u_ == -u  $^X $__FILE__\n";
}
else {
    print "not ok - 18 Egb18030::u_ == -u  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::g_ ne '') == (-g ne '')) {
    print "ok - 19 Egb18030::g_ == -g  $^X $__FILE__\n";
}
else {
    print "not ok - 19 Egb18030::g_ == -g  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::T_ ne '') == (-T ne '')) {
    print "ok - 20 Egb18030::T_ == -T  $^X $__FILE__\n";
}
else {
    print "not ok - 20 Egb18030::T_ == -T  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::B_ ne '') == (-B ne '')) {
    print "ok - 21 Egb18030::B_ == -B  $^X $__FILE__\n";
}
else {
    print "not ok - 21 Egb18030::B_ == -B  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::M_ ne '') == (-M ne '')) {
    print "ok - 22 Egb18030::M_ == -M  $^X $__FILE__\n";
}
else {
    print "not ok - 22 Egb18030::M_ == -M  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::A_ ne '') == (-A ne '')) {
    print "ok - 23 Egb18030::A_ == -A  $^X $__FILE__\n";
}
else {
    print "not ok - 23 Egb18030::A_ == -A  $^X $__FILE__\n";
}

$_ = 'file';
if ((Egb18030::C_ ne '') == (-C ne '')) {
    print "ok - 24 Egb18030::C_ == -C  $^X $__FILE__\n";
}
else {
    print "not ok - 24 Egb18030::C_ == -C  $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
