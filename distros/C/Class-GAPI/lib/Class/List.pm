package Class::List         ;

use Class::GAPI 		    ;
our @ISA = qw(Class::GAPI)  ;

my $VERSION = '1.1' 	    ; 
use strict                  ; 

sub new {
	my $class = shift     ;
	return (bless \@_, $class) ;   
}

1 ;

############# CODE ENDS HERE #####################

=head1 NAME

Class::List - Array class which inherits the features of Class::GAPI 

=head1 DESCRIPTION

See Class::GAPI for usage. Generally this is not used by itself. 

=head1 AUTHOR

Matthew Sibley 
matt@itoperators.com

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2005 IT Operators  (http://www.itoperators.com) 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
