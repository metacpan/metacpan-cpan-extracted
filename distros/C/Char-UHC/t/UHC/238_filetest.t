# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{あ} ne "\x82\xa0";

# 一般的なファイル名と chr(0x5C) で終わるファイル名のファイルテストの結果が一致することの確認

my $__FILE__ = __FILE__;

use UHC;
$| = 1;
print "1..51\n";

my $chcp = '';
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    $chcp = `chcp`;
}
if ($chcp !~ /932|949/oxms) {
    for my $tno (1..51) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);
open(FILE,'>F機能');
close(FILE);

open(FILE1,'file');
open(FILE2,'F機能');

if (((-r 'file') ne '') == ((-r 'F機能') ne '')) {
    print "ok - 1 -r 'file' == -r 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 1 -r 'file' == -r 'F機能' $^X $__FILE__\n";
}

if (((-r FILE1) ne '') == ((-r FILE2) ne '')) {
    print "ok - 2 -r FILE1 == -r FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 2 -r FILE1 == -r FILE2 $^X $__FILE__\n";
}

if (((-w 'file') ne '') == ((-w 'F機能') ne '')) {
    print "ok - 3 -w 'file' == -w 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 3 -w 'file' == -w 'F機能' $^X $__FILE__\n";
}

if (((-w FILE1) ne '') == ((-w FILE2) ne '')) {
    print "ok - 4 -w FILE1 == -w FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 4 -w FILE1 == -w FILE2 $^X $__FILE__\n";
}

if (((-x 'file') ne '') == ((-x 'F機能') ne '')) {
    print "ok - 5 -x 'file' == -x 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 5 -x 'file' == -x 'F機能' $^X $__FILE__\n";
}

if (((-x FILE1) ne '') == ((-x FILE2) ne '')) {
    print "ok - 6 -x FILE1 == -x FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 6 -x FILE1 == -x FILE2 $^X $__FILE__\n";
}

if (((-o 'file') ne '') == ((-o 'F機能') ne '')) {
    print "ok - 7 -o 'file' == -o 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 7 -o 'file' == -o 'F機能' $^X $__FILE__\n";
}

if (((-o FILE1) ne '') == ((-o FILE2) ne '')) {
    print "ok - 8 -o FILE1 == -o FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 8 -o FILE1 == -o FILE2 $^X $__FILE__\n";
}

if (((-R 'file') ne '') == ((-R 'F機能') ne '')) {
    print "ok - 9 -R 'file' == -R 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 9 -R 'file' == -R 'F機能' $^X $__FILE__\n";
}

if (((-R FILE1) ne '') == ((-R FILE2) ne '')) {
    print "ok - 10 -R FILE1 == -R FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 10 -R FILE1 == -R FILE2 $^X $__FILE__\n";
}

if (((-W 'file') ne '') == ((-W 'F機能') ne '')) {
    print "ok - 11 -W 'file' == -W 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 11 -W 'file' == -W 'F機能' $^X $__FILE__\n";
}

if (((-W FILE1) ne '') == ((-W FILE2) ne '')) {
    print "ok - 12 -W FILE1 == -W FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 12 -W FILE1 == -W FILE2 $^X $__FILE__\n";
}

if (((-X 'file') ne '') == ((-X 'F機能') ne '')) {
    print "ok - 13 -X 'file' == -X 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 13 -X 'file' == -X 'F機能' $^X $__FILE__\n";
}

if (((-X FILE1) ne '') == ((-X FILE2) ne '')) {
    print "ok - 14 -X FILE1 == -X FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 14 -X FILE1 == -X FILE2 $^X $__FILE__\n";
}

if (((-O 'file') ne '') == ((-O 'F機能') ne '')) {
    print "ok - 15 -O 'file' == -O 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 15 -O 'file' == -O 'F機能' $^X $__FILE__\n";
}

