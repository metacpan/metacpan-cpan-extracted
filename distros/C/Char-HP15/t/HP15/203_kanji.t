# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{あ} ne "\x82\xa0";

use strict;
# use warnings;

use HP15;
print "1..1\n";

my $__FILE__ = __FILE__;

my $chcp = '';
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    $chcp = `chcp`;
}
if ($chcp !~ /932/oxms) {
    print "ok - 1 # SKIP $^X $__FILE__\n";
    exit;
}

mkdir('hoge', 0777);
open(FILE,'>hoge/テストソース.txt') || die "Can't open file: hoge/テストソース.txt\n";
print FILE "1\n";
close(FILE);

my($fileName) = glob("./hoge/*");
my $wk = "ソース";
if ($fileName =~ /\Q$wk\E/) {
    print "ok - 1 $^X $__FILE__\n";
}
else {
    print "not ok - 1 $^X $__FILE__\n";
}

unlink('hoge/テストソース.txt');
rmdir('hoge');

__END__

たとえば、./hoge配下に『テストソース.txt』というファイルがあったとします。
一度『ソース』文字列を変数に格納してみます。

◆その３：コードはshiftjis、処理はshiftjis、標準入出力はshiftjis

実行結果
C:\test>perl $0
Unmatch
./hoge/テストソース.txt

しかし、上記ではマッチしません。
これは、『my $wk = "ソース";』で『ソ』の第２バイトがエスケープ文字『\』の
コードになっているからです。
そして、『ソ』の第１バイトと『ー』の第１バイトがくっ付いてしまうのです。

8/2(土) ■[Perlノート] シフトJIS漢字のファイル名にマッチしてみる
http://d.hatena.ne.jp/chaichanPaPa/20080802/1217660826
