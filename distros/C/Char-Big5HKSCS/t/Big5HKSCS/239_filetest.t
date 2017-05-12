# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{あ} ne "\x82\xa0";

# Ebig5hkscs::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト(対象はディレクトリ)

my $__FILE__ = __FILE__;

use Ebig5hkscs;
print "1..22\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..22) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

mkdir('directory',0777);

opendir(DIR,'directory');

if (((Ebig5hkscs::r 'directory') ne '') == ((-r 'directory') ne '')) {
    print "ok - 1 Ebig5hkscs::r 'directory' == -r 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Ebig5hkscs::r 'directory' == -r 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::w 'directory') ne '') == ((-w 'directory') ne '')) {
    print "ok - 2 Ebig5hkscs::w 'directory' == -w 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 2 Ebig5hkscs::w 'directory' == -w 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::x 'directory') ne '') == ((-x 'directory') ne '')) {
    print "ok - 3 Ebig5hkscs::x 'directory' == -x 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Ebig5hkscs::x 'directory' == -x 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::o 'directory') ne '') == ((-o 'directory') ne '')) {
    print "ok - 4 Ebig5hkscs::o 'directory' == -o 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 4 Ebig5hkscs::o 'directory' == -o 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::R 'directory') ne '') == ((-R 'directory') ne '')) {
    print "ok - 5 Ebig5hkscs::R 'directory' == -R 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Ebig5hkscs::R 'directory' == -R 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::W 'directory') ne '') == ((-W 'directory') ne '')) {
    print "ok - 6 Ebig5hkscs::W 'directory' == -W 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 6 Ebig5hkscs::W 'directory' == -W 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::X 'directory') ne '') == ((-X 'directory') ne '')) {
    print "ok - 7 Ebig5hkscs::X 'directory' == -X 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Ebig5hkscs::X 'directory' == -X 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::O 'directory') ne '') == ((-O 'directory') ne '')) {
    print "ok - 8 Ebig5hkscs::O 'directory' == -O 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 8 Ebig5hkscs::O 'directory' == -O 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::e 'directory') ne '') == ((-e 'directory') ne '')) {
    print "ok - 9 Ebig5hkscs::e 'directory' == -e 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Ebig5hkscs::e 'directory' == -e 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::z 'directory') ne '') == ((-z 'directory') ne '')) {
    print "ok - 10 Ebig5hkscs::z 'directory' == -z 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 10 Ebig5hkscs::z 'directory' == -z 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::s 'directory') ne '') == ((-s 'directory') ne '')) {
    print "ok - 11 Ebig5hkscs::s 'directory' == -s 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ebig5hkscs::s 'directory' == -s 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::f 'directory') ne '') == ((-f 'directory') ne '')) {
    print "ok - 12 Ebig5hkscs::f 'directory' == -f 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 12 Ebig5hkscs::f 'directory' == -f 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::d 'directory') ne '') == ((-d 'directory') ne '')) {
    print "ok - 13 Ebig5hkscs::d 'directory' == -d 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Ebig5hkscs::d 'directory' == -d 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::p 'directory') ne '') == ((-p 'directory') ne '')) {
    print "ok - 14 Ebig5hkscs::p 'directory' == -p 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 14 Ebig5hkscs::p 'directory' == -p 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::S 'directory') ne '') == ((-S 'directory') ne '')) {
    print "ok - 15 Ebig5hkscs::S 'directory' == -S 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Ebig5hkscs::S 'directory' == -S 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::b 'directory') ne '') == ((-b 'directory') ne '')) {
    print "ok - 16 Ebig5hkscs::b 'directory' == -b 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 16 Ebig5hkscs::b 'directory' == -b 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::c 'directory') ne '') == ((-c 'directory') ne '')) {
    print "ok - 17 Ebig5hkscs::c 'directory' == -c 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Ebig5hkscs::c 'directory' == -c 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::u 'directory') ne '') == ((-u 'directory') ne '')) {
    print "ok - 18 Ebig5hkscs::u 'directory' == -u 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 18 Ebig5hkscs::u 'directory' == -u 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::g 'directory') ne '') == ((-g 'directory') ne '')) {
    print "ok - 19 Ebig5hkscs::g 'directory' == -g 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Ebig5hkscs::g 'directory' == -g 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::M 'directory') ne '') == ((-M 'directory') ne '')) {
    print "ok - 20 Ebig5hkscs::M 'directory' == -M 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 20 Ebig5hkscs::M 'directory' == -M 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::A 'directory') ne '') == ((-A 'directory') ne '')) {
    print "ok - 21 Ebig5hkscs::A 'directory' == -A 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ebig5hkscs::A 'directory' == -A 'directory' $^X $__FILE__\n";
}

if (((Ebig5hkscs::C 'directory') ne '') == ((-C 'directory') ne '')) {
    print "ok - 22 Ebig5hkscs::C 'directory' == -C 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ebig5hkscs::C 'directory' == -C 'directory' $^X $__FILE__\n";
}

closedir(DIR);
rmdir('directory');

__END__
