package  Apache2::REST::Handler::test::user ;

use base qw/Apache2::REST::Handler/  ;

=head1 NAME

Apache2::REST::Handler::test::user - Test dummy user handler

=cut


=head2 GET

Echoes a message.

=cut

sub GET{
    my ( $self , $req , $resp ) = @_ ;
    
    $resp->data()->{'user_message'} = 'You are accessing user '.$self->userid() ;
    $resp->data()->{'user'} = {
        'name' => "\x{111}\x{103}ng t\x{1ea3}i t\x{1ea1}i",
        'email' => 'jerome@eteve.net' ,
    };
    return Apache2::Const::HTTP_OK ;
}

=head2 isAuth

Allows GET

=cut

sub isAuth{
    my ( $self , $method , $req ) = @_ ;
    
    ## if not no auth token
    return $method eq 'GET' ;
    
}




1;
