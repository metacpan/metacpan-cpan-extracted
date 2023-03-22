package App::chars2code ;  
our $VERSION = '0.010' ; 
our $DATE = '2023-03-21T16:46+09:00' ; 

=encoding utf8

=head1 NAME

App::chars2code -- UTF8の文字列を1行ずつ読み取り、各文字をU+(16進数)の形式などに変換して、1行ずつ出力する。

 chars2code -- コマンドの「od -tax1」と動作は似ているが、16バイトずつではなくて、1行単位であり、便利な場面が多い。

=head1 SYNOPSIS

This module provides a Unix-like command `F<chars2code>' and `F<primefind>'.

=head1 DESCRIPTION


=head1 AUTHOR

下野寿之 Toshiyuki SHIMONO <bin4tsv@gmail.com> 統計数理研究所 外来研究員

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023 Toshiyuki SHIMONO. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1 ;
