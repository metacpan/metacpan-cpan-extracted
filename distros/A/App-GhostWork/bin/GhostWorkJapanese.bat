@echo off
echo:#####################################################################
echo:
echo: GhostWork - 読取ったバーコードをログファイルにするプログラム
echo:
echo:#####################################################################
echo:
echo:■操作説明
echo:   [Q] は [Q]uit  の略でプログラムを終了します。
echo:   [R] は [R]etry の略で直前の操作をやり直せます。
echo:

setlocal
set Q_WHO=あなたの名前は？
set Q_TOWHICH=どの工程を行いますか？
set Q_WHAT=どの帳票ですか？
set Q_WHY=....理由は？
set INFO_LOGFILE_IS=ログファイルは 
set INFO_DOUBLE_SCANNED=エラー発生：直前と同じバーコードです。
set INFO_ANY_KEY_TO_EXIT=何かキーを押すと終了します。

call GhostWork.bat %*
endlocal
