package App::tjoin ;  
our $VERSION = '0.061' ; 
our $DATE = '2021-11-13T14:42+09:00' ; 

=encoding utf8
=head1 NAME
App::tjoin
=head1 SYNOPSIS
This module provides a Unix-like command `F<tjoin>'. 
=head1 DESCRIPTION

 tjoin table < data
 tjoin table data
 cat data | tjoin -c1 -f1 table

  data の指定列(c列目もしくはc列目からf個の列)を、table に従って変換したものを出力する。

  tableのファイルの中身は、タブ区切り(変更可)で1〜f列目とそれ以降が
  それぞれ、変換前の文字列、変換後の文字列で構成されているとする。
  c は -c のオプションで指定される。未指定なら1である。
  f は -f のオプションで指定される。未指定なら1である。


 オプション :

  -c num : (小文字のk) 1始まりもしくは-1終わりで列の番号を指定する。未指定なら1。
  -f num : (大文字のK) 指定位置から何列をキーにするかを指定。未指定なら1。
  -~  : 変換の仕方を逆方向にする。-fで指定された数をKとすると、tableの末尾のK列をキーと見なす。

  -h  : 変換前のデータの最初列の前に変換した値を付ける。 (head)
  -i  : 入力データに対して、変換対象データを置換をする。 (insert)
  -t  : 変換前のデータの最終列の後ろに変換した値をつける。 (tail)
  -x  : 変換対象が無い場合と変換対象のキーの列が無い場合は、出力をしない。
  -m  : 変換すべきdata の変換方法が、参照表 table によって何通り指定されているかを出力。

  -=  : data の最初の行をヘッダ行と見なし、適切に結合した結果の表示をするようにする。(!要推敲)
  -, str : dataもtableも各列は、文字列strで区切られているとする。
  -? str : 変換値が未定義の場合の出力文字列の指定。デフォルトは "notfound" の8文字。
  -E str : 入力が未定義の場合の出力文字列の指定。デフォルトは "noinput" の7文字。<-- 必要なのか?

  --help : この tjoin のヘルプメッセージを出す。  perldoc -t tjoin | cat でもほぼ同じ。
  --help opt : オプションのみのヘルプを出す。opt以外でも optionsの先頭から一致すれば良い。

 開発上のメモ:
   * -E が必要なのか要検討

=head1 SEE ALSO

CLI::KeyValue::Hack's wisejoin.
CLI::Table::Key::Finder's wisejoin.

=cut

1 ;
