@echo off
echo:#####################################################################
echo:
echo: GhostWork - 読取ったバーコードをログファイルにするプログラム
echo:
echo:#####################################################################
echo:
echo:■操作説明
echo:   [Q] は [Q]uit  の略でデータを保存して終了します。
echo:   [R] は [R]etry の略で直前の操作をやり直せます。
echo:
echo:   ウィンドウ右上の [X] をクリックしないでください。データが保存されません。
echo:

set Q_WHO=あなたの名前は？
set Q_TOWHICH=どの工程を行いますか？
set INFO_LOGFILE_IS=ログファイルは、
set Q_WHAT=どの帳票ですか？
set Q_WHY=....理由は？
set INFO_ANY_KEY_TO_EXIT=何かキーを押すと終了します。

GhostWork %*

