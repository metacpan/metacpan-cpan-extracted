# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{あ} ne "\x82\xa0";

# Ebig5::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト

my $__FILE__ = __FILE__;

use Ebig5;
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

if (((Ebig5::r 'file') ne '') == ((-r 'file') ne '')) {
    print "ok - 1 Ebig5::r 'file' == -r 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Ebig5::r 'file' == -r 'file' $^X $__FILE__\n";
}

if (((Ebig5::r FILE) ne '') == ((-r FILE) ne '')) {
    print "ok - 2 Ebig5::r FILE == -r FILE $^X $__FILE__\n";
}
else {
    print "not ok - 2 Ebig5::r FILE == -r FILE $^X $__FILE__\n";
}

if (((Ebig5::w 'file') ne '') == ((-w 'file') ne '')) {
    print "ok - 3 Ebig5::w 'file' == -w 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Ebig5::w 'file' == -w 'file' $^X $__FILE__\n";
}

if (((Ebig5::w FILE) ne '') == ((-w FILE) ne '')) {
    print "ok - 4 Ebig5::w FILE == -w FILE $^X $__FILE__\n";
}
else {
    print "not ok - 4 Ebig5::w FILE == -w FILE $^X $__FILE__\n";
}

if (((Ebig5::x 'file') ne '') == ((-x 'file') ne '')) {
    print "ok - 5 Ebig5::x 'file' == -x 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Ebig5::x 'file' == -x 'file' $^X $__FILE__\n";
}

if (((Ebig5::x FILE) ne '') == ((-x FILE) ne '')) {
    print "ok - 6 Ebig5::x FILE == -x FILE $^X $__FILE__\n";
}
else {
    print "not ok - 6 Ebig5::x FILE == -x FILE $^X $__FILE__\n";
}

if (((Ebig5::o 'file') ne '') == ((-o 'file') ne '')) {
    print "ok - 7 Ebig5::o 'file' == -o 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Ebig5::o 'file' == -o 'file' $^X $__FILE__\n";
}

if (((Ebig5::o FILE) ne '') == ((-o FILE) ne '')) {
    print "ok - 8 Ebig5::o FILE == -o FILE $^X $__FILE__\n";
}
else {
    print "not ok - 8 Ebig5::o FILE == -o FILE $^X $__FILE__\n";
}

if (((Ebig5::R 'file') ne '') == ((-R 'file') ne '')) {
    print "ok - 9 Ebig5::R 'file' == -R 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Ebig5::R 'file' == -R 'file' $^X $__FILE__\n";
}

if (((Ebig5::R FILE) ne '') == ((-R FILE) ne '')) {
    print "ok - 10 Ebig5::R FILE == -R FILE $^X $__FILE__\n";
}
else {
    print "not ok - 10 Ebig5::R FILE == -R FILE $^X $__FILE__\n";
}

if (((Ebig5::W 'file') ne '') == ((-W 'file') ne '')) {
    print "ok - 11 Ebig5::W 'file' == -W 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ebig5::W 'file' == -W 'file' $^X $__FILE__\n";
}

if (((Ebig5::W FILE) ne '') == ((-W FILE) ne '')) {
    print "ok - 12 Ebig5::W FILE == -W FILE $^X $__FILE__\n";
}
else {
    print "not ok - 12 Ebig5::W FILE == -W FILE $^X $__FILE__\n";
}

if (((Ebig5::X 'file') ne '') == ((-X 'file') ne '')) {
    print "ok - 13 Ebig5::X 'file' == -X 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Ebig5::X 'file' == -X 'file' $^X $__FILE__\n";
}

if (((Ebig5::X FILE) ne '') == ((-X FILE) ne '')) {
    print "ok - 14 Ebig5::X FILE == -X FILE $^X $__FILE__\n";
}
else {
    print "not ok - 14 Ebig5::X FILE == -X FILE $^X $__FILE__\n";
}

if (((Ebig5::O 'file') ne '') == ((-O 'file') ne '')) {
    print "ok - 15 Ebig5::O 'file' == -O 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Ebig5::O 'file' == -O 'file' $^X $__FILE__\n";
}

if (((Ebig5::O FILE) ne '') == ((-O FILE) ne '')) {
    print "ok - 16 Ebig5::O FILE == -O FILE $^X $__FILE__\n";
}
else {
    print "not ok - 16 Ebig5::O FILE == -O FILE $^X $__FILE__\n";
}

