package Apache2::REST::Handler::test::user::location ;

use base qw/Apache2::REST::Handler/  ;

=head1 NAME

Apache2::REST::Handler::test::user::location - Fake location resource for a user.

=cut

=head2 GET

Returns a fake collection of locations.

=cut

sub GET{
    my ( $self , $req , $resp ) = @ _;
    $resp->data()->{'location_message'} = 'This is location of user '.$self->parent()->userid() ;
    $resp->data()->{'locations'} =[ { 'lat' => '45.222233'  , 'long' => '45.564354343' },
                                    { 'lat' => '46.222233'  , 'long' => '45.564354343' },
                                    { 'lat' => '47.222233'  , 'long' => '45.564354343' },
                                  ]
                                    ;
    return Apache2::Const::HTTP_OK ;
}

1 ;
