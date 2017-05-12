package Apache2::REST::AppAuth::Echo;
use warnings ;
use strict ;
use Apache2::Const ;

use base qw/Apache2::REST::AppAuth/ ;

=head2 NAME

Apache2::REST::AppAuth::Echo - A app auth plugin which echoes some property and refuses access.

=cut

=head2 authorize

Authorize app is X-AppAuth header equals 'please'

=cut

sub authorize{
    my ( $self , $req , $resp ) = @_ ;
    
    my $header = $req->headers_in()->{'X-AppAuth'} || '' ;
    if ( $header eq 'please' ){
        return 1 ;
    }
    
    $resp->status( Apache2::Const::HTTP_UNAUTHORIZED ) ;
    $resp->message("Access denied. X-AppAuth was $header. Be polite") ;
    return 0 ;
}

1;
