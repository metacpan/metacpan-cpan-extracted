@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
jperl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
jperl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!jperl
#line 14
print STDERR <<END;
#####################################################################

 GhostWork - 読取ったバーコードをログファイルにするプログラム

#####################################################################

■操作説明
   [Q] は [Q]uit  の略でプログラムを終了します。
   [R] は [R]etry の略で直前の操作をやり直せます。

END

$Q_WHO='あなたの名前は？';
$Q_TOWHICH='どの工程を行いますか？';
$Q_WHAT='どの帳票ですか？';
$Q_WHY='....理由は？';
$INFO_LOGFILE_IS='ログファイルは ';
$INFO_DOUBLE_SCANNED='エラー発生：直前と同じバーコードです。';
$INFO_ANY_KEY_TO_EXIT='何かキーを押すと終了します。';

($FindBin = __FILE__) =~ s{[^/\\]+$}{};
do "$FindBin/GhostWork.pl4.bat";

__END__
:endofperl
