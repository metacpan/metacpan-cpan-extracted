# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

# Einformixv6als::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト

my $__FILE__ = __FILE__;

use Einformixv6als;
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

if (((Einformixv6als::r 'file') ne '') == ((-r 'file') ne '')) {
    print "ok - 1 Einformixv6als::r 'file' == -r 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Einformixv6als::r 'file' == -r 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::r FILE) ne '') == ((-r FILE) ne '')) {
    print "ok - 2 Einformixv6als::r FILE == -r FILE $^X $__FILE__\n";
}
else {
    print "not ok - 2 Einformixv6als::r FILE == -r FILE $^X $__FILE__\n";
}

if (((Einformixv6als::w 'file') ne '') == ((-w 'file') ne '')) {
    print "ok - 3 Einformixv6als::w 'file' == -w 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Einformixv6als::w 'file' == -w 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::w FILE) ne '') == ((-w FILE) ne '')) {
    print "ok - 4 Einformixv6als::w FILE == -w FILE $^X $__FILE__\n";
}
else {
    print "not ok - 4 Einformixv6als::w FILE == -w FILE $^X $__FILE__\n";
}

if (((Einformixv6als::x 'file') ne '') == ((-x 'file') ne '')) {
    print "ok - 5 Einformixv6als::x 'file' == -x 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Einformixv6als::x 'file' == -x 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::x FILE) ne '') == ((-x FILE) ne '')) {
    print "ok - 6 Einformixv6als::x FILE == -x FILE $^X $__FILE__\n";
}
else {
    print "not ok - 6 Einformixv6als::x FILE == -x FILE $^X $__FILE__\n";
}

if (((Einformixv6als::o 'file') ne '') == ((-o 'file') ne '')) {
    print "ok - 7 Einformixv6als::o 'file' == -o 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Einformixv6als::o 'file' == -o 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::o FILE) ne '') == ((-o FILE) ne '')) {
    print "ok - 8 Einformixv6als::o FILE == -o FILE $^X $__FILE__\n";
}
else {
    print "not ok - 8 Einformixv6als::o FILE == -o FILE $^X $__FILE__\n";
}

if (((Einformixv6als::R 'file') ne '') == ((-R 'file') ne '')) {
    print "ok - 9 Einformixv6als::R 'file' == -R 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Einformixv6als::R 'file' == -R 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::R FILE) ne '') == ((-R FILE) ne '')) {
    print "ok - 10 Einformixv6als::R FILE == -R FILE $^X $__FILE__\n";
}
else {
    print "not ok - 10 Einformixv6als::R FILE == -R FILE $^X $__FILE__\n";
}

if (((Einformixv6als::W 'file') ne '') == ((-W 'file') ne '')) {
    print "ok - 11 Einformixv6als::W 'file' == -W 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Einformixv6als::W 'file' == -W 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::W FILE) ne '') == ((-W FILE) ne '')) {
    print "ok - 12 Einformixv6als::W FILE == -W FILE $^X $__FILE__\n";
}
else {
    print "not ok - 12 Einformixv6als::W FILE == -W FILE $^X $__FILE__\n";
}

if (((Einformixv6als::X 'file') ne '') == ((-X 'file') ne '')) {
    print "ok - 13 Einformixv6als::X 'file' == -X 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Einformixv6als::X 'file' == -X 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::X FILE) ne '') == ((-X FILE) ne '')) {
    print "ok - 14 Einformixv6als::X FILE == -X FILE $^X $__FILE__\n";
}
else {
    print "not ok - 14 Einformixv6als::X FILE == -X FILE $^X $__FILE__\n";
}

if (((Einformixv6als::O 'file') ne '') == ((-O 'file') ne '')) {
    print "ok - 15 Einformixv6als::O 'file' == -O 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Einformixv6als::O 'file' == -O 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::O FILE) ne '') == ((-O FILE) ne '')) {
    print "ok - 16 Einformixv6als::O FILE == -O FILE $^X $__FILE__\n";
}
else {
    print "not ok - 16 Einformixv6als::O FILE == -O FILE $^X $__FILE__\n";
}

