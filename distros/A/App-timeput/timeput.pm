package App::timeput ;  
our $VERSION = '0.078' ; 
our $DATE = '2021-11-24T22:59+09:00' ; 

=encoding utf8
=head1 NAME
App::timeput
=head1 SYNOPSIS
This module provides a Unix-like command `F<timeput>'. 
=head1 DESCRIPTION

=head1

timeput 

  入力を1行ずつ読み、その各行の先頭に、読み取った時点の時刻をタブ区切りで出力する。
  ただし、"-w 秒数" の指定により、1行読んで出力して、指定秒数動作を止める(sleepする)。

 オプション : 
    -b : 出力のバッファリングを許す(何か理由が無い限り使うことは無いであろう)
    -c STR : 色の指定。0で色無し。"cyan","faint red bold","bright_blue"など。色名指定はTerm::ANSIColor を参照。
    -d : 日付も出力。yyyy-mm-dd HH:MM:SS 形式で。(date)
    -g : 開始からの秒数でなくて、1行ごとの間隔秒数を表示。(gap)
    -s : 起動してからの秒数を出力。(start)
    -w N: 入力から1行ずつ逐次読み取り出力して、N秒停止することを繰り返す。正の浮動小数点数を指定可能。(wait)
    -z STR : タイムゾーンの設定。"Asia/Tokyo", "-9", "-9:00", "JST-9" などが設定できる。(システム依存)

    -. N : 秒数を小数点以下 N 桁出力する。0から6の整数値が使える。未指定なら3。(-d とは両立しない。) 

 利用例 : 
    yes | head | timeput -.6 
    yes | head | timeput -d  | sed 's/ /T/' # POSIXの日時形式にしたい場合。このsed文は最初の空白文字のみTに変更。
    seq 5 | timeput -.6 | timeput -s.6 | timeput -g.6
    seq 10 | timeput -w0.45 | timeput -g.3 # 0.45秒ずつ1行を読み取る。
    command 1> output1.txt 2> >( timeput error.log ) # command は標準エラー出力に何か出力をするプログラムである。便利。

  開発メモ:
    * -w の動作を高度化したい。-w 2,0.2x10,0 と指定することで最初は2秒、次に10回は0.2秒、残りは即座のように。,は+、xは*でも可としたい。
    * -3 のオプションを作りたい。timeput -3 で timeput -g | timeput -s | timeput とおなじ機能を持たせたい。
    * 名前を timeput (タイムプット)ではなく、puttime の方が「プッタイム」で発音しやすい気がする。その方が記憶しやすい。

=head1 AUTHOR

下野寿之 Toshiyuki SHIMONO <bin4tsv@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2021 Toshiyuki SHIMONO. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1 ;
