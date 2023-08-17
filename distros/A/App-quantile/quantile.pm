package App::quantile ;  
our $VERSION = '0.014' ; 
our $DATE = '2023-06-09T19:29+09:00' ; 

=encoding utf8

=head1 NAME

App::quantile -- calculates the quantiles. 

=head1 SYNOPSIS

This module provides a Unix-like command `F<quantile>'. 

=head1 DESCRIPTION

 quantile -q N  # This reads a number in each line from STDIN, then prints N-quantiles. 

  `perldoc App::quantile' shows English help. 
  `perldoc quantile' and `quantile --help' shows Japanese help. 

  分位点を求める。通常の(線形)補間値のみならず、上側の値と下側の値も出力する。
  2次情報として何個の値を入力から読み取ったかも、標準エラー出力に出力。

 Options :  N refers to a number.

  -= : 最初の行を読み飛ばす。
  -q N : 分位分割の数Nを指定する。
  -p 1..5など : 何番目の分位点を出力するかを指定する。小数も指定可能。, や .. が使える。
  -a : 平均値も出力する(最も右の列に)。  

  -h : 分位点の計算において、考えられる大きい値についても、出力する。
  -I : 分位点を観測値に存在する値ではなくて、線形補間した値を用いる。
  -l : 分位点の計算において、考えられる小さい値についても、出力する。
  -0 : 通常のよく使われる分位点の値を出さない。(-h, -l, -i を使う時に便利。)
  -s : 入力を数値としてではなく、文字列として処理する。日時を扱う場合などに使う。

  -L ; 層別に分位点を出力する。1列目を値と見なし、タブ区切り2列目以降を層のラベルと見なす。
  -w ; 分位値を算出する際に、各値を平等に扱うのではなくて、その値自信で重みを付ける。(正の値を仮定する。)
  -3 : -w で数値が2列とする。左側が昇順ソートされるが、重みは自己重みではなくて、右側の値となる。

  -i str ; 入力の区切り文字をstrとする。
  -@ N : 一定秒数ごとに、標準エラー出力にレポートを出す。未指定なら、10秒。
  -2 0 : Suppresses the secondary information. 

  --help : Shows this help. 
  --help opt : Shows the option help.
  --version : Shows the version information.
 
=head1 AUTHOR

下野寿之 Toshiyuki SHIMONO <bin4tsv@gmail.com> The Institute of Statistical Mathematics, a visiting researcher. 

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016-2023 Toshiyuki SHIMONO. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1 ;