if (((Einformixv6als::e 'file') ne '') == ((-e 'file') ne '')) {
    print "ok - 17 Einformixv6als::e 'file' == -e 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Einformixv6als::e 'file' == -e 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::e FILE) ne '') == ((-e FILE) ne '')) {
    print "ok - 18 Einformixv6als::e FILE == -e FILE $^X $__FILE__\n";
}
else {
    print "not ok - 18 Einformixv6als::e FILE == -e FILE $^X $__FILE__\n";
}

if (((Einformixv6als::z 'file') ne '') == ((-z 'file') ne '')) {
    print "ok - 19 Einformixv6als::z 'file' == -z 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Einformixv6als::z 'file' == -z 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::z FILE) ne '') == ((-z FILE) ne '')) {
    print "ok - 20 Einformixv6als::z FILE == -z FILE $^X $__FILE__\n";
}
else {
    print "not ok - 20 Einformixv6als::z FILE == -z FILE $^X $__FILE__\n";
}

if (((Einformixv6als::s 'file') ne '') == ((-s 'file') ne '')) {
    print "ok - 21 Einformixv6als::s 'file' == -s 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Einformixv6als::s 'file' == -s 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::s FILE) ne '') == ((-s FILE) ne '')) {
    print "ok - 22 Einformixv6als::s FILE == -s FILE $^X $__FILE__\n";
}
else {
    print "not ok - 22 Einformixv6als::s FILE == -s FILE $^X $__FILE__\n";
}

if (((Einformixv6als::f 'file') ne '') == ((-f 'file') ne '')) {
    print "ok - 23 Einformixv6als::f 'file' == -f 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 23 Einformixv6als::f 'file' == -f 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::f FILE) ne '') == ((-f FILE) ne '')) {
    print "ok - 24 Einformixv6als::f FILE == -f FILE $^X $__FILE__\n";
}
else {
    print "not ok - 24 Einformixv6als::f FILE == -f FILE $^X $__FILE__\n";
}

if (((Einformixv6als::d 'file') ne '') == ((-d 'file') ne '')) {
    print "ok - 25 Einformixv6als::d 'file' == -d 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 25 Einformixv6als::d 'file' == -d 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::d FILE) ne '') == ((-d FILE) ne '')) {
    print "ok - 26 Einformixv6als::d FILE == -d FILE $^X $__FILE__\n";
}
else {
    print "not ok - 26 Einformixv6als::d FILE == -d FILE $^X $__FILE__\n";
}

if (((Einformixv6als::p 'file') ne '') == ((-p 'file') ne '')) {
    print "ok - 27 Einformixv6als::p 'file' == -p 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 27 Einformixv6als::p 'file' == -p 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::p FILE) ne '') == ((-p FILE) ne '')) {
    print "ok - 28 Einformixv6als::p FILE == -p FILE $^X $__FILE__\n";
}
else {
    print "not ok - 28 Einformixv6als::p FILE == -p FILE $^X $__FILE__\n";
}

if (((Einformixv6als::S 'file') ne '') == ((-S 'file') ne '')) {
    print "ok - 29 Einformixv6als::S 'file' == -S 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 29 Einformixv6als::S 'file' == -S 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::S FILE) ne '') == ((-S FILE) ne '')) {
    print "ok - 30 Einformixv6als::S FILE == -S FILE $^X $__FILE__\n";
}
else {
    print "not ok - 30 Einformixv6als::S FILE == -S FILE $^X $__FILE__\n";
}

if (((Einformixv6als::b 'file') ne '') == ((-b 'file') ne '')) {
    print "ok - 31 Einformixv6als::b 'file' == -b 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 31 Einformixv6als::b 'file' == -b 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::b FILE) ne '') == ((-b FILE) ne '')) {
    print "ok - 32 Einformixv6als::b FILE == -b FILE $^X $__FILE__\n";
}
else {
    print "not ok - 32 Einformixv6als::b FILE == -b FILE $^X $__FILE__\n";
}

