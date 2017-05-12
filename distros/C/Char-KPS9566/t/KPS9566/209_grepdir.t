# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{あ} ne "\x82\xa0";

use KPS9566;
print "1..2\n";

my $__FILE__ = __FILE__;

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    print "ok - 1 # SKIP $^X $__FILE__\n";
    print "ok - 2 # SKIP $^X $__FILE__\n";
    exit;
}

$| = 1;

mkdir('dt',0777);
mkdir('dt/alphabet',0777);
mkdir('dt/日本語',0777);

open(FILE,">dt/alphabet/alpha.txt") || die "Can't open file: dt/alphabet/alpha.txt\n";
print FILE <<'END';
aaa
bbb
ccc
ddd
eee
END
close(FILE);

open(FILE,">dt/日本語/alpha.txt") || die "Can't open file: dt/日本語/alpha.txt\n";
print FILE <<'END';
aaa
bbb
ccc
ddd
eee
END
close(FILE);

open(FILE,">dt/alphabet/sjis.txt") || die "Can't open file: dt/alphabet/sjis.txt\n";
print FILE <<'END';
aaa
あああ
bbb
いいい
ccc
ううう
ddd
表
eee
END
close(FILE);

open(FILE,">dt/日本語/sjis.txt") || die "Can't open file: dt/日本語/sjis.txt\n";
print FILE <<'END';
aaa
あああ
bbb
いいい
ccc
ううう
ddd
表
eee
END
close(FILE);

my $aaa = <<'END';
!!dt/alphabet!!
!!dt/alphabet/alpha.txt!!
dt/alphabet/alpha.txt:aaa
!!dt/alphabet/sjis.txt!!
dt/alphabet/sjis.txt:aaa
!!dt/日本語!!
!!dt/日本語/alpha.txt!!
dt/日本語/alpha.txt:aaa
!!dt/日本語/sjis.txt!!
dt/日本語/sjis.txt:aaa
END

my $hyou = <<'END';
!!dt/alphabet!!
!!dt/alphabet/alpha.txt!!
!!dt/alphabet/sjis.txt!!
dt/alphabet/sjis.txt:表
!!dt/日本語!!
!!dt/日本語/alpha.txt!!
!!dt/日本語/sjis.txt!!
dt/日本語/sjis.txt:表
END

my $script = __FILE__ . '.pl';

open(FILE,">$script") || die "Can't open file: $script\n";
print FILE <DATA>;
close(FILE);

if (($ENV{'PERL5SHELL'}||$ENV{'COMSPEC'}) =~ / \\COMMAND\.COM \z/oxmsi) {
    $_ = `$^X $script aaa dt`;
}
else {
    $_ = `$^X $script aaa dt 2>NUL`;
}
sleep 1;
if ($_ eq $aaa) {
    print "ok - 1 $^X $__FILE__ aaa dt \n";
}
else {
    print "not ok - 1 $^X $__FILE__ aaa dt \n";
    print "($_)\n";
    print "($aaa)\n";
}

if (($ENV{'PERL5SHELL'}||$ENV{'COMSPEC'}) =~ / \\COMMAND\.COM \z/oxmsi) {
    $_ = `$^X $script 表 dt`;
}
else {
    $_ = `$^X $script 表 dt 2>NUL`;
}
sleep 1;
if ($_ eq $hyou) {
    print "ok - 2 $^X $__FILE__ 表 dt\n";
}
else {
    print "not ok - 2 $^X $__FILE__ 表 dt\n";
    print "($_)\n";
    print "($hyou)\n";
}
sleep 1;

unlink($script);
unlink("$script.e");

unlink('dt/alphabet/alpha.txt');
unlink('dt/alphabet/sjis.txt');
unlink('dt/日本語/alpha.txt');
unlink('dt/日本語/sjis.txt');
rmdir('dt/alphabet');
rmdir('dt/日本語');
rmdir('dt');

__END__
# encoding: KPS9566
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use KPS9566;

local $^W = 1;

if (@ARGV < 2) {
    die <<END;
実行方法:

perl $0 aaa dt
perl $0 表  dt
END
}

&grepdir(@ARGV);

exit 0;

sub grepdir ($$) {
    my($pat,$dir) = @_;
    my($node);

    opendir(D,$dir);
    my @nodes = grep (!/^\./, readdir(D));
    closedir(D);

    foreach $node (@nodes) {
        my $path="$dir/$node";
        print "!!$path!!\n";
        if ( -f $path ) {
            grepfile($pat,$path);
        }
        elsif( -d $path) {
            &grepdir($pat,$path);
        }
        else {
            print STDERR "skip:$path\n";
        }
    }
}

sub grepfile ($$) {
    my($pat,$file) = @_;
    open(IN,$file) or die "Error:open($file):$!\n";
    while (<IN>) {
        chomp;

# 修正箇所1
#       print "$file:$_\n" if (/$pat/);
        print "$file:$_\n" if (/\Q$pat\E/);
    }
}

__END__

WindowsでPerl 5.8/5.10を使うモンじゃない

の「ここで紹介したスクリプトのサンプル」の grepdir.pl を利用しています。

例: 正規表現を指定して，指定したディレクトリ配下のファイルから取り出すコードを書いてる。

コマンド形式: perl grepdir.pl {パターン} {ディレクトリ}

次のようなテスト環境を用意する。

C:\TEMP\TP> tree /F dt
フォルダ パスの一覧: ボリューム vvvvv_vvvvvvvvv
ボリューム シリアル番号は vvvv-ssss です
C:\TEMP\TP\DT
├─alphabet
│      alpha.txt
│      sjis.txt
│
└─日本語
       alpha.txt
       sjis.txt

これを perl にて実行させると，次のようになる。

C:\TEMP\TP\DT>perl grepdir.pl aaa dt
!!dt/alphabet!!
!!dt/alphabet/alpha.txt!!
dt/alphabet/alpha.txt:aaa
!!dt/alphabet/sjis.txt!!
dt/alphabet/sjis.txt:aaa
!!dt/日本語!!
!!dt/日本語/alpha.txt!!
dt/日本語/alpha.txt:aaa
!!dt/日本語/sjis.txt!!
dt/日本語/sjis.txt:aaa

C:\TEMP\TP\DT>perl grepdir.pl 表 dt
!!dt/alphabet!!
!!dt/alphabet/alpha.txt!!
!!dt/alphabet/sjis.txt!!
dt/alphabet/sjis.txt:表
!!dt/日本語!!
!!dt/日本語/alpha.txt!!
!!dt/日本語/sjis.txt!!
dt/日本語/sjis.txt:表

直さなければならないところは，以下のようなところになる。

修正箇所1
  正規表現内に変数を記述し、変数に格納されている内容そのものにマッチ
  させたいのであれば \Q ... \E で囲む必要がある。

    ----------------------------------------------
    print "$file:$_\n" if (/$pat/);
    ----------------------------------------------
                ↓ 書き換え
    ----------------------------------------------
    print "$file:$_\n" if (/\Q$pat\E/);
    ----------------------------------------------

以上
