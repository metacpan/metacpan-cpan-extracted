package App::1234567891 ;  
our $VERSION = '0.011' ; 
our $DATE = '2025-03-18T15:20+09:00' ; 

=encoding utf8

=head1 NAME

App::1234567891 - Yield the sequence like '12345678911234567892...' to know the text length by comparison. 

=head1 SYNOPSIS

This module provides a Unix-like command `F<1234567891>'. 

=head1 DESCRIPTION

By aligning with a text sequence such as "123456789112345678921234567893.."
you can quickly know the length of the character string with your eyes.  
The command `1234567891' (10-letter-command) on the terminal yields such sequences
also with a few options. The starting number and ending number can be given as arguments. 

-d DIGITS : The number DIGITS specifies the width of each original number. 1 when unspecified.
-f        : Fullwidth numerical digits are produced instead of the half size (ascii) digits.

=head1 SEE ALSO

1234567891 --help

man 1234567891

perldoc 1234567891

=cut

1 ;