if (((Einformixv6als::c 'file') ne '') == ((-c 'file') ne '')) {
    print "ok - 33 Einformixv6als::c 'file' == -c 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 33 Einformixv6als::c 'file' == -c 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::c FILE) ne '') == ((-c FILE) ne '')) {
    print "ok - 34 Einformixv6als::c FILE == -c FILE $^X $__FILE__\n";
}
else {
    print "not ok - 34 Einformixv6als::c FILE == -c FILE $^X $__FILE__\n";
}

if (((Einformixv6als::u 'file') ne '') == ((-u 'file') ne '')) {
    print "ok - 35 Einformixv6als::u 'file' == -u 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 35 Einformixv6als::u 'file' == -u 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::u FILE) ne '') == ((-u FILE) ne '')) {
    print "ok - 36 Einformixv6als::u FILE == -u FILE $^X $__FILE__\n";
}
else {
    print "not ok - 36 Einformixv6als::u FILE == -u FILE $^X $__FILE__\n";
}

if (((Einformixv6als::g 'file') ne '') == ((-g 'file') ne '')) {
    print "ok - 37 Einformixv6als::g 'file' == -g 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 37 Einformixv6als::g 'file' == -g 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::g FILE) ne '') == ((-g FILE) ne '')) {
    print "ok - 38 Einformixv6als::g FILE == -g FILE $^X $__FILE__\n";
}
else {
    print "not ok - 38 Einformixv6als::g FILE == -g FILE $^X $__FILE__\n";
}

if (((Einformixv6als::T 'file') ne '') == ((-T 'file') ne '')) {
    print "ok - 39 Einformixv6als::T 'file' == -T 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 39 Einformixv6als::T 'file' == -T 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::T FILE) ne '') == ((-T FILE) ne '')) {
    print "ok - 40 Einformixv6als::T FILE == -T FILE $^X $__FILE__\n";
}
else {
    print "not ok - 40 Einformixv6als::T FILE == -T FILE $^X $__FILE__\n";
}

if (((Einformixv6als::B 'file') ne '') == ((-B 'file') ne '')) {
    print "ok - 41 Einformixv6als::B 'file' == -B 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 41 Einformixv6als::B 'file' == -B 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::B FILE) ne '') == ((-B FILE) ne '')) {
    print "ok - 42 Einformixv6als::B FILE == -B FILE $^X $__FILE__\n";
}
else {
    print "not ok - 42 Einformixv6als::B FILE == -B FILE $^X $__FILE__\n";
}

if (((Einformixv6als::M 'file') ne '') == ((-M 'file') ne '')) {
    print "ok - 43 Einformixv6als::M 'file' == -M 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 43 Einformixv6als::M 'file' == -M 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::M FILE) ne '') == ((-M FILE) ne '')) {
    print "ok - 44 Einformixv6als::M FILE == -M FILE $^X $__FILE__\n";
}
else {
    print "not ok - 44 Einformixv6als::M FILE == -M FILE $^X $__FILE__\n";
}

if (((Einformixv6als::A 'file') ne '') == ((-A 'file') ne '')) {
    print "ok - 45 Einformixv6als::A 'file' == -A 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 45 Einformixv6als::A 'file' == -A 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::A FILE) ne '') == ((-A FILE) ne '')) {
    print "ok - 46 Einformixv6als::A FILE == -A FILE $^X $__FILE__\n";
}
else {
    print "not ok - 46 Einformixv6als::A FILE == -A FILE $^X $__FILE__\n";
}

if (((Einformixv6als::C 'file') ne '') == ((-C 'file') ne '')) {
    print "ok - 47 Einformixv6als::C 'file' == -C 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 47 Einformixv6als::C 'file' == -C 'file' $^X $__FILE__\n";
}

if (((Einformixv6als::C FILE) ne '') == ((-C FILE) ne '')) {
    print "ok - 48 Einformixv6als::C FILE == -C FILE $^X $__FILE__\n";
}
else {
    print "not ok - 48 Einformixv6als::C FILE == -C FILE $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
