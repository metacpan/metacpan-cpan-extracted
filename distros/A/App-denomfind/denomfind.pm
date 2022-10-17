package App::denomfind ;  
our $VERSION = '0.258' ; 
our $DATE = '2022-10-17T18:55+09:00' ; 

=encoding utf8

=head1 NAME

App::denomfind -- Finding the common denominator for multiple approximated quotients in decimal.

   1. denomfind -- 複数の四捨五入などされた数値を、共通した1個の分母を持つ整数比と見なして、その分母を総当たりで探索する。
   2. primefind -- 1行ずつ整数を逐次読み取り、ある数が既に読んだどの数の倍数でなければ、出力する。

=head1 SYNOPSIS

This module provides a Unix-like command `F<denomfind>' and `F<primefind>'.

=head1 DESCRIPTION


=head1 AUTHOR

下野寿之 Toshiyuki SHIMONO <bin4tsv@gmail.com> 統計数理研究所 外来研究員

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022 Toshiyuki SHIMONO. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1 ;
