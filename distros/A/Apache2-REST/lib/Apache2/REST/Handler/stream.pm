package Apache2::REST::Handler::stream ;

use strict ;
use base qw/Apache2::REST::Handler/  ;

use Apache2::REST::Stream::TestStream;

use Apache2::Const qw( 
                       :common :http 
                       );

=head2 NAME

Apache2::REST::Handler::stream - test handler access '/test/stream' to test a streaming response

=cut

=head2 GET

Sets the response as a streaming one and returns OK on get.

=cut

sub GET{
    my ($self, $req , $resp ) = @_ ;
    
    if ( $req->param('die') ){
        die "This is an error\n" ;
    }
    
    $resp->data()->{'test_mess'} = 'This is a GET test message on a streaming ressource' ;
    $resp->stream(Apache2::REST::Stream::TestStream->new($req->param('chunks') || 10));
    ## It is OK
    return Apache2::Const::HTTP_OK ;
}

=head2 isAuth

Any method is allowed

=cut

sub isAuth{
    my ($self , $method , $req ) = @_ ;
    return 1 ;
}



1;
