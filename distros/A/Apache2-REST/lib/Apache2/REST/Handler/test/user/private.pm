package Apache2::REST::Handler::test::user::private ;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use base qw/Apache2::REST::Handler/  ;

=head1 NAME

Apache2::REST::Handler::test::user::private - Private part of test user

=cut

=head2 GET

Echoes a message

=cut

sub GET{
    my ( $self , $req , $resp ) = @ _;
    $resp->status(Apache2::Const::HTTP_OK);
    $resp->data()->{'private_message'} = 'This is a private part of '.$self->parent()->userid() ;
    return Apache2::Const::HTTP_OK ;
}

=head2 isAuth

Allows all if auth param contains token given by /login for the user.

Allows nothing otherwise

=cut

sub isAuth{
    my ( $self , $method , $req ) = @_ ;
    my $uid = $self->parent()->userid() ;
    
    my $candMD5 = md5_hex($uid.'toto') ;
    unless( $req->param('auth') ){ return 0 ;}
    if ( $req->param('auth') ne $candMD5 ){ return 0 ;}
    
    ## If its ok, the user can do everything
    return 1 ;
    
}

1 ;
