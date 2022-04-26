package App::dirdim ;  
our $VERSION = '0.031' ; 
our $DATE = '2022-04-25T22:34+09:00' ; 

=encoding utf8

=head1 NAME

App::dirdim

=head1 SYNOPSIS

This module provides a Unix-like command `F<dirdim>'. 

=head1 DESCRIPTION

 dirdim DIR [DIR] [DIR] ..

  指定されたディレクトリの直下にある、非ディリクトリファイルの数とディレトリの数を出力する。
  シンボリックファイルの個数は括弧内に示す。 (何も引数が無い場合は、カレントディレクトリに対して動作。)

 オプション: 

  -.  : ファイル名がピリオドで始まるファイル(隠しファイルと言われる)について調べる。(dot file)
  -j  : 出力の表頭の表記を、英語から日本語に変更。
  -n  : ファイル名がピリオドで始まるファイル(隠しファイルと言われる)は対象外とする。(Nomal)
  -r  ; 最も深い所にあるファイルの名前とその深さを示す。さらに、findで見つかるファイルの個数も出力。(Recursive)
  -v  : ファイル名の(文字列としての)最小値と最大値も出力する。(verbose)
  -y  : 引数 arg でディレクトリ以外のものがあった場合は、処理を飛ばす。(出力が簡潔になる。)

  --help : このヘルプを表示。

 開発上のメモ: 
   * glob の */../*のような探索と File::Find による探索の違いを発見した。dirdimとdirdigで共通化の検討が必要。
   * Ctrl-Cを押下した時の挙動を決めたい。
   * 色を消すオプションを実装した方が良いだろうか? 他のコマンドの colorplus -0 に任せるべきか?

=head1 AUTHOR

下野寿之 Toshiyuki SHIMONO <bin4tsv@gmail.com> 統計数理研究所 外来研究員

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022 Toshiyuki SHIMONO. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1 ;
