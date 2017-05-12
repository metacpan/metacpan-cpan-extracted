# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

# Euhc::X 궴 -X (Perl궻긲�@귽깑긡긚긣뎶럁럔) 궻뙅됈궕덇뭭궥귡궞궴궻긡긚긣(뫮뤭궼긢귻깒긏긣깏)

my $__FILE__ = __FILE__;

use Euhc;
print "1..22\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..22) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

mkdir('directory',0777);

opendir(DIR,'directory');

if (((Euhc::r 'directory') ne '') == ((-r 'directory') ne '')) {
    print "ok - 1 Euhc::r 'directory' == -r 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Euhc::r 'directory' == -r 'directory' $^X $__FILE__\n";
}

if (((Euhc::w 'directory') ne '') == ((-w 'directory') ne '')) {
    print "ok - 2 Euhc::w 'directory' == -w 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 2 Euhc::w 'directory' == -w 'directory' $^X $__FILE__\n";
}

if (((Euhc::x 'directory') ne '') == ((-x 'directory') ne '')) {
    print "ok - 3 Euhc::x 'directory' == -x 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Euhc::x 'directory' == -x 'directory' $^X $__FILE__\n";
}

if (((Euhc::o 'directory') ne '') == ((-o 'directory') ne '')) {
    print "ok - 4 Euhc::o 'directory' == -o 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 4 Euhc::o 'directory' == -o 'directory' $^X $__FILE__\n";
}

if (((Euhc::R 'directory') ne '') == ((-R 'directory') ne '')) {
    print "ok - 5 Euhc::R 'directory' == -R 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Euhc::R 'directory' == -R 'directory' $^X $__FILE__\n";
}

if (((Euhc::W 'directory') ne '') == ((-W 'directory') ne '')) {
    print "ok - 6 Euhc::W 'directory' == -W 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 6 Euhc::W 'directory' == -W 'directory' $^X $__FILE__\n";
}

if (((Euhc::X 'directory') ne '') == ((-X 'directory') ne '')) {
    print "ok - 7 Euhc::X 'directory' == -X 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Euhc::X 'directory' == -X 'directory' $^X $__FILE__\n";
}

if (((Euhc::O 'directory') ne '') == ((-O 'directory') ne '')) {
    print "ok - 8 Euhc::O 'directory' == -O 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 8 Euhc::O 'directory' == -O 'directory' $^X $__FILE__\n";
}

if (((Euhc::e 'directory') ne '') == ((-e 'directory') ne '')) {
    print "ok - 9 Euhc::e 'directory' == -e 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Euhc::e 'directory' == -e 'directory' $^X $__FILE__\n";
}

if (((Euhc::z 'directory') ne '') == ((-z 'directory') ne '')) {
    print "ok - 10 Euhc::z 'directory' == -z 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 10 Euhc::z 'directory' == -z 'directory' $^X $__FILE__\n";
}

if (((Euhc::s 'directory') ne '') == ((-s 'directory') ne '')) {
    print "ok - 11 Euhc::s 'directory' == -s 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Euhc::s 'directory' == -s 'directory' $^X $__FILE__\n";
}

if (((Euhc::f 'directory') ne '') == ((-f 'directory') ne '')) {
    print "ok - 12 Euhc::f 'directory' == -f 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 12 Euhc::f 'directory' == -f 'directory' $^X $__FILE__\n";
}

if (((Euhc::d 'directory') ne '') == ((-d 'directory') ne '')) {
    print "ok - 13 Euhc::d 'directory' == -d 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Euhc::d 'directory' == -d 'directory' $^X $__FILE__\n";
}

if (((Euhc::p 'directory') ne '') == ((-p 'directory') ne '')) {
    print "ok - 14 Euhc::p 'directory' == -p 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 14 Euhc::p 'directory' == -p 'directory' $^X $__FILE__\n";
}

if (((Euhc::S 'directory') ne '') == ((-S 'directory') ne '')) {
    print "ok - 15 Euhc::S 'directory' == -S 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Euhc::S 'directory' == -S 'directory' $^X $__FILE__\n";
}

if (((Euhc::b 'directory') ne '') == ((-b 'directory') ne '')) {
    print "ok - 16 Euhc::b 'directory' == -b 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 16 Euhc::b 'directory' == -b 'directory' $^X $__FILE__\n";
}

if (((Euhc::c 'directory') ne '') == ((-c 'directory') ne '')) {
    print "ok - 17 Euhc::c 'directory' == -c 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Euhc::c 'directory' == -c 'directory' $^X $__FILE__\n";
}

if (((Euhc::u 'directory') ne '') == ((-u 'directory') ne '')) {
    print "ok - 18 Euhc::u 'directory' == -u 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 18 Euhc::u 'directory' == -u 'directory' $^X $__FILE__\n";
}

if (((Euhc::g 'directory') ne '') == ((-g 'directory') ne '')) {
    print "ok - 19 Euhc::g 'directory' == -g 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Euhc::g 'directory' == -g 'directory' $^X $__FILE__\n";
}

if (((Euhc::M 'directory') ne '') == ((-M 'directory') ne '')) {
    print "ok - 20 Euhc::M 'directory' == -M 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 20 Euhc::M 'directory' == -M 'directory' $^X $__FILE__\n";
}

if (((Euhc::A 'directory') ne '') == ((-A 'directory') ne '')) {
    print "ok - 21 Euhc::A 'directory' == -A 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Euhc::A 'directory' == -A 'directory' $^X $__FILE__\n";
}

if (((Euhc::C 'directory') ne '') == ((-C 'directory') ne '')) {
    print "ok - 22 Euhc::C 'directory' == -C 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 22 Euhc::C 'directory' == -C 'directory' $^X $__FILE__\n";
}

closedir(DIR);
rmdir('directory');

__END__
