# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{あ} ne "\x82\xa0";

# Ehp15::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト

my $__FILE__ = __FILE__;

use Ehp15;
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

if (((Ehp15::r 'file') ne '') == ((-r 'file') ne '')) {
    print "ok - 1 Ehp15::r 'file' == -r 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Ehp15::r 'file' == -r 'file' $^X $__FILE__\n";
}

if (((Ehp15::r FILE) ne '') == ((-r FILE) ne '')) {
    print "ok - 2 Ehp15::r FILE == -r FILE $^X $__FILE__\n";
}
else {
    print "not ok - 2 Ehp15::r FILE == -r FILE $^X $__FILE__\n";
}

if (((Ehp15::w 'file') ne '') == ((-w 'file') ne '')) {
    print "ok - 3 Ehp15::w 'file' == -w 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Ehp15::w 'file' == -w 'file' $^X $__FILE__\n";
}

if (((Ehp15::w FILE) ne '') == ((-w FILE) ne '')) {
    print "ok - 4 Ehp15::w FILE == -w FILE $^X $__FILE__\n";
}
else {
    print "not ok - 4 Ehp15::w FILE == -w FILE $^X $__FILE__\n";
}

if (((Ehp15::x 'file') ne '') == ((-x 'file') ne '')) {
    print "ok - 5 Ehp15::x 'file' == -x 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Ehp15::x 'file' == -x 'file' $^X $__FILE__\n";
}

if (((Ehp15::x FILE) ne '') == ((-x FILE) ne '')) {
    print "ok - 6 Ehp15::x FILE == -x FILE $^X $__FILE__\n";
}
else {
    print "not ok - 6 Ehp15::x FILE == -x FILE $^X $__FILE__\n";
}

if (((Ehp15::o 'file') ne '') == ((-o 'file') ne '')) {
    print "ok - 7 Ehp15::o 'file' == -o 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Ehp15::o 'file' == -o 'file' $^X $__FILE__\n";
}

if (((Ehp15::o FILE) ne '') == ((-o FILE) ne '')) {
    print "ok - 8 Ehp15::o FILE == -o FILE $^X $__FILE__\n";
}
else {
    print "not ok - 8 Ehp15::o FILE == -o FILE $^X $__FILE__\n";
}

if (((Ehp15::R 'file') ne '') == ((-R 'file') ne '')) {
    print "ok - 9 Ehp15::R 'file' == -R 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Ehp15::R 'file' == -R 'file' $^X $__FILE__\n";
}

if (((Ehp15::R FILE) ne '') == ((-R FILE) ne '')) {
    print "ok - 10 Ehp15::R FILE == -R FILE $^X $__FILE__\n";
}
else {
    print "not ok - 10 Ehp15::R FILE == -R FILE $^X $__FILE__\n";
}

if (((Ehp15::W 'file') ne '') == ((-W 'file') ne '')) {
    print "ok - 11 Ehp15::W 'file' == -W 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ehp15::W 'file' == -W 'file' $^X $__FILE__\n";
}

if (((Ehp15::W FILE) ne '') == ((-W FILE) ne '')) {
    print "ok - 12 Ehp15::W FILE == -W FILE $^X $__FILE__\n";
}
else {
    print "not ok - 12 Ehp15::W FILE == -W FILE $^X $__FILE__\n";
}

if (((Ehp15::X 'file') ne '') == ((-X 'file') ne '')) {
    print "ok - 13 Ehp15::X 'file' == -X 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Ehp15::X 'file' == -X 'file' $^X $__FILE__\n";
}

if (((Ehp15::X FILE) ne '') == ((-X FILE) ne '')) {
    print "ok - 14 Ehp15::X FILE == -X FILE $^X $__FILE__\n";
}
else {
    print "not ok - 14 Ehp15::X FILE == -X FILE $^X $__FILE__\n";
}

if (((Ehp15::O 'file') ne '') == ((-O 'file') ne '')) {
    print "ok - 15 Ehp15::O 'file' == -O 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Ehp15::O 'file' == -O 'file' $^X $__FILE__\n";
}

if (((Ehp15::O FILE) ne '') == ((-O FILE) ne '')) {
    print "ok - 16 Ehp15::O FILE == -O FILE $^X $__FILE__\n";
}
else {
    print "not ok - 16 Ehp15::O FILE == -O FILE $^X $__FILE__\n";
}

