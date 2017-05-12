package Apache2::REST::ErrorOutputHandler::both ;
use strict ;
use base qw/Apache2::REST::ErrorOutputHandler/ ;


sub handle{
    my ($self , $e , $resp , $req  ) = @_ ;
    my $sig = Digest::MD5::md5_hex($e);
    $req->log_error( 'REST API ERROR CODE:'.$sig.':'.$e ) ;
    $resp->message('SERVER ERROR CODE:'.$sig.':'.$e);
}


1;
