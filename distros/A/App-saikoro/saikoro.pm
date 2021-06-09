package App::saikoro ;  
our $VERSION = '0.300' ; 
our $DATE = '2021-06-08T14:21+09:00' ; 

=encoding utf8

=head1 NAME

App::saikoro

=head1 SYNOPSIS

This module provides a Unix-like command `F<saikoro>'. 
This command `saikoro' is a random number generator. 
Just `saikoro' yielods the integer numbers between 1 and 6 (for 12 times).

=head1 DESCRIPTION

You can add many options such as : 
  
  saikoro -g 3  # You will get 3 numbers.
  saikoro -g 5,6 # You will get a table of random numbers in 5 rows and 6 columns. 
  saikoro -. 3 # Numbers from [0.000,6.000), with decimally 3 digtis under the floating point. 
  saikoro -y 1..10 # Numbers are 1 to 10. 
  
  saikoro -i , -g 12 # -i changes the output delimiter. 
  saikoro -s 123  # specifiy the random seed 123. 
  siakoro -2 0 # suppress the secondary informtion on STDERR.
  
  saikoro --help # give the (Japanese) help .
  saikoro --help en # give the English help but of the older version of `saikoro'.

=head1 SEE ALSO


=cut

1 ;
