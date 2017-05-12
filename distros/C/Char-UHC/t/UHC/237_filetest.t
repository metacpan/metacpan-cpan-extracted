# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

# Euhc::X 궴 -X (Perl궻긲�@귽깑긡긚긣뎶럁럔) 궻뙅됈궕덇뭭궥귡궞궴궻긡긚긣

my $__FILE__ = __FILE__;

use Euhc;
print "1..48\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..48) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);

open(FILE,'file');

if (((Euhc::r 'file') ne '') == ((-r 'file') ne '')) {
    print "ok - 1 Euhc::r 'file' == -r 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Euhc::r 'file' == -r 'file' $^X $__FILE__\n";
}

if (((Euhc::r FILE) ne '') == ((-r FILE) ne '')) {
    print "ok - 2 Euhc::r FILE == -r FILE $^X $__FILE__\n";
}
else {
    print "not ok - 2 Euhc::r FILE == -r FILE $^X $__FILE__\n";
}

if (((Euhc::w 'file') ne '') == ((-w 'file') ne '')) {
    print "ok - 3 Euhc::w 'file' == -w 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Euhc::w 'file' == -w 'file' $^X $__FILE__\n";
}

if (((Euhc::w FILE) ne '') == ((-w FILE) ne '')) {
    print "ok - 4 Euhc::w FILE == -w FILE $^X $__FILE__\n";
}
else {
    print "not ok - 4 Euhc::w FILE == -w FILE $^X $__FILE__\n";
}

if (((Euhc::x 'file') ne '') == ((-x 'file') ne '')) {
    print "ok - 5 Euhc::x 'file' == -x 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Euhc::x 'file' == -x 'file' $^X $__FILE__\n";
}

if (((Euhc::x FILE) ne '') == ((-x FILE) ne '')) {
    print "ok - 6 Euhc::x FILE == -x FILE $^X $__FILE__\n";
}
else {
    print "not ok - 6 Euhc::x FILE == -x FILE $^X $__FILE__\n";
}

if (((Euhc::o 'file') ne '') == ((-o 'file') ne '')) {
    print "ok - 7 Euhc::o 'file' == -o 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Euhc::o 'file' == -o 'file' $^X $__FILE__\n";
}

if (((Euhc::o FILE) ne '') == ((-o FILE) ne '')) {
    print "ok - 8 Euhc::o FILE == -o FILE $^X $__FILE__\n";
}
else {
    print "not ok - 8 Euhc::o FILE == -o FILE $^X $__FILE__\n";
}

if (((Euhc::R 'file') ne '') == ((-R 'file') ne '')) {
    print "ok - 9 Euhc::R 'file' == -R 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Euhc::R 'file' == -R 'file' $^X $__FILE__\n";
}

if (((Euhc::R FILE) ne '') == ((-R FILE) ne '')) {
    print "ok - 10 Euhc::R FILE == -R FILE $^X $__FILE__\n";
}
else {
    print "not ok - 10 Euhc::R FILE == -R FILE $^X $__FILE__\n";
}

if (((Euhc::W 'file') ne '') == ((-W 'file') ne '')) {
    print "ok - 11 Euhc::W 'file' == -W 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Euhc::W 'file' == -W 'file' $^X $__FILE__\n";
}

if (((Euhc::W FILE) ne '') == ((-W FILE) ne '')) {
    print "ok - 12 Euhc::W FILE == -W FILE $^X $__FILE__\n";
}
else {
    print "not ok - 12 Euhc::W FILE == -W FILE $^X $__FILE__\n";
}

if (((Euhc::X 'file') ne '') == ((-X 'file') ne '')) {
    print "ok - 13 Euhc::X 'file' == -X 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Euhc::X 'file' == -X 'file' $^X $__FILE__\n";
}

if (((Euhc::X FILE) ne '') == ((-X FILE) ne '')) {
    print "ok - 14 Euhc::X FILE == -X FILE $^X $__FILE__\n";
}
else {
    print "not ok - 14 Euhc::X FILE == -X FILE $^X $__FILE__\n";
}

if (((Euhc::O 'file') ne '') == ((-O 'file') ne '')) {
    print "ok - 15 Euhc::O 'file' == -O 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Euhc::O 'file' == -O 'file' $^X $__FILE__\n";
}