if (((Ebig5::e 'file') ne '') == ((-e 'file') ne '')) {
    print "ok - 17 Ebig5::e 'file' == -e 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Ebig5::e 'file' == -e 'file' $^X $__FILE__\n";
}

if (((Ebig5::e FILE) ne '') == ((-e FILE) ne '')) {
    print "ok - 18 Ebig5::e FILE == -e FILE $^X $__FILE__\n";
}
else {
    print "not ok - 18 Ebig5::e FILE == -e FILE $^X $__FILE__\n";
}

if (((Ebig5::z 'file') ne '') == ((-z 'file') ne '')) {
    print "ok - 19 Ebig5::z 'file' == -z 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Ebig5::z 'file' == -z 'file' $^X $__FILE__\n";
}

if (((Ebig5::z FILE) ne '') == ((-z FILE) ne '')) {
    print "ok - 20 Ebig5::z FILE == -z FILE $^X $__FILE__\n";
}
else {
    print "not ok - 20 Ebig5::z FILE == -z FILE $^X $__FILE__\n";
}

if (((Ebig5::s 'file') ne '') == ((-s 'file') ne '')) {
    print "ok - 21 Ebig5::s 'file' == -s 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ebig5::s 'file' == -s 'file' $^X $__FILE__\n";
}

if (((Ebig5::s FILE) ne '') == ((-s FILE) ne '')) {
    print "ok - 22 Ebig5::s FILE == -s FILE $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ebig5::s FILE == -s FILE $^X $__FILE__\n";
}

if (((Ebig5::f 'file') ne '') == ((-f 'file') ne '')) {
    print "ok - 23 Ebig5::f 'file' == -f 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 23 Ebig5::f 'file' == -f 'file' $^X $__FILE__\n";
}

if (((Ebig5::f FILE) ne '') == ((-f FILE) ne '')) {
    print "ok - 24 Ebig5::f FILE == -f FILE $^X $__FILE__\n";
}
else {
    print "not ok - 24 Ebig5::f FILE == -f FILE $^X $__FILE__\n";
}

if (((Ebig5::d 'file') ne '') == ((-d 'file') ne '')) {
    print "ok - 25 Ebig5::d 'file' == -d 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 25 Ebig5::d 'file' == -d 'file' $^X $__FILE__\n";
}

if (((Ebig5::d FILE) ne '') == ((-d FILE) ne '')) {
    print "ok - 26 Ebig5::d FILE == -d FILE $^X $__FILE__\n";
}
else {
    print "not ok - 26 Ebig5::d FILE == -d FILE $^X $__FILE__\n";
}

if (((Ebig5::p 'file') ne '') == ((-p 'file') ne '')) {
    print "ok - 27 Ebig5::p 'file' == -p 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 27 Ebig5::p 'file' == -p 'file' $^X $__FILE__\n";
}

if (((Ebig5::p FILE) ne '') == ((-p FILE) ne '')) {
    print "ok - 28 Ebig5::p FILE == -p FILE $^X $__FILE__\n";
}
else {
    print "not ok - 28 Ebig5::p FILE == -p FILE $^X $__FILE__\n";
}

if (((Ebig5::S 'file') ne '') == ((-S 'file') ne '')) {
    print "ok - 29 Ebig5::S 'file' == -S 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 29 Ebig5::S 'file' == -S 'file' $^X $__FILE__\n";
}

if (((Ebig5::S FILE) ne '') == ((-S FILE) ne '')) {
    print "ok - 30 Ebig5::S FILE == -S FILE $^X $__FILE__\n";
}
else {
    print "not ok - 30 Ebig5::S FILE == -S FILE $^X $__FILE__\n";
}

if (((Ebig5::b 'file') ne '') == ((-b 'file') ne '')) {
    print "ok - 31 Ebig5::b 'file' == -b 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 31 Ebig5::b 'file' == -b 'file' $^X $__FILE__\n";
}

if (((Ebig5::b FILE) ne '') == ((-b FILE) ne '')) {
    print "ok - 32 Ebig5::b FILE == -b FILE $^X $__FILE__\n";
}
else {
    print "not ok - 32 Ebig5::b FILE == -b FILE $^X $__FILE__\n";
}

