package App::resistorcc ;  
our $VERSION = '0.054' ; 
our $DATE = '2023-06-09T09:42+09:00' ; 

=encoding utf8

=head1 NAME

App::resistorcc -- Put colors on numerical digits (0 to 9) according to the electric resistance color codes. 1 for brown, 2 for red, 3 for orange and so on with some small change.

=head1 SYNOPSIS

This module provides a Unix-like command `F<resistorcc>'. 

=head1 DESCRIPTION

 resistorcc 

  `perldoc App::resistorcc' shows English help. 
  `perldoc resistorcc' and `resistorcc --help' shows Japanese help. 

   This command read the given file or STDIN, then 
   using ANSI Escape Code it puts colors as follows on numerical characters.
   The color is based on the electronic color code which is internationally 
   used. As a result, the text containing many numerical digits may be able 
   to be read easily by human eyes.

0 black -> actually the darker gray which is darker than "8".
1 brown
2 red
3 orange
4 yellow
5 green
6 blue
7 purple
8 gray
9 white -> actually brighter than standard white.

 Options : Not yet implemented.

 Reference: https://en.wikipedia.org/w/index.php?title=Electronic_color_code 

=head1 OPTION

  -= N ; skip coloring on the first N lines. 

=head1 TRY

  resistorcc --help | resistorcc 

=head1 SEE ALSO

  App::colorplus -- `colorplus -0' deletes the colros given by ANSI escape code. 

=head1 AUTHOR

下野寿之 Toshiyuki SHIMONO <bin4tsv@gmail.com> The Institute of Statistical Mathematics, a visiting researcher. 

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020-2023 Toshiyuki SHIMONO. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1 ;
