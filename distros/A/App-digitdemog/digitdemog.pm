package App::digitdemog ; 
our $VERSION = '0.085' ; 
our $DATE = '2023-03-06T01:23+09:00' ; 

=encoding utf8

=head1 NAME

App::digitdemog -- 各行の文字列について、左からの桁ごとにどんな文字が現れたかをクロス表で表示。

=head1 SYNOPSIS

This module provides a Unix-like command `digitdemog'. 

=head1 DESCRIPTION

想定している使い方 (digitdemog) : 

  1. 何桁目にどんな文字が現れたのか把握することで、調べたい文字列データの性質を解読する
  2. 最も長いもしくは短い行の例を知る。
  3. L2 か -L4 のオプションで、行の文字列長ごとの例を知る。
 
=head1 SEE ALSO

digitdemog --help 

 Copyright (c) 2023 Toshiyuki SHIMONO. All rights reserved.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=head1 SEE ALSO


=cut

1 ;