if (((-O FILE1) ne '') == ((-O FILE2) ne '')) {
    print "ok - 16 -O FILE1 == -O FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 16 -O FILE1 == -O FILE2 $^X $__FILE__\n";
}

if (((-e 'file') ne '') == ((-e 'F機能') ne '')) {
    print "ok - 17 -e 'file' == -e 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 17 -e 'file' == -e 'F機能' $^X $__FILE__\n";
}

if (((-e FILE1) ne '') == ((-e FILE2) ne '')) {
    print "ok - 18 -e FILE1 == -e FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 18 -e FILE1 == -e FILE2 $^X $__FILE__\n";
}

if (((-z 'file') ne '') == ((-z 'F機能') ne '')) {
    print "ok - 19 -z 'file' == -z 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 19 -z 'file' == -z 'F機能' $^X $__FILE__\n";
}

if (((-z FILE1) ne '') == ((-z FILE2) ne '')) {
    print "ok - 20 -z FILE1 == -z FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 20 -z FILE1 == -z FILE2 $^X $__FILE__\n";
}

if (((-s 'file') ne '') == ((-s 'F機能') ne '')) {
    print "ok - 21 -s 'file' == -s 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 21 -s 'file' == -s 'F機能' $^X $__FILE__\n";
}

if (((-s FILE1) ne '') == ((-s FILE2) ne '')) {
    print "ok - 22 -s FILE1 == -s FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 22 -s FILE1 == -s FILE2 $^X $__FILE__\n";
}

if (((-f 'file') ne '') == ((-f 'F機能') ne '')) {
    print "ok - 23 -f 'file' == -f 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 23 -f 'file' == -f 'F機能' $^X $__FILE__\n";
}

if (((-f FILE1) ne '') == ((-f FILE2) ne '')) {
    print "ok - 24 -f FILE1 == -f FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 24 -f FILE1 == -f FILE2 $^X $__FILE__\n";
}

if (((-d 'file') ne '') == ((-d 'F機能') ne '')) {
    print "ok - 25 -d 'file' == -d 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 25 -d 'file' == -d 'F機能' $^X $__FILE__\n";
}

if (((-d FILE1) ne '') == ((-d FILE2) ne '')) {
    print "ok - 26 -d FILE1 == -d FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 26 -d FILE1 == -d FILE2 $^X $__FILE__\n";
}

if (((-p 'file') ne '') == ((-p 'F機能') ne '')) {
    print "ok - 27 -p 'file' == -p 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 27 -p 'file' == -p 'F機能' $^X $__FILE__\n";
}

if (((-p FILE1) ne '') == ((-p FILE2) ne '')) {
    print "ok - 28 -p FILE1 == -p FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 28 -p FILE1 == -p FILE2 $^X $__FILE__\n";
}

if (((-S 'file') ne '') == ((-S 'F機能') ne '')) {
    print "ok - 29 -S 'file' == -S 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 29 -S 'file' == -S 'F機能' $^X $__FILE__\n";
}

if (((-S FILE1) ne '') == ((-S FILE2) ne '')) {
    print "ok - 30 -S FILE1 == -S FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 30 -S FILE1 == -S FILE2 $^X $__FILE__\n";
}

if (((-b 'file') ne '') == ((-b 'F機能') ne '')) {
    print "ok - 31 -b 'file' == -b 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 31 -b 'file' == -b 'F機能' $^X $__FILE__\n";
}

if (((-b FILE1) ne '') == ((-b FILE2) ne '')) {
    print "ok - 32 -b FILE1 == -b FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 32 -b FILE1 == -b FILE2 $^X $__FILE__\n";
}

if (((-c 'file') ne '') == ((-c 'F機能') ne '')) {
    print "ok - 33 -c 'file' == -c 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 33 -c 'file' == -c 'F機能' $^X $__FILE__\n";
}

if (((-c FILE1) ne '') == ((-c FILE2) ne '')) {
    print "ok - 34 -c FILE1 == -c FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 34 -c FILE1 == -c FILE2 $^X $__FILE__\n";
}

