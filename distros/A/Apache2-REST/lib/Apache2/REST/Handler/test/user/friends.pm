package Apache2::REST::Handler::test::user::friends ;

use strict ;
use base qw/Apache2::REST::Handler::test/ ;

=head1 NAME

Apache2::REST::Handler::test::user::friends - Fake module for the friends resource of a user.

=head1 SYNOPSIS

Try accessing /test/1/friends/ and then /test/1/friends/2/
(in test app)

=cut

=head2 GET

Echoes a fake list of friends id that can serve as user.

=cut

sub GET{
    my ( $self , $req , $resp ) = @_ ;
    
    $resp->data()->{'friends'} = [ 1234, 3456, 726, 1] ;
    return Apache2::Const::HTTP_OK ;
}

1;
