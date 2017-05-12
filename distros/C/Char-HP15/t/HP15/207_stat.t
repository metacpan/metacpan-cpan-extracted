# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{あ} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use HP15;
print "1..2\n";

my $chcp = '';
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    $chcp = `chcp`;
}
if ($chcp !~ /932/oxms) {
    print "ok - 1 # SKIP $^X $__FILE__\n";
    print "ok - 2 # SKIP $^X $__FILE__\n";
    exit;
}

open(FILE,'>F機能') || die "Can't open file: F機能\n";
print FILE "1\n";
close(FILE);
mkdir('D機能', 0777);
open(FILE,'>D機能/a.txt') || die "Can't open file: D機能/a.txt\n";
print FILE "1\n";
close(FILE);
open(FILE,'>D機能/b.txt') || die "Can't open file: D機能/b.txt\n";
print FILE "1\n";
close(FILE);
open(FILE,'>D機能/c.txt') || die "Can't open file: D機能/c.txt\n";
print FILE "1\n";
close(FILE);
open(FILE,'>D機能/F機能') || die "Can't open file: D機能/F機能\n";
print FILE "1\n";
close(FILE);
mkdir('D機能/D機能', 0777);

$_ = 'F機能';
if (@_ = stat($_)) {
    print "ok - 1 $^X $__FILE__\n";
}
else{
    print "not ok - 1 $^X $__FILE__\n";
}

$_ = 'D機能';
if (@_ = stat($_)) {
    print "not ok - 2 $^X $__FILE__\n";
}
else{
    print "ok - 2 $^X $__FILE__\n";
}

unlink('F機能');
rmdir('D機能/D機能');
unlink('D機能/a.txt');
unlink('D機能/b.txt');
unlink('D機能/c.txt');
unlink('D機能/F機能');
rmdir('D機能');

__END__

Perlメモ/Windowsでのファイルパス
http://digit.que.ne.jp/work/wiki.cgi?Perl%E3%83%A1%E3%83%A2%2FWindows%E3%81%A7%E3%81%AE%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%83%91%E3%82%B9

ファイル関連コマンドの動作確認
「機能」という文字列を変数$_に入れ、stat($_)としても返り値がない 