if (((Euhc::O FILE) ne '') == ((-O FILE) ne '')) {
    print "ok - 16 Euhc::O FILE == -O FILE $^X $__FILE__\n";
}
else {
    print "not ok - 16 Euhc::O FILE == -O FILE $^X $__FILE__\n";
}

if (((Euhc::e 'file') ne '') == ((-e 'file') ne '')) {
    print "ok - 17 Euhc::e 'file' == -e 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Euhc::e 'file' == -e 'file' $^X $__FILE__\n";
}

if (((Euhc::e FILE) ne '') == ((-e FILE) ne '')) {
    print "ok - 18 Euhc::e FILE == -e FILE $^X $__FILE__\n";
}
else {
    print "not ok - 18 Euhc::e FILE == -e FILE $^X $__FILE__\n";
}

if (((Euhc::z 'file') ne '') == ((-z 'file') ne '')) {
    print "ok - 19 Euhc::z 'file' == -z 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Euhc::z 'file' == -z 'file' $^X $__FILE__\n";
}

if (((Euhc::z FILE) ne '') == ((-z FILE) ne '')) {
    print "ok - 20 Euhc::z FILE == -z FILE $^X $__FILE__\n";
}
else {
    print "not ok - 20 Euhc::z FILE == -z FILE $^X $__FILE__\n";
}

if (((Euhc::s 'file') ne '') == ((-s 'file') ne '')) {
    print "ok - 21 Euhc::s 'file' == -s 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Euhc::s 'file' == -s 'file' $^X $__FILE__\n";
}

if (((Euhc::s FILE) ne '') == ((-s FILE) ne '')) {
    print "ok - 22 Euhc::s FILE == -s FILE $^X $__FILE__\n";
}
else {
    print "not ok - 22 Euhc::s FILE == -s FILE $^X $__FILE__\n";
}

if (((Euhc::f 'file') ne '') == ((-f 'file') ne '')) {
    print "ok - 23 Euhc::f 'file' == -f 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 23 Euhc::f 'file' == -f 'file' $^X $__FILE__\n";
}

if (((Euhc::f FILE) ne '') == ((-f FILE) ne '')) {
    print "ok - 24 Euhc::f FILE == -f FILE $^X $__FILE__\n";
}
else {
    print "not ok - 24 Euhc::f FILE == -f FILE $^X $__FILE__\n";
}

if (((Euhc::d 'file') ne '') == ((-d 'file') ne '')) {
    print "ok - 25 Euhc::d 'file' == -d 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 25 Euhc::d 'file' == -d 'file' $^X $__FILE__\n";
}

if (((Euhc::d FILE) ne '') == ((-d FILE) ne '')) {
    print "ok - 26 Euhc::d FILE == -d FILE $^X $__FILE__\n";
}
else {
    print "not ok - 26 Euhc::d FILE == -d FILE $^X $__FILE__\n";
}

if (((Euhc::p 'file') ne '') == ((-p 'file') ne '')) {
    print "ok - 27 Euhc::p 'file' == -p 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 27 Euhc::p 'file' == -p 'file' $^X $__FILE__\n";
}

if (((Euhc::p FILE) ne '') == ((-p FILE) ne '')) {
    print "ok - 28 Euhc::p FILE == -p FILE $^X $__FILE__\n";
}
else {
    print "not ok - 28 Euhc::p FILE == -p FILE $^X $__FILE__\n";
}

if (((Euhc::S 'file') ne '') == ((-S 'file') ne '')) {
    print "ok - 29 Euhc::S 'file' == -S 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 29 Euhc::S 'file' == -S 'file' $^X $__FILE__\n";
}

if (((Euhc::S FILE) ne '') == ((-S FILE) ne '')) {
    print "ok - 30 Euhc::S FILE == -S FILE $^X $__FILE__\n";
}
else {
    print "not ok - 30 Euhc::S FILE == -S FILE $^X $__FILE__\n";
}

if (((Euhc::b 'file') ne '') == ((-b 'file') ne '')) {
    print "ok - 31 Euhc::b 'file' == -b 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 31 Euhc::b 'file' == -b 'file' $^X $__FILE__\n";
}

if (((Euhc::b FILE) ne '') == ((-b FILE) ne '')) {
    print "ok - 32 Euhc::b FILE == -b FILE $^X $__FILE__\n";
}
else {
    print "not ok - 32 Euhc::b FILE == -b FILE $^X $__FILE__\n";
}

