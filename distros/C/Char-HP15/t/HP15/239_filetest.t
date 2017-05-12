# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{あ} ne "\x82\xa0";

# Ehp15::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト(対象はディレクトリ)

my $__FILE__ = __FILE__;

use Ehp15;
print "1..22\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..22) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

mkdir('directory',0777);

opendir(DIR,'directory');

if (((Ehp15::r 'directory') ne '') == ((-r 'directory') ne '')) {
    print "ok - 1 Ehp15::r 'directory' == -r 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Ehp15::r 'directory' == -r 'directory' $^X $__FILE__\n";
}

if (((Ehp15::w 'directory') ne '') == ((-w 'directory') ne '')) {
    print "ok - 2 Ehp15::w 'directory' == -w 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 2 Ehp15::w 'directory' == -w 'directory' $^X $__FILE__\n";
}

if (((Ehp15::x 'directory') ne '') == ((-x 'directory') ne '')) {
    print "ok - 3 Ehp15::x 'directory' == -x 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Ehp15::x 'directory' == -x 'directory' $^X $__FILE__\n";
}

if (((Ehp15::o 'directory') ne '') == ((-o 'directory') ne '')) {
    print "ok - 4 Ehp15::o 'directory' == -o 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 4 Ehp15::o 'directory' == -o 'directory' $^X $__FILE__\n";
}

if (((Ehp15::R 'directory') ne '') == ((-R 'directory') ne '')) {
    print "ok - 5 Ehp15::R 'directory' == -R 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Ehp15::R 'directory' == -R 'directory' $^X $__FILE__\n";
}

if (((Ehp15::W 'directory') ne '') == ((-W 'directory') ne '')) {
    print "ok - 6 Ehp15::W 'directory' == -W 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 6 Ehp15::W 'directory' == -W 'directory' $^X $__FILE__\n";
}

if (((Ehp15::X 'directory') ne '') == ((-X 'directory') ne '')) {
    print "ok - 7 Ehp15::X 'directory' == -X 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Ehp15::X 'directory' == -X 'directory' $^X $__FILE__\n";
}

if (((Ehp15::O 'directory') ne '') == ((-O 'directory') ne '')) {
    print "ok - 8 Ehp15::O 'directory' == -O 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 8 Ehp15::O 'directory' == -O 'directory' $^X $__FILE__\n";
}

if (((Ehp15::e 'directory') ne '') == ((-e 'directory') ne '')) {
    print "ok - 9 Ehp15::e 'directory' == -e 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Ehp15::e 'directory' == -e 'directory' $^X $__FILE__\n";
}

if (((Ehp15::z 'directory') ne '') == ((-z 'directory') ne '')) {
    print "ok - 10 Ehp15::z 'directory' == -z 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 10 Ehp15::z 'directory' == -z 'directory' $^X $__FILE__\n";
}

if (((Ehp15::s 'directory') ne '') == ((-s 'directory') ne '')) {
    print "ok - 11 Ehp15::s 'directory' == -s 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ehp15::s 'directory' == -s 'directory' $^X $__FILE__\n";
}

if (((Ehp15::f 'directory') ne '') == ((-f 'directory') ne '')) {
    print "ok - 12 Ehp15::f 'directory' == -f 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 12 Ehp15::f 'directory' == -f 'directory' $^X $__FILE__\n";
}

if (((Ehp15::d 'directory') ne '') == ((-d 'directory') ne '')) {
    print "ok - 13 Ehp15::d 'directory' == -d 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Ehp15::d 'directory' == -d 'directory' $^X $__FILE__\n";
}

if (((Ehp15::p 'directory') ne '') == ((-p 'directory') ne '')) {
    print "ok - 14 Ehp15::p 'directory' == -p 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 14 Ehp15::p 'directory' == -p 'directory' $^X $__FILE__\n";
}

if (((Ehp15::S 'directory') ne '') == ((-S 'directory') ne '')) {
    print "ok - 15 Ehp15::S 'directory' == -S 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Ehp15::S 'directory' == -S 'directory' $^X $__FILE__\n";
}

if (((Ehp15::b 'directory') ne '') == ((-b 'directory') ne '')) {
    print "ok - 16 Ehp15::b 'directory' == -b 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 16 Ehp15::b 'directory' == -b 'directory' $^X $__FILE__\n";
}

if (((Ehp15::c 'directory') ne '') == ((-c 'directory') ne '')) {
    print "ok - 17 Ehp15::c 'directory' == -c 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Ehp15::c 'directory' == -c 'directory' $^X $__FILE__\n";
}

if (((Ehp15::u 'directory') ne '') == ((-u 'directory') ne '')) {
    print "ok - 18 Ehp15::u 'directory' == -u 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 18 Ehp15::u 'directory' == -u 'directory' $^X $__FILE__\n";
}

if (((Ehp15::g 'directory') ne '') == ((-g 'directory') ne '')) {
    print "ok - 19 Ehp15::g 'directory' == -g 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Ehp15::g 'directory' == -g 'directory' $^X $__FILE__\n";
}

if (((Ehp15::M 'directory') ne '') == ((-M 'directory') ne '')) {
    print "ok - 20 Ehp15::M 'directory' == -M 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 20 Ehp15::M 'directory' == -M 'directory' $^X $__FILE__\n";
}

if (((Ehp15::A 'directory') ne '') == ((-A 'directory') ne '')) {
    print "ok - 21 Ehp15::A 'directory' == -A 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ehp15::A 'directory' == -A 'directory' $^X $__FILE__\n";
}

if (((Ehp15::C 'directory') ne '') == ((-C 'directory') ne '')) {
    print "ok - 22 Ehp15::C 'directory' == -C 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ehp15::C 'directory' == -C 'directory' $^X $__FILE__\n";
}

closedir(DIR);
rmdir('directory');

__END__
