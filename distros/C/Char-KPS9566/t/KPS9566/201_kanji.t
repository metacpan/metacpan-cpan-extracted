# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{あ} ne "\x82\xa0";

use strict;
# use warnings;

use KPS9566;
print "1..1\n";

my $__FILE__ = __FILE__;

my $chcp = '';
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    $chcp = `chcp`;
}
if ($chcp !~ /932|949/oxms) {
    print "ok - 1 # SKIP $^X $0\n";
    exit;
}

mkdir('hoge', 0777);
open(FILE,'>hoge/テストソース.txt') || die "Can't open file: hoge/テストソース.txt\n";
print FILE "1\n";
close(FILE);

my($fileName) = glob("./hoge/*");
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

◆その１：コードはshiftjis、処理はshiftjis、標準入出力はshiftjis

実行結果
C:\test>perl $0
Unmatched [ in regex; marked by <-- HERE in m/メ[ <-- HERE ス/ at $0 line 6.

しかし、上記ではマッチしません。
というか、正規表現エラーになります。
これは、『ソース』の『ー』の第２バイトが『[』のコードになっているからです。
そして、閉じの『]』がないために正規表現エラーになるのです。

8/2(土) ■[Perlノート] シフトJIS漢字のファイル名にマッチしてみる
http://d.hatena.ne.jp/chaichanPaPa/20080802/1217660826
