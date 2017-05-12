# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

# Esjis::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト(対象はディレクトリ)

my $__FILE__ = __FILE__;

use Esjis;
print "1..22\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..22) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

mkdir('directory',0777);

opendir(DIR,'directory');

if (((Esjis::r 'directory') ne '') == ((-r 'directory') ne '')) {
    print "ok - 1 Esjis::r 'directory' == -r 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Esjis::r 'directory' == -r 'directory' $^X $__FILE__\n";
}

if (((Esjis::w 'directory') ne '') == ((-w 'directory') ne '')) {
    print "ok - 2 Esjis::w 'directory' == -w 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 2 Esjis::w 'directory' == -w 'directory' $^X $__FILE__\n";
}

if (((Esjis::x 'directory') ne '') == ((-x 'directory') ne '')) {
    print "ok - 3 Esjis::x 'directory' == -x 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Esjis::x 'directory' == -x 'directory' $^X $__FILE__\n";
}

if (((Esjis::o 'directory') ne '') == ((-o 'directory') ne '')) {
    print "ok - 4 Esjis::o 'directory' == -o 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 4 Esjis::o 'directory' == -o 'directory' $^X $__FILE__\n";
}

if (((Esjis::R 'directory') ne '') == ((-R 'directory') ne '')) {
    print "ok - 5 Esjis::R 'directory' == -R 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Esjis::R 'directory' == -R 'directory' $^X $__FILE__\n";
}

if (((Esjis::W 'directory') ne '') == ((-W 'directory') ne '')) {
    print "ok - 6 Esjis::W 'directory' == -W 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 6 Esjis::W 'directory' == -W 'directory' $^X $__FILE__\n";
}

if (((Esjis::X 'directory') ne '') == ((-X 'directory') ne '')) {
    print "ok - 7 Esjis::X 'directory' == -X 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Esjis::X 'directory' == -X 'directory' $^X $__FILE__\n";
}

if (((Esjis::O 'directory') ne '') == ((-O 'directory') ne '')) {
    print "ok - 8 Esjis::O 'directory' == -O 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 8 Esjis::O 'directory' == -O 'directory' $^X $__FILE__\n";
}

if (((Esjis::e 'directory') ne '') == ((-e 'directory') ne '')) {
    print "ok - 9 Esjis::e 'directory' == -e 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Esjis::e 'directory' == -e 'directory' $^X $__FILE__\n";
}

if (((Esjis::z 'directory') ne '') == ((-z 'directory') ne '')) {
    print "ok - 10 Esjis::z 'directory' == -z 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 10 Esjis::z 'directory' == -z 'directory' $^X $__FILE__\n";
}

if (((Esjis::s 'directory') ne '') == ((-s 'directory') ne '')) {
    print "ok - 11 Esjis::s 'directory' == -s 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Esjis::s 'directory' == -s 'directory' $^X $__FILE__\n";
}

if (((Esjis::f 'directory') ne '') == ((-f 'directory') ne '')) {
    print "ok - 12 Esjis::f 'directory' == -f 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 12 Esjis::f 'directory' == -f 'directory' $^X $__FILE__\n";
}

if (((Esjis::d 'directory') ne '') == ((-d 'directory') ne '')) {
    print "ok - 13 Esjis::d 'directory' == -d 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Esjis::d 'directory' == -d 'directory' $^X $__FILE__\n";
}

if (((Esjis::p 'directory') ne '') == ((-p 'directory') ne '')) {
    print "ok - 14 Esjis::p 'directory' == -p 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 14 Esjis::p 'directory' == -p 'directory' $^X $__FILE__\n";
}

if (((Esjis::S 'directory') ne '') == ((-S 'directory') ne '')) {
    print "ok - 15 Esjis::S 'directory' == -S 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Esjis::S 'directory' == -S 'directory' $^X $__FILE__\n";
}

if (((Esjis::b 'directory') ne '') == ((-b 'directory') ne '')) {
    print "ok - 16 Esjis::b 'directory' == -b 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 16 Esjis::b 'directory' == -b 'directory' $^X $__FILE__\n";
}

if (((Esjis::c 'directory') ne '') == ((-c 'directory') ne '')) {
    print "ok - 17 Esjis::c 'directory' == -c 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Esjis::c 'directory' == -c 'directory' $^X $__FILE__\n";
}

if (((Esjis::u 'directory') ne '') == ((-u 'directory') ne '')) {
    print "ok - 18 Esjis::u 'directory' == -u 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 18 Esjis::u 'directory' == -u 'directory' $^X $__FILE__\n";
}

if (((Esjis::g 'directory') ne '') == ((-g 'directory') ne '')) {
    print "ok - 19 Esjis::g 'directory' == -g 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Esjis::g 'directory' == -g 'directory' $^X $__FILE__\n";
}

if (((Esjis::M 'directory') ne '') == ((-M 'directory') ne '')) {
    print "ok - 20 Esjis::M 'directory' == -M 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 20 Esjis::M 'directory' == -M 'directory' $^X $__FILE__\n";
}

if (((Esjis::A 'directory') ne '') == ((-A 'directory') ne '')) {
    print "ok - 21 Esjis::A 'directory' == -A 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Esjis::A 'directory' == -A 'directory' $^X $__FILE__\n";
}

if (((Esjis::C 'directory') ne '') == ((-C 'directory') ne '')) {
    print "ok - 22 Esjis::C 'directory' == -C 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 22 Esjis::C 'directory' == -C 'directory' $^X $__FILE__\n";
}

closedir(DIR);
rmdir('directory');

__END__
