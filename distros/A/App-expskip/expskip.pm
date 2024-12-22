package App::expskip ;  
our $VERSION = '0.114' ; 
our $DATE = '2024-12-22T13:46+09:00' ; 

=encoding utf8

=head1 NAME

App::expskip - To see a large text file, 1st, 10th, 100th, 1000th .. lines are shown to see fewer lines. Output lines can be specifed by the options.

=head1 SYNOPSIS

This module provides a Unix-like command `F<expskip>'. 

 $0 [-z] [-B 0] [-A 0] [-p 1] [-f 1] [-e 2]  

   大きなテキストファイルの全体を把握しやすくするため、
   最初と最後の数行と途中の 1, 10, 100, 1000 .. 行目などを出力する。どう出力するかは、オプションで指定可能。


=head1 DESCRIPTION

=head1 SEE ALSO

=cut

1 ;