if (((Ehp15::e 'file') ne '') == ((-e 'file') ne '')) {
    print "ok - 17 Ehp15::e 'file' == -e 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Ehp15::e 'file' == -e 'file' $^X $__FILE__\n";
}

if (((Ehp15::e FILE) ne '') == ((-e FILE) ne '')) {
    print "ok - 18 Ehp15::e FILE == -e FILE $^X $__FILE__\n";
}
else {
    print "not ok - 18 Ehp15::e FILE == -e FILE $^X $__FILE__\n";
}

if (((Ehp15::z 'file') ne '') == ((-z 'file') ne '')) {
    print "ok - 19 Ehp15::z 'file' == -z 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Ehp15::z 'file' == -z 'file' $^X $__FILE__\n";
}

if (((Ehp15::z FILE) ne '') == ((-z FILE) ne '')) {
    print "ok - 20 Ehp15::z FILE == -z FILE $^X $__FILE__\n";
}
else {
    print "not ok - 20 Ehp15::z FILE == -z FILE $^X $__FILE__\n";
}

if (((Ehp15::s 'file') ne '') == ((-s 'file') ne '')) {
    print "ok - 21 Ehp15::s 'file' == -s 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ehp15::s 'file' == -s 'file' $^X $__FILE__\n";
}

if (((Ehp15::s FILE) ne '') == ((-s FILE) ne '')) {
    print "ok - 22 Ehp15::s FILE == -s FILE $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ehp15::s FILE == -s FILE $^X $__FILE__\n";
}

if (((Ehp15::f 'file') ne '') == ((-f 'file') ne '')) {
    print "ok - 23 Ehp15::f 'file' == -f 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 23 Ehp15::f 'file' == -f 'file' $^X $__FILE__\n";
}

if (((Ehp15::f FILE) ne '') == ((-f FILE) ne '')) {
    print "ok - 24 Ehp15::f FILE == -f FILE $^X $__FILE__\n";
}
else {
    print "not ok - 24 Ehp15::f FILE == -f FILE $^X $__FILE__\n";
}

if (((Ehp15::d 'file') ne '') == ((-d 'file') ne '')) {
    print "ok - 25 Ehp15::d 'file' == -d 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 25 Ehp15::d 'file' == -d 'file' $^X $__FILE__\n";
}

if (((Ehp15::d FILE) ne '') == ((-d FILE) ne '')) {
    print "ok - 26 Ehp15::d FILE == -d FILE $^X $__FILE__\n";
}
else {
    print "not ok - 26 Ehp15::d FILE == -d FILE $^X $__FILE__\n";
}

if (((Ehp15::p 'file') ne '') == ((-p 'file') ne '')) {
    print "ok - 27 Ehp15::p 'file' == -p 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 27 Ehp15::p 'file' == -p 'file' $^X $__FILE__\n";
}

if (((Ehp15::p FILE) ne '') == ((-p FILE) ne '')) {
    print "ok - 28 Ehp15::p FILE == -p FILE $^X $__FILE__\n";
}
else {
    print "not ok - 28 Ehp15::p FILE == -p FILE $^X $__FILE__\n";
}

if (((Ehp15::S 'file') ne '') == ((-S 'file') ne '')) {
    print "ok - 29 Ehp15::S 'file' == -S 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 29 Ehp15::S 'file' == -S 'file' $^X $__FILE__\n";
}

if (((Ehp15::S FILE) ne '') == ((-S FILE) ne '')) {
    print "ok - 30 Ehp15::S FILE == -S FILE $^X $__FILE__\n";
}
else {
    print "not ok - 30 Ehp15::S FILE == -S FILE $^X $__FILE__\n";
}

if (((Ehp15::b 'file') ne '') == ((-b 'file') ne '')) {
    print "ok - 31 Ehp15::b 'file' == -b 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 31 Ehp15::b 'file' == -b 'file' $^X $__FILE__\n";
}

if (((Ehp15::b FILE) ne '') == ((-b FILE) ne '')) {
    print "ok - 32 Ehp15::b FILE == -b FILE $^X $__FILE__\n";
}
else {
    print "not ok - 32 Ehp15::b FILE == -b FILE $^X $__FILE__\n";
}

