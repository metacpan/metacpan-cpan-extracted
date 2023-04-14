package App::diroctopus ;  
our $VERSION = '0.025' ; 
our $DATE = '2023-04-06T11:30+09:00' ; 

=encoding utf8

=head1 NAME

App::diroctopus -- shows the longest directory branch paths (most apart each other) of a given directory.

=head1 SYNOPSIS

This module provides a Unix-like command `F<diroctopus>'. 

=head1 DESCRIPTION

 diroctopus [-g NUM] DIR 

  This command outputs the longest dirctory paths under the specified directory DIR.
  The first of the output shows the deepest directory path ("DP") under DIR. 
  The next row on the output shows the farthest DP from any of "above", repeatedly.
  NUM after `-g' specifies the number of rows by this repetition, and 12 if not specified. 
  (Yellow colored directory on each output of DP is the "branch point" in a sense. )
  DIR is regarded to be "." (current directory) if not specified.

  Compared from the outpus of `find . -type d' (or `ls -d **/*(/)' in zsh), 
  the result of `diroctopus' suppresses the DP not reaching the "terminus directory"
  (a ternminus directory here means a directory who has no sub-directory any more).

  `perldoc App::diroctopus' shows English help. 
  `perldoc diroctopus' and `diroctopus --help' shows Japanese help. 

 Options (selected): 
  -. 0 : Specifies not to follow any dot file (whose name begins with period character).
  -g NUM : The maximum number of directory paths to be shown as a branch.
  -l NUM : The minimum number of the "distance" from branch that a shown directory has.
  -s NUM : A random seed for reproductivity because "farthest DPs" are chosen arbitrarily.

=head1 NOTE

  The explanation above may not be enough. Japanese help explains more. 
  And this progragm is under development, its functions and output should be refined more.

=head1 SEE ALSO

  App::dirstrata -- gives minute hierarchial information about a directory using a triangular matrix.

=head1 AUTHOR

下野寿之 Toshiyuki SHIMONO <bin4tsv@gmail.com> The Institute of Statistical Mathematics, a visiting researcher. 

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019-2023 Toshiyuki SHIMONO. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1 ;
