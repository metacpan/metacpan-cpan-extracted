package App::sizecheck ;  
our $VERSION = '0.060' ; 
our $DATE = '2022-01-20T23:59+09:00' ; 

=encoding utf8

=head1 NAME

App::sizecheck

=head1 SYNOPSIS

This module provides a Unix-like command `F<sizecheck>'. 

=head1 DESCRIPTION

=head1


sizecheck [dirname] [dirname] ..
  
   カレントディレクトリまたは指定ディレクトリにあるファイルのサイズを表示する。
   ディレクトリ名ではないファイルが指定された場合は、そのファイルのサイズを表示する。
   出力形式はTSV形式(タブ文字区切り)である。

 [オプション] :
   -d N ; 探索する深さ。1で直下のみ。
   -m   ; MD5 によるハッシュ値を各ファイルで計算する。(MD5 = "Message Digest Algorithm 5")
   -:   ; ファイルの番号を出力する。
   -2 0 ; 2次情報(処理したファイル数と経過時間)を出さない。
   -0   ; 単にファイルの一覧を表示。ドライランと考えることも出来る。

  --help : この $0 のヘルプメッセージを出す。  perldoc -t $0 | cat でもほぼ同じ。
  --help opt : オプションのみのヘルプを出す。opt以外でも options と先頭が1文字以上一致すれば良い。

=head1 AUTHOR

下野寿之 Toshiyuki SHIMONO <bin4tsv@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2021 Toshiyuki SHIMONO. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1 ;