if (((Ebig5::c 'file') ne '') == ((-c 'file') ne '')) {
    print "ok - 33 Ebig5::c 'file' == -c 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 33 Ebig5::c 'file' == -c 'file' $^X $__FILE__\n";
}

if (((Ebig5::c FILE) ne '') == ((-c FILE) ne '')) {
    print "ok - 34 Ebig5::c FILE == -c FILE $^X $__FILE__\n";
}
else {
    print "not ok - 34 Ebig5::c FILE == -c FILE $^X $__FILE__\n";
}

if (((Ebig5::u 'file') ne '') == ((-u 'file') ne '')) {
    print "ok - 35 Ebig5::u 'file' == -u 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 35 Ebig5::u 'file' == -u 'file' $^X $__FILE__\n";
}

if (((Ebig5::u FILE) ne '') == ((-u FILE) ne '')) {
    print "ok - 36 Ebig5::u FILE == -u FILE $^X $__FILE__\n";
}
else {
    print "not ok - 36 Ebig5::u FILE == -u FILE $^X $__FILE__\n";
}

if (((Ebig5::g 'file') ne '') == ((-g 'file') ne '')) {
    print "ok - 37 Ebig5::g 'file' == -g 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 37 Ebig5::g 'file' == -g 'file' $^X $__FILE__\n";
}

if (((Ebig5::g FILE) ne '') == ((-g FILE) ne '')) {
    print "ok - 38 Ebig5::g FILE == -g FILE $^X $__FILE__\n";
}
else {
    print "not ok - 38 Ebig5::g FILE == -g FILE $^X $__FILE__\n";
}

if (((Ebig5::T 'file') ne '') == ((-T 'file') ne '')) {
    print "ok - 39 Ebig5::T 'file' == -T 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 39 Ebig5::T 'file' == -T 'file' $^X $__FILE__\n";
}

if (((Ebig5::T FILE) ne '') == ((-T FILE) ne '')) {
    print "ok - 40 Ebig5::T FILE == -T FILE $^X $__FILE__\n";
}
else {
    print "not ok - 40 Ebig5::T FILE == -T FILE $^X $__FILE__\n";
}

if (((Ebig5::B 'file') ne '') == ((-B 'file') ne '')) {
    print "ok - 41 Ebig5::B 'file' == -B 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 41 Ebig5::B 'file' == -B 'file' $^X $__FILE__\n";
}

if (((Ebig5::B FILE) ne '') == ((-B FILE) ne '')) {
    print "ok - 42 Ebig5::B FILE == -B FILE $^X $__FILE__\n";
}
else {
    print "not ok - 42 Ebig5::B FILE == -B FILE $^X $__FILE__\n";
}

if (((Ebig5::M 'file') ne '') == ((-M 'file') ne '')) {
    print "ok - 43 Ebig5::M 'file' == -M 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 43 Ebig5::M 'file' == -M 'file' $^X $__FILE__\n";
}

if (((Ebig5::M FILE) ne '') == ((-M FILE) ne '')) {
    print "ok - 44 Ebig5::M FILE == -M FILE $^X $__FILE__\n";
}
else {
    print "not ok - 44 Ebig5::M FILE == -M FILE $^X $__FILE__\n";
}

if (((Ebig5::A 'file') ne '') == ((-A 'file') ne '')) {
    print "ok - 45 Ebig5::A 'file' == -A 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 45 Ebig5::A 'file' == -A 'file' $^X $__FILE__\n";
}

if (((Ebig5::A FILE) ne '') == ((-A FILE) ne '')) {
    print "ok - 46 Ebig5::A FILE == -A FILE $^X $__FILE__\n";
}
else {
    print "not ok - 46 Ebig5::A FILE == -A FILE $^X $__FILE__\n";
}

if (((Ebig5::C 'file') ne '') == ((-C 'file') ne '')) {
    print "ok - 47 Ebig5::C 'file' == -C 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 47 Ebig5::C 'file' == -C 'file' $^X $__FILE__\n";
}

if (((Ebig5::C FILE) ne '') == ((-C FILE) ne '')) {
    print "ok - 48 Ebig5::C FILE == -C FILE $^X $__FILE__\n";
}
else {
    print "not ok - 48 Ebig5::C FILE == -C FILE $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
