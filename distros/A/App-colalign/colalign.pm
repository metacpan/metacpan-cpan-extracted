package App::colalign ;  
our $VERSION = '0.022' ; 
our $DATE = '2023-08-12T00:40+09:00' ; 

=encoding utf8

=head1 NAME

App::colalign -- Align the number of columns on each line upon TSV input.

=head1 SYNOPSIS

This module provides a Unix-like command `F<colalign>'. 
This command `colalign' gets the TSV formatted file into the output 
consisting with all the lines each of which packed with the number 
of columns at least NUM where NUM is specified by the option -a. 
It is useful when a large TSV file containg glitches such as 
containing extra new line characters in the middle of a line. 

=head1 DESCRIPTION

 colalign -a NUM  # Align the number of columns into the number NUM. 

 Options : 

  -c str : Specifies the character string replacing an extra new line character. If not specified it is "#n#".
  -i str : Specifies the column separator on the input. If not specified it is "\t" (tab character).
  -1 REGEX : If a line contains only one column : if it matches the REGEX, it is regarded as a next line. Otherwise, it is regarded as of the previous line.

=head1 SEE ALSO

   App::colsummary
   App::csel
   App::collen (to be published, soon after Aug 2023)
   App::alluniq (to be published, soon after Aug 2023)

=head1 AUTHOR

下野寿之 Toshiyuki SHIMONO <bin4tsv@gmail.com> The Institute of Statistical Mathematics, a visiting researcher. 

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023 Toshiyuki SHIMONO. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1 ;
