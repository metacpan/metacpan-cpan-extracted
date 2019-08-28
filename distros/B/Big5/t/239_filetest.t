# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{あ} ne "\x82\xa0";

# Ebig5::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト(対象はディレクトリ)

my $__FILE__ = __FILE__;

use Ebig5;
print "1..22\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..22) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

mkdir('directory',0777);

opendir(DIR,'directory');

if (((Ebig5::r 'directory') ne '') == ((-r 'directory') ne '')) {
    print "ok - 1 Ebig5::r 'directory' == -r 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Ebig5::r 'directory' == -r 'directory' $^X $__FILE__\n";
}

if (((Ebig5::w 'directory') ne '') == ((-w 'directory') ne '')) {
    print "ok - 2 Ebig5::w 'directory' == -w 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 2 Ebig5::w 'directory' == -w 'directory' $^X $__FILE__\n";
}

if (((Ebig5::x 'directory') ne '') == ((-x 'directory') ne '')) {
    print "ok - 3 Ebig5::x 'directory' == -x 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Ebig5::x 'directory' == -x 'directory' $^X $__FILE__\n";
}

if (((Ebig5::o 'directory') ne '') == ((-o 'directory') ne '')) {
    print "ok - 4 Ebig5::o 'directory' == -o 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 4 Ebig5::o 'directory' == -o 'directory' $^X $__FILE__\n";
}

if (((Ebig5::R 'directory') ne '') == ((-R 'directory') ne '')) {
    print "ok - 5 Ebig5::R 'directory' == -R 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Ebig5::R 'directory' == -R 'directory' $^X $__FILE__\n";
}

if (((Ebig5::W 'directory') ne '') == ((-W 'directory') ne '')) {
    print "ok - 6 Ebig5::W 'directory' == -W 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 6 Ebig5::W 'directory' == -W 'directory' $^X $__FILE__\n";
}

if (((Ebig5::X 'directory') ne '') == ((-X 'directory') ne '')) {
    print "ok - 7 Ebig5::X 'directory' == -X 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Ebig5::X 'directory' == -X 'directory' $^X $__FILE__\n";
}

if (((Ebig5::O 'directory') ne '') == ((-O 'directory') ne '')) {
    print "ok - 8 Ebig5::O 'directory' == -O 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 8 Ebig5::O 'directory' == -O 'directory' $^X $__FILE__\n";
}

if (((Ebig5::e 'directory') ne '') == ((-e 'directory') ne '')) {
    print "ok - 9 Ebig5::e 'directory' == -e 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Ebig5::e 'directory' == -e 'directory' $^X $__FILE__\n";
}

if (((Ebig5::z 'directory') ne '') == ((-z 'directory') ne '')) {
    print "ok - 10 Ebig5::z 'directory' == -z 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 10 Ebig5::z 'directory' == -z 'directory' $^X $__FILE__\n";
}

if (((Ebig5::s 'directory') ne '') == ((-s 'directory') ne '')) {
    print "ok - 11 Ebig5::s 'directory' == -s 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ebig5::s 'directory' == -s 'directory' $^X $__FILE__\n";
}

if (((Ebig5::f 'directory') ne '') == ((-f 'directory') ne '')) {
    print "ok - 12 Ebig5::f 'directory' == -f 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 12 Ebig5::f 'directory' == -f 'directory' $^X $__FILE__\n";
}

if (((Ebig5::d 'directory') ne '') == ((-d 'directory') ne '')) {
    print "ok - 13 Ebig5::d 'directory' == -d 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Ebig5::d 'directory' == -d 'directory' $^X $__FILE__\n";
}

if (((Ebig5::p 'directory') ne '') == ((-p 'directory') ne '')) {
    print "ok - 14 Ebig5::p 'directory' == -p 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 14 Ebig5::p 'directory' == -p 'directory' $^X $__FILE__\n";
}

if (((Ebig5::S 'directory') ne '') == ((-S 'directory') ne '')) {
    print "ok - 15 Ebig5::S 'directory' == -S 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Ebig5::S 'directory' == -S 'directory' $^X $__FILE__\n";
}

if (((Ebig5::b 'directory') ne '') == ((-b 'directory') ne '')) {
    print "ok - 16 Ebig5::b 'directory' == -b 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 16 Ebig5::b 'directory' == -b 'directory' $^X $__FILE__\n";
}

if (((Ebig5::c 'directory') ne '') == ((-c 'directory') ne '')) {
    print "ok - 17 Ebig5::c 'directory' == -c 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Ebig5::c 'directory' == -c 'directory' $^X $__FILE__\n";
}

if (((Ebig5::u 'directory') ne '') == ((-u 'directory') ne '')) {
    print "ok - 18 Ebig5::u 'directory' == -u 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 18 Ebig5::u 'directory' == -u 'directory' $^X $__FILE__\n";
}

if (((Ebig5::g 'directory') ne '') == ((-g 'directory') ne '')) {
    print "ok - 19 Ebig5::g 'directory' == -g 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Ebig5::g 'directory' == -g 'directory' $^X $__FILE__\n";
}

if (((Ebig5::M 'directory') ne '') == ((-M 'directory') ne '')) {
    print "ok - 20 Ebig5::M 'directory' == -M 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 20 Ebig5::M 'directory' == -M 'directory' $^X $__FILE__\n";
}

if (((Ebig5::A 'directory') ne '') == ((-A 'directory') ne '')) {
    print "ok - 21 Ebig5::A 'directory' == -A 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ebig5::A 'directory' == -A 'directory' $^X $__FILE__\n";
}

if (((Ebig5::C 'directory') ne '') == ((-C 'directory') ne '')) {
    print "ok - 22 Ebig5::C 'directory' == -C 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ebig5::C 'directory' == -C 'directory' $^X $__FILE__\n";
}

closedir(DIR);
rmdir('directory');

__END__
