package App::expandtab ;  
our $VERSION = '0.042' ; 
our $DATE = '2023-03-22T19:23+09:00' ; 

=encoding utf8

=head1 NAME

App::expandtab - display TSV text aligned vertically along tab characters.

=head1 SYNOPSIS

This module provides a Unix-like command `F<expandtab>'. 

TSV形式(タブ区切り)のテキストデータに対して、各列が同じ位置に揃うように出力する。
Text::VisualWidth が院トールされている場合、全角文字が混ざっていても、さらには
ASCIIカラーコード付きの文字が混ざっていても、正しく縦に揃うようにする。

=head1 DESCRIPTION

=head1 SEE ALSO

=cut

1 ;
