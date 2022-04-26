package App::filedays ;  
our $VERSION = '0.203' ; 
our $DATE = '2022-04-24T21:20+09:00' ; 

=encoding utf8

=head1 NAME

App::filedays

=head1 SYNOPSIS

This module provides a Unix-like command `F<filedays>'. 

=head1 DESCRIPTION

=head1

　filedays [dirname]
    
 カレントディレクトリまたは指定ディレクトリに含まれる通常ファイル全てについて、
 各ファイルの日時情報3個(atime,mtime,ctme)を取り出し、それぞれ3つの日付ごとに
 ファイルの個数とバイトサイズの合計を、出力する。

   出力は7列のTSV形式のテーブルであり、
 (1)日付 (2)atimeの日付ごとのファイルの個数 (3) mtime での個数 (4) ctime での個数
 (5) atimeの日付ごとに該当するファイル全てのバイト数の合計 (6) mtime での合計 (7) ctimeでの合計
   となる。オプションに寄り、日単位の日付だけでは無くて、月単位、年単位などに変更が可能。

 ※ UNIXコマンドの tabs -11 をあらかじめ実行すると、このコマンド filedays の実行結果が見やすいであろう。


オプション: 

  -y : 年単位で集計
  -m : 月単位で集計
  -d : 日単位で集計 (初期設定)
  -H : 時単位で集計
  -M : 分単位で集計
  -S : 秒単位で集計

  -. 0 : 隠しファイルを処理対象としないことの指定
  -b 0 : バイト数の合計の出力の抑制の指定
  -r : ディレクトリを再帰的に下に辿る。
  -~ : 出力の時間順を逆にする。
  -2 0 : 処理に要した秒数の情報の抑制の指定
 

=head1 AUTHOR

下野寿之 Toshiyuki SHIMONO <bin4tsv@gmail.com> 統計数理研究所 外来研究員

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022 Toshiyuki SHIMONO. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1 ;
