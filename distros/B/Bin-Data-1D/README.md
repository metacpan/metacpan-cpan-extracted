# Bin-Data-1D

各行にデータとして意味のあるような値が記載されたファイルを扱うための、コマンドラインツールの集まり。
Perl言語のcpanモジュールとしてこのレポジトリは機能する。

CPANにモジュール名 Bin::Data::1D として登録されることを想定している。
モジュール名のガイドラインである perlmodlib は完全で無いものの考慮している。
Li は Lines の略として、またhtml言語におけるliを参考にして命名した。
Li = Lited Items = Line Items の語呂を連想させるようにした。

2021年5月25日に初めて作成(各コマンドは何年か前に作ったが、それを初めてこのモジュール用に選んで、まとめた)。



This module "Bin::Data::1D" provides scripts for specific functions that deals "line-recorded data".
The included commands are as follows. 

expskip     ; Only shows 1st, 10th, 100th, 1000th lines and so on.
freq        ; Counts the frequencies of each different value that appears as one line.
sampler     ; Randomly selected lines will be extracted. 
cat-n       ; Alternative function of "cat -n". 
chars2code  ; Each line is interpreted as the stream of binary codes. Hexagonal ASCII codes or Unicode will be shown.
summing     ; Accumulative sum will be shown while reading each line.
gzpaste     ; Unix `paste` funciton for multiple gzipped files. 

