# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{あ} ne "\x82\xa0";

use strict;
# use warnings;

use Big5HKSCS;
print "1..1\n";

my $__FILE__ = __FILE__;

my $chcp = '';
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    $chcp = `chcp`;
}
if ($chcp !~ /932|950/oxms) {
    print "ok - 1 # SKIP $^X $__FILE__\n";
    exit;
}

mkdir('hoge', 0777);
open(FILE,'>hoge/テストソース.txt') || die "Can't open file: hoge/テストソース.txt\n";
print FILE "1\n";
close(FILE);

my($fileName) = glob("./hoge/*");
# if ($fileName =~ /\Qソース\E/) {
if ($fileName =~ /ソース/) {
    print "ok - 1 $^X $__FILE__\n";
}
else {
    print "not ok - 1 $^X $__FILE__\n";
}

unlink('hoge/テストソース.txt');
rmdir('hoge');

__END__

たとえば、./hoge配下に『テストソース.txt』というファイルがあったとします。
『[』を普通の文字扱いするために、『ソース』を\Qと\Eで囲んでみます。

◆その２：コードはshiftjis、処理はshiftjis、標準入出力はshiftjis

実行結果
C:\test>perl $0
Unmatch
./hoge/テストソース.txt

しかし、上記ではマッチしません。
なぜかというと、 /\Qソース\E/は、\Qより先に『ソース』文字列が評価されるので、
基本的に『[』をエスケープしたに過ぎません。

8/2(土) ■[Perlノート] シフトJIS漢字のファイル名にマッチしてみる
http://d.hatena.ne.jp/chaichanPaPa/20080802/1217660826
