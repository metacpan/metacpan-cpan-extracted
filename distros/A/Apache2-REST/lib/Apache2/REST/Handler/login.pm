package Apache2::REST::Handler::login ;
use strict ;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use base qw/Apache2::REST::Handler/ ;

my $SERIAL = 0 ;

=head1 NAME

Apache2::REST::Handler::login - POC for a login mecanism

=cut

=head2 GET

Returns a uid and a authentication token

=cut

sub GET{
    my ( $self , $req , $resp ) = @_ ;
    
    my $email = $req->param('email') ;
    my $password = $req->param('password') ;
    
    ## DUMMY
    if ( $email ne 'fail'){
        my $uid = $SERIAL++ ;
        $resp->data()->{'uid'} = $uid ;
        $resp->data()->{'authentication'} = md5_hex($uid.'toto') ;
        return Apache2::Const::HTTP_OK ;
    }
    ## DUMMY FAILURE
    $resp->message('Authentication failed') ;
    return Apache2::Const::HTTP_UNAUTHORIZED ;
    
}

=head2 isAuth

Allow GET or POST

=cut

sub isAuth{
    my ($self , $method , $req ) = @_ ;
    return $method eq 'GET' || 
           $method eq 'POST' ;
}

1;
