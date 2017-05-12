package Apache2::REST::ErrorOutputHandler ;
use strict ;


sub new{
    my ($class) = @_ ;
    my $self = {} ;
    return bless $self , $class ;
}


=head2 handle

Handles an error and do something with the response if needed.

=cut

sub handle{
    my ( $self , $error , $response , $request  ) = @_ ;
    die "Implement this\n" ;    
}


1;