if (((Euhc::c 'file') ne '') == ((-c 'file') ne '')) {
    print "ok - 33 Euhc::c 'file' == -c 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 33 Euhc::c 'file' == -c 'file' $^X $__FILE__\n";
}

if (((Euhc::c FILE) ne '') == ((-c FILE) ne '')) {
    print "ok - 34 Euhc::c FILE == -c FILE $^X $__FILE__\n";
}
else {
    print "not ok - 34 Euhc::c FILE == -c FILE $^X $__FILE__\n";
}

if (((Euhc::u 'file') ne '') == ((-u 'file') ne '')) {
    print "ok - 35 Euhc::u 'file' == -u 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 35 Euhc::u 'file' == -u 'file' $^X $__FILE__\n";
}

if (((Euhc::u FILE) ne '') == ((-u FILE) ne '')) {
    print "ok - 36 Euhc::u FILE == -u FILE $^X $__FILE__\n";
}
else {
    print "not ok - 36 Euhc::u FILE == -u FILE $^X $__FILE__\n";
}

if (((Euhc::g 'file') ne '') == ((-g 'file') ne '')) {
    print "ok - 37 Euhc::g 'file' == -g 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 37 Euhc::g 'file' == -g 'file' $^X $__FILE__\n";
}

if (((Euhc::g FILE) ne '') == ((-g FILE) ne '')) {
    print "ok - 38 Euhc::g FILE == -g FILE $^X $__FILE__\n";
}
else {
    print "not ok - 38 Euhc::g FILE == -g FILE $^X $__FILE__\n";
}

if (((Euhc::T 'file') ne '') == ((-T 'file') ne '')) {
    print "ok - 39 Euhc::T 'file' == -T 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 39 Euhc::T 'file' == -T 'file' $^X $__FILE__\n";
}

if (((Euhc::T FILE) ne '') == ((-T FILE) ne '')) {
    print "ok - 40 Euhc::T FILE == -T FILE $^X $__FILE__\n";
}
else {
    print "not ok - 40 Euhc::T FILE == -T FILE $^X $__FILE__\n";
}

if (((Euhc::B 'file') ne '') == ((-B 'file') ne '')) {
    print "ok - 41 Euhc::B 'file' == -B 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 41 Euhc::B 'file' == -B 'file' $^X $__FILE__\n";
}

if (((Euhc::B FILE) ne '') == ((-B FILE) ne '')) {
    print "ok - 42 Euhc::B FILE == -B FILE $^X $__FILE__\n";
}
else {
    print "not ok - 42 Euhc::B FILE == -B FILE $^X $__FILE__\n";
}

if (((Euhc::M 'file') ne '') == ((-M 'file') ne '')) {
    print "ok - 43 Euhc::M 'file' == -M 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 43 Euhc::M 'file' == -M 'file' $^X $__FILE__\n";
}

if (((Euhc::M FILE) ne '') == ((-M FILE) ne '')) {
    print "ok - 44 Euhc::M FILE == -M FILE $^X $__FILE__\n";
}
else {
    print "not ok - 44 Euhc::M FILE == -M FILE $^X $__FILE__\n";
}

if (((Euhc::A 'file') ne '') == ((-A 'file') ne '')) {
    print "ok - 45 Euhc::A 'file' == -A 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 45 Euhc::A 'file' == -A 'file' $^X $__FILE__\n";
}

if (((Euhc::A FILE) ne '') == ((-A FILE) ne '')) {
    print "ok - 46 Euhc::A FILE == -A FILE $^X $__FILE__\n";
}
else {
    print "not ok - 46 Euhc::A FILE == -A FILE $^X $__FILE__\n";
}

if (((Euhc::C 'file') ne '') == ((-C 'file') ne '')) {
    print "ok - 47 Euhc::C 'file' == -C 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 47 Euhc::C 'file' == -C 'file' $^X $__FILE__\n";
}

if (((Euhc::C FILE) ne '') == ((-C FILE) ne '')) {
    print "ok - 48 Euhc::C FILE == -C FILE $^X $__FILE__\n";
}
else {
    print "not ok - 48 Euhc::C FILE == -C FILE $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