if (((Ehp15::c 'file') ne '') == ((-c 'file') ne '')) {
    print "ok - 33 Ehp15::c 'file' == -c 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 33 Ehp15::c 'file' == -c 'file' $^X $__FILE__\n";
}

if (((Ehp15::c FILE) ne '') == ((-c FILE) ne '')) {
    print "ok - 34 Ehp15::c FILE == -c FILE $^X $__FILE__\n";
}
else {
    print "not ok - 34 Ehp15::c FILE == -c FILE $^X $__FILE__\n";
}

if (((Ehp15::u 'file') ne '') == ((-u 'file') ne '')) {
    print "ok - 35 Ehp15::u 'file' == -u 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 35 Ehp15::u 'file' == -u 'file' $^X $__FILE__\n";
}

if (((Ehp15::u FILE) ne '') == ((-u FILE) ne '')) {
    print "ok - 36 Ehp15::u FILE == -u FILE $^X $__FILE__\n";
}
else {
    print "not ok - 36 Ehp15::u FILE == -u FILE $^X $__FILE__\n";
}

if (((Ehp15::g 'file') ne '') == ((-g 'file') ne '')) {
    print "ok - 37 Ehp15::g 'file' == -g 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 37 Ehp15::g 'file' == -g 'file' $^X $__FILE__\n";
}

if (((Ehp15::g FILE) ne '') == ((-g FILE) ne '')) {
    print "ok - 38 Ehp15::g FILE == -g FILE $^X $__FILE__\n";
}
else {
    print "not ok - 38 Ehp15::g FILE == -g FILE $^X $__FILE__\n";
}

if (((Ehp15::T 'file') ne '') == ((-T 'file') ne '')) {
    print "ok - 39 Ehp15::T 'file' == -T 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 39 Ehp15::T 'file' == -T 'file' $^X $__FILE__\n";
}

if (((Ehp15::T FILE) ne '') == ((-T FILE) ne '')) {
    print "ok - 40 Ehp15::T FILE == -T FILE $^X $__FILE__\n";
}
else {
    print "not ok - 40 Ehp15::T FILE == -T FILE $^X $__FILE__\n";
}

if (((Ehp15::B 'file') ne '') == ((-B 'file') ne '')) {
    print "ok - 41 Ehp15::B 'file' == -B 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 41 Ehp15::B 'file' == -B 'file' $^X $__FILE__\n";
}

if (((Ehp15::B FILE) ne '') == ((-B FILE) ne '')) {
    print "ok - 42 Ehp15::B FILE == -B FILE $^X $__FILE__\n";
}
else {
    print "not ok - 42 Ehp15::B FILE == -B FILE $^X $__FILE__\n";
}

if (((Ehp15::M 'file') ne '') == ((-M 'file') ne '')) {
    print "ok - 43 Ehp15::M 'file' == -M 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 43 Ehp15::M 'file' == -M 'file' $^X $__FILE__\n";
}

if (((Ehp15::M FILE) ne '') == ((-M FILE) ne '')) {
    print "ok - 44 Ehp15::M FILE == -M FILE $^X $__FILE__\n";
}
else {
    print "not ok - 44 Ehp15::M FILE == -M FILE $^X $__FILE__\n";
}

if (((Ehp15::A 'file') ne '') == ((-A 'file') ne '')) {
    print "ok - 45 Ehp15::A 'file' == -A 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 45 Ehp15::A 'file' == -A 'file' $^X $__FILE__\n";
}

if (((Ehp15::A FILE) ne '') == ((-A FILE) ne '')) {
    print "ok - 46 Ehp15::A FILE == -A FILE $^X $__FILE__\n";
}
else {
    print "not ok - 46 Ehp15::A FILE == -A FILE $^X $__FILE__\n";
}

if (((Ehp15::C 'file') ne '') == ((-C 'file') ne '')) {
    print "ok - 47 Ehp15::C 'file' == -C 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 47 Ehp15::C 'file' == -C 'file' $^X $__FILE__\n";
}

if (((Ehp15::C FILE) ne '') == ((-C FILE) ne '')) {
    print "ok - 48 Ehp15::C FILE == -C FILE $^X $__FILE__\n";
}
else {
    print "not ok - 48 Ehp15::C FILE == -C FILE $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
