package Apache2::REST::ErrorOutputHandler::server ;
use strict ;
use Digest::MD5 ;

use base qw/Apache2::REST::ErrorOutputHandler/ ;



sub handle{
    my ($self , $e , $resp , $req   ) = @_ ;
    
    # Change newlines in e
    $e =~ s/$/ NEWLINE /s ;
    my $sig = Digest::MD5::md5_hex($e);
    $req->log_error('ERROR CODE:'.$sig.':'.$e);
    $resp->message('SERVER ERROR CODE:'.$sig);
}


1;
