# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

# Einformixv6als::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト(対象はディレクトリ)

my $__FILE__ = __FILE__;

use Einformixv6als;
print "1..22\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..22) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

mkdir('directory',0777);

opendir(DIR,'directory');

if (((Einformixv6als::r 'directory') ne '') == ((-r 'directory') ne '')) {
    print "ok - 1 Einformixv6als::r 'directory' == -r 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Einformixv6als::r 'directory' == -r 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::w 'directory') ne '') == ((-w 'directory') ne '')) {
    print "ok - 2 Einformixv6als::w 'directory' == -w 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 2 Einformixv6als::w 'directory' == -w 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::x 'directory') ne '') == ((-x 'directory') ne '')) {
    print "ok - 3 Einformixv6als::x 'directory' == -x 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Einformixv6als::x 'directory' == -x 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::o 'directory') ne '') == ((-o 'directory') ne '')) {
    print "ok - 4 Einformixv6als::o 'directory' == -o 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 4 Einformixv6als::o 'directory' == -o 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::R 'directory') ne '') == ((-R 'directory') ne '')) {
    print "ok - 5 Einformixv6als::R 'directory' == -R 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Einformixv6als::R 'directory' == -R 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::W 'directory') ne '') == ((-W 'directory') ne '')) {
    print "ok - 6 Einformixv6als::W 'directory' == -W 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 6 Einformixv6als::W 'directory' == -W 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::X 'directory') ne '') == ((-X 'directory') ne '')) {
    print "ok - 7 Einformixv6als::X 'directory' == -X 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Einformixv6als::X 'directory' == -X 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::O 'directory') ne '') == ((-O 'directory') ne '')) {
    print "ok - 8 Einformixv6als::O 'directory' == -O 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 8 Einformixv6als::O 'directory' == -O 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::e 'directory') ne '') == ((-e 'directory') ne '')) {
    print "ok - 9 Einformixv6als::e 'directory' == -e 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Einformixv6als::e 'directory' == -e 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::z 'directory') ne '') == ((-z 'directory') ne '')) {
    print "ok - 10 Einformixv6als::z 'directory' == -z 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 10 Einformixv6als::z 'directory' == -z 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::s 'directory') ne '') == ((-s 'directory') ne '')) {
    print "ok - 11 Einformixv6als::s 'directory' == -s 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Einformixv6als::s 'directory' == -s 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::f 'directory') ne '') == ((-f 'directory') ne '')) {
    print "ok - 12 Einformixv6als::f 'directory' == -f 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 12 Einformixv6als::f 'directory' == -f 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::d 'directory') ne '') == ((-d 'directory') ne '')) {
    print "ok - 13 Einformixv6als::d 'directory' == -d 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Einformixv6als::d 'directory' == -d 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::p 'directory') ne '') == ((-p 'directory') ne '')) {
    print "ok - 14 Einformixv6als::p 'directory' == -p 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 14 Einformixv6als::p 'directory' == -p 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::S 'directory') ne '') == ((-S 'directory') ne '')) {
    print "ok - 15 Einformixv6als::S 'directory' == -S 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Einformixv6als::S 'directory' == -S 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::b 'directory') ne '') == ((-b 'directory') ne '')) {
    print "ok - 16 Einformixv6als::b 'directory' == -b 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 16 Einformixv6als::b 'directory' == -b 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::c 'directory') ne '') == ((-c 'directory') ne '')) {
    print "ok - 17 Einformixv6als::c 'directory' == -c 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Einformixv6als::c 'directory' == -c 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::u 'directory') ne '') == ((-u 'directory') ne '')) {
    print "ok - 18 Einformixv6als::u 'directory' == -u 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 18 Einformixv6als::u 'directory' == -u 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::g 'directory') ne '') == ((-g 'directory') ne '')) {
    print "ok - 19 Einformixv6als::g 'directory' == -g 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Einformixv6als::g 'directory' == -g 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::M 'directory') ne '') == ((-M 'directory') ne '')) {
    print "ok - 20 Einformixv6als::M 'directory' == -M 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 20 Einformixv6als::M 'directory' == -M 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::A 'directory') ne '') == ((-A 'directory') ne '')) {
    print "ok - 21 Einformixv6als::A 'directory' == -A 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Einformixv6als::A 'directory' == -A 'directory' $^X $__FILE__\n";
}

if (((Einformixv6als::C 'directory') ne '') == ((-C 'directory') ne '')) {
    print "ok - 22 Einformixv6als::C 'directory' == -C 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 22 Einformixv6als::C 'directory' == -C 'directory' $^X $__FILE__\n";
}

closedir(DIR);
rmdir('directory');

__END__