if (((-t FILE1) ne '') == ((-t FILE2) ne '')) {
    print "ok - 35 -t FILE1 == -t FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 35 -t FILE1 == -t FILE2 $^X $__FILE__\n";
}

if (((-u 'file') ne '') == ((-u 'F機能') ne '')) {
    print "ok - 36 -u 'file' == -u 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 36 -u 'file' == -u 'F機能' $^X $__FILE__\n";
}

if (((-u FILE1) ne '') == ((-u FILE2) ne '')) {
    print "ok - 37 -u FILE1 == -u FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 37 -u FILE1 == -u FILE2 $^X $__FILE__\n";
}

if (((-g 'file') ne '') == ((-g 'F機能') ne '')) {
    print "ok - 38 -g 'file' == -g 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 38 -g 'file' == -g 'F機能' $^X $__FILE__\n";
}

if (((-g FILE1) ne '') == ((-g FILE2) ne '')) {
    print "ok - 39 -g FILE1 == -g FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 39 -g FILE1 == -g FILE2 $^X $__FILE__\n";
}

if (((-k 'file') ne '') == ((-k 'F機能') ne '')) {
    print "ok - 40 -k 'file' == -k 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 40 -k 'file' == -k 'F機能' $^X $__FILE__\n";
}

if (((-k FILE1) ne '') == ((-k FILE2) ne '')) {
    print "ok - 41 -k FILE1 == -k FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 41 -k FILE1 == -k FILE2 $^X $__FILE__\n";
}

if (((-T 'file') ne '') == ((-T 'F機能') ne '')) {
    print "ok - 42 -T 'file' == -T 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 42 -T 'file' == -T 'F機能' $^X $__FILE__\n";
}

if (((-T FILE1) ne '') == ((-T FILE2) ne '')) {
    print "ok - 43 -T FILE1 == -T FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 43 -T FILE1 == -T FILE2 $^X $__FILE__\n";
}

if (((-B 'file') ne '') == ((-B 'F機能') ne '')) {
    print "ok - 44 -B 'file' == -B 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 44 -B 'file' == -B 'F機能' $^X $__FILE__\n";
}

if (((-B FILE1) ne '') == ((-B FILE2) ne '')) {
    print "ok - 45 -B FILE1 == -B FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 45 -B FILE1 == -B FILE2 $^X $__FILE__\n";
}

if (((-M 'file') ne '') == ((-M 'F機能') ne '')) {
    print "ok - 46 -M 'file' == -M 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 46 -M 'file' == -M 'F機能' $^X $__FILE__\n";
}

if (((-M FILE1) ne '') == ((-M FILE2) ne '')) {
    print "ok - 47 -M FILE1 == -M FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 47 -M FILE1 == -M FILE2 $^X $__FILE__\n";
}

if (((-A 'file') ne '') == ((-A 'F機能') ne '')) {
    print "ok - 48 -A 'file' == -A 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 48 -A 'file' == -A 'F機能' $^X $__FILE__\n";
}

if (((-A FILE1) ne '') == ((-A FILE2) ne '')) {
    print "ok - 49 -A FILE1 == -A FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 49 -A FILE1 == -A FILE2 $^X $__FILE__\n";
}

if (((-C 'file') ne '') == ((-C 'F機能') ne '')) {
    print "ok - 50 -C 'file' == -C 'F機能' $^X $__FILE__\n";
}
else {
    print "not ok - 50 -C 'file' == -C 'F機能' $^X $__FILE__\n";
}

if (((-C FILE1) ne '') == ((-C FILE2) ne '')) {
    print "ok - 51 -C FILE1 == -C FILE2 $^X $__FILE__\n";
}
else {
    print "not ok - 51 -C FILE1 == -C FILE2 $^X $__FILE__\n";
}

close(FILE1);
close(FILE2);
unlink('file');
unlink('F機能');

__END__
