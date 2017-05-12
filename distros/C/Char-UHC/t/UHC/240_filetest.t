# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{あ} ne "\x82\xa0";

# 一般的なディレクトリル名と chr(0x5C) で終わるディレクトリ名のファイルテストの結果が一致することの確認

my $__FILE__ = __FILE__;

use UHC;
print "1..23\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..23) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

mkdir('directory',0777);
mkdir('D機能',0777);

if (((-r 'directory') ne '') == ((-r 'D機能') ne '')) {
    print "ok - 1 -r 'directory' == -r 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 1 -r 'directory' == -r 'D機能' $^X $__FILE__\n";
}

if (((-w 'directory') ne '') == ((-w 'D機能') ne '')) {
    print "ok - 2 -w 'directory' == -w 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 2 -w 'directory' == -w 'D機能' $^X $__FILE__\n";
}

if (((-x 'directory') ne '') == ((-x 'D機能') ne '')) {
    print "ok - 3 -x 'directory' == -x 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 3 -x 'directory' == -x 'D機能' $^X $__FILE__\n";
}

if (((-o 'directory') ne '') == ((-o 'D機能') ne '')) {
    print "ok - 4 -o 'directory' == -o 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 4 -o 'directory' == -o 'D機能' $^X $__FILE__\n";
}

if (((-R 'directory') ne '') == ((-R 'D機能') ne '')) {
    print "ok - 5 -R 'directory' == -R 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 5 -R 'directory' == -R 'D機能' $^X $__FILE__\n";
}

if (((-W 'directory') ne '') == ((-W 'D機能') ne '')) {
    print "ok - 6 -W 'directory' == -W 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 6 -W 'directory' == -W 'D機能' $^X $__FILE__\n";
}

if (((-X 'directory') ne '') == ((-X 'D機能') ne '')) {
    print "ok - 7 -X 'directory' == -X 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 7 -X 'directory' == -X 'D機能' $^X $__FILE__\n";
}

if (((-O 'directory') ne '') == ((-O 'D機能') ne '')) {
    print "ok - 8 -O 'directory' == -O 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 8 -O 'directory' == -O 'D機能' $^X $__FILE__\n";
}

if (((-e 'directory') ne '') == ((-e 'D機能') ne '')) {
    print "ok - 9 -e 'directory' == -e 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 9 -e 'directory' == -e 'D機能' $^X $__FILE__\n";
}

if (((-z 'directory') ne '') == ((-z 'D機能') ne '')) {
    print "ok - 10 -z 'directory' == -z 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 10 -z 'directory' == -z 'D機能' $^X $__FILE__\n";
}

if (((-s 'directory') ne '') == ((-s 'D機能') ne '')) {
    print "ok - 11 -s 'directory' == -s 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 11 -s 'directory' == -s 'D機能' $^X $__FILE__\n";
}

if (((-f 'directory') ne '') == ((-f 'D機能') ne '')) {
    print "ok - 12 -f 'directory' == -f 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 12 -f 'directory' == -f 'D機能' $^X $__FILE__\n";
}

if (((-d 'directory') ne '') == ((-d 'D機能') ne '')) {
    print "ok - 13 -d 'directory' == -d 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 13 -d 'directory' == -d 'D機能' $^X $__FILE__\n";
}

if (((-p 'directory') ne '') == ((-p 'D機能') ne '')) {
    print "ok - 14 -p 'directory' == -p 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 14 -p 'directory' == -p 'D機能' $^X $__FILE__\n";
}

if (((-S 'directory') ne '') == ((-S 'D機能') ne '')) {
    print "ok - 15 -S 'directory' == -S 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 15 -S 'directory' == -S 'D機能' $^X $__FILE__\n";
}

if (((-b 'directory') ne '') == ((-b 'D機能') ne '')) {
    print "ok - 16 -b 'directory' == -b 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 16 -b 'directory' == -b 'D機能' $^X $__FILE__\n";
}

if (((-c 'directory') ne '') == ((-c 'D機能') ne '')) {
    print "ok - 17 -c 'directory' == -c 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 17 -c 'directory' == -c 'D機能' $^X $__FILE__\n";
}

if (((-u 'directory') ne '') == ((-u 'D機能') ne '')) {
    print "ok - 18 -u 'directory' == -u 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 18 -u 'directory' == -u 'D機能' $^X $__FILE__\n";
}

if (((-g 'directory') ne '') == ((-g 'D機能') ne '')) {
    print "ok - 19 -g 'directory' == -g 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 19 -g 'directory' == -g 'D機能' $^X $__FILE__\n";
}

if (((-k 'directory') ne '') == ((-k 'D機能') ne '')) {
    print "ok - 20 -k 'directory' == -k 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 20 -k 'directory' == -k 'D機能' $^X $__FILE__\n";
}

if (((-M 'directory') ne '') == ((-M 'D機能') ne '')) {
    print "ok - 21 -M 'directory' == -M 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 21 -M 'directory' == -M 'D機能' $^X $__FILE__\n";
}

if (((-A 'directory') ne '') == ((-A 'D機能') ne '')) {
    print "ok - 22 -A 'directory' == -A 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 22 -A 'directory' == -A 'D機能' $^X $__FILE__\n";
}

if (((-C 'directory') ne '') == ((-C 'D機能') ne '')) {
    print "ok - 23 -C 'directory' == -C 'D機能' $^X $__FILE__\n";
}
else {
    print "not ok - 23 -C 'directory' == -C 'D機能' $^X $__FILE__\n";
}

rmdir('directory');
rmdir('D機能');

__END__
