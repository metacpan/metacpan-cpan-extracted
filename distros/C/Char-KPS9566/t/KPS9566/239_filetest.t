# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{あ} ne "\x82\xa0";

# Ekps9566::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト(対象はディレクトリ)

my $__FILE__ = __FILE__;

use Ekps9566;
print "1..22\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..22) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

mkdir('directory',0777);

opendir(DIR,'directory');

if (((Ekps9566::r 'directory') ne '') == ((-r 'directory') ne '')) {
    print "ok - 1 Ekps9566::r 'directory' == -r 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Ekps9566::r 'directory' == -r 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::w 'directory') ne '') == ((-w 'directory') ne '')) {
    print "ok - 2 Ekps9566::w 'directory' == -w 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 2 Ekps9566::w 'directory' == -w 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::x 'directory') ne '') == ((-x 'directory') ne '')) {
    print "ok - 3 Ekps9566::x 'directory' == -x 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Ekps9566::x 'directory' == -x 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::o 'directory') ne '') == ((-o 'directory') ne '')) {
    print "ok - 4 Ekps9566::o 'directory' == -o 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 4 Ekps9566::o 'directory' == -o 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::R 'directory') ne '') == ((-R 'directory') ne '')) {
    print "ok - 5 Ekps9566::R 'directory' == -R 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Ekps9566::R 'directory' == -R 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::W 'directory') ne '') == ((-W 'directory') ne '')) {
    print "ok - 6 Ekps9566::W 'directory' == -W 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 6 Ekps9566::W 'directory' == -W 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::X 'directory') ne '') == ((-X 'directory') ne '')) {
    print "ok - 7 Ekps9566::X 'directory' == -X 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Ekps9566::X 'directory' == -X 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::O 'directory') ne '') == ((-O 'directory') ne '')) {
    print "ok - 8 Ekps9566::O 'directory' == -O 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 8 Ekps9566::O 'directory' == -O 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::e 'directory') ne '') == ((-e 'directory') ne '')) {
    print "ok - 9 Ekps9566::e 'directory' == -e 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Ekps9566::e 'directory' == -e 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::z 'directory') ne '') == ((-z 'directory') ne '')) {
    print "ok - 10 Ekps9566::z 'directory' == -z 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 10 Ekps9566::z 'directory' == -z 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::s 'directory') ne '') == ((-s 'directory') ne '')) {
    print "ok - 11 Ekps9566::s 'directory' == -s 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ekps9566::s 'directory' == -s 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::f 'directory') ne '') == ((-f 'directory') ne '')) {
    print "ok - 12 Ekps9566::f 'directory' == -f 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 12 Ekps9566::f 'directory' == -f 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::d 'directory') ne '') == ((-d 'directory') ne '')) {
    print "ok - 13 Ekps9566::d 'directory' == -d 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Ekps9566::d 'directory' == -d 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::p 'directory') ne '') == ((-p 'directory') ne '')) {
    print "ok - 14 Ekps9566::p 'directory' == -p 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 14 Ekps9566::p 'directory' == -p 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::S 'directory') ne '') == ((-S 'directory') ne '')) {
    print "ok - 15 Ekps9566::S 'directory' == -S 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Ekps9566::S 'directory' == -S 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::b 'directory') ne '') == ((-b 'directory') ne '')) {
    print "ok - 16 Ekps9566::b 'directory' == -b 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 16 Ekps9566::b 'directory' == -b 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::c 'directory') ne '') == ((-c 'directory') ne '')) {
    print "ok - 17 Ekps9566::c 'directory' == -c 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Ekps9566::c 'directory' == -c 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::u 'directory') ne '') == ((-u 'directory') ne '')) {
    print "ok - 18 Ekps9566::u 'directory' == -u 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 18 Ekps9566::u 'directory' == -u 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::g 'directory') ne '') == ((-g 'directory') ne '')) {
    print "ok - 19 Ekps9566::g 'directory' == -g 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Ekps9566::g 'directory' == -g 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::M 'directory') ne '') == ((-M 'directory') ne '')) {
    print "ok - 20 Ekps9566::M 'directory' == -M 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 20 Ekps9566::M 'directory' == -M 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::A 'directory') ne '') == ((-A 'directory') ne '')) {
    print "ok - 21 Ekps9566::A 'directory' == -A 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ekps9566::A 'directory' == -A 'directory' $^X $__FILE__\n";
}

if (((Ekps9566::C 'directory') ne '') == ((-C 'directory') ne '')) {
    print "ok - 22 Ekps9566::C 'directory' == -C 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ekps9566::C 'directory' == -C 'directory' $^X $__FILE__\n";
}

closedir(DIR);
rmdir('directory');

__END__
