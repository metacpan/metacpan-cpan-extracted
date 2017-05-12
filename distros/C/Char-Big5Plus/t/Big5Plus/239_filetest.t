# encoding: Big5Plus
# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{あ} ne "\x82\xa0";

# Ebig5plus::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト(対象はディレクトリ)

my $__FILE__ = __FILE__;

use Ebig5plus;
print "1..22\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..22) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

mkdir('directory',0777);

opendir(DIR,'directory');

if (((Ebig5plus::r 'directory') ne '') == ((-r 'directory') ne '')) {
    print "ok - 1 Ebig5plus::r 'directory' == -r 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Ebig5plus::r 'directory' == -r 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::w 'directory') ne '') == ((-w 'directory') ne '')) {
    print "ok - 2 Ebig5plus::w 'directory' == -w 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 2 Ebig5plus::w 'directory' == -w 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::x 'directory') ne '') == ((-x 'directory') ne '')) {
    print "ok - 3 Ebig5plus::x 'directory' == -x 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Ebig5plus::x 'directory' == -x 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::o 'directory') ne '') == ((-o 'directory') ne '')) {
    print "ok - 4 Ebig5plus::o 'directory' == -o 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 4 Ebig5plus::o 'directory' == -o 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::R 'directory') ne '') == ((-R 'directory') ne '')) {
    print "ok - 5 Ebig5plus::R 'directory' == -R 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Ebig5plus::R 'directory' == -R 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::W 'directory') ne '') == ((-W 'directory') ne '')) {
    print "ok - 6 Ebig5plus::W 'directory' == -W 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 6 Ebig5plus::W 'directory' == -W 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::X 'directory') ne '') == ((-X 'directory') ne '')) {
    print "ok - 7 Ebig5plus::X 'directory' == -X 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Ebig5plus::X 'directory' == -X 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::O 'directory') ne '') == ((-O 'directory') ne '')) {
    print "ok - 8 Ebig5plus::O 'directory' == -O 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 8 Ebig5plus::O 'directory' == -O 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::e 'directory') ne '') == ((-e 'directory') ne '')) {
    print "ok - 9 Ebig5plus::e 'directory' == -e 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Ebig5plus::e 'directory' == -e 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::z 'directory') ne '') == ((-z 'directory') ne '')) {
    print "ok - 10 Ebig5plus::z 'directory' == -z 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 10 Ebig5plus::z 'directory' == -z 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::s 'directory') ne '') == ((-s 'directory') ne '')) {
    print "ok - 11 Ebig5plus::s 'directory' == -s 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ebig5plus::s 'directory' == -s 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::f 'directory') ne '') == ((-f 'directory') ne '')) {
    print "ok - 12 Ebig5plus::f 'directory' == -f 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 12 Ebig5plus::f 'directory' == -f 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::d 'directory') ne '') == ((-d 'directory') ne '')) {
    print "ok - 13 Ebig5plus::d 'directory' == -d 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Ebig5plus::d 'directory' == -d 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::p 'directory') ne '') == ((-p 'directory') ne '')) {
    print "ok - 14 Ebig5plus::p 'directory' == -p 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 14 Ebig5plus::p 'directory' == -p 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::S 'directory') ne '') == ((-S 'directory') ne '')) {
    print "ok - 15 Ebig5plus::S 'directory' == -S 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Ebig5plus::S 'directory' == -S 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::b 'directory') ne '') == ((-b 'directory') ne '')) {
    print "ok - 16 Ebig5plus::b 'directory' == -b 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 16 Ebig5plus::b 'directory' == -b 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::c 'directory') ne '') == ((-c 'directory') ne '')) {
    print "ok - 17 Ebig5plus::c 'directory' == -c 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Ebig5plus::c 'directory' == -c 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::u 'directory') ne '') == ((-u 'directory') ne '')) {
    print "ok - 18 Ebig5plus::u 'directory' == -u 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 18 Ebig5plus::u 'directory' == -u 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::g 'directory') ne '') == ((-g 'directory') ne '')) {
    print "ok - 19 Ebig5plus::g 'directory' == -g 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Ebig5plus::g 'directory' == -g 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::M 'directory') ne '') == ((-M 'directory') ne '')) {
    print "ok - 20 Ebig5plus::M 'directory' == -M 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 20 Ebig5plus::M 'directory' == -M 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::A 'directory') ne '') == ((-A 'directory') ne '')) {
    print "ok - 21 Ebig5plus::A 'directory' == -A 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ebig5plus::A 'directory' == -A 'directory' $^X $__FILE__\n";
}

if (((Ebig5plus::C 'directory') ne '') == ((-C 'directory') ne '')) {
    print "ok - 22 Ebig5plus::C 'directory' == -C 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ebig5plus::C 'directory' == -C 'directory' $^X $__FILE__\n";
}

closedir(DIR);
rmdir('directory');

__END__
