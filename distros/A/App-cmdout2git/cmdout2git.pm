package App::cmdout2git ; 
our $VERSION = '0.015' ; 
our $DATE = '2023-03-10T21:00+09:00' ; 

=encoding utf8

=head1 NAME

App::cmdout2git -- コマンドの出力結果を、Gitのレポジトリの中のファイルに保管する。

=head1 SYNOPSIS

This module provides a Unix-like command `cmdout2git'. 

=head1 DESCRIPTION

想定している使い方 (cmdout2git) : 

  - コマンドの crontab -l や last や "ls サーバー名/ディレクトリ" の結果を定期的に保管する。
 
=head1 SEE ALSO

cmdout2git --help 

 Copyright (c) 2023 Toshiyuki SHIMONO. All rights reserved.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=head1 SEE ALSO


=cut

1 ;


