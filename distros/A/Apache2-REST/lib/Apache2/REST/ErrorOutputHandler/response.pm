package Apache2::REST::ErrorOutputHandler::response ;
use strict ;
use base qw/Apache2::REST::ErrorOutputHandler/ ;


sub handle{
    my ($self , $e , $resp , $req  ) = @_ ;
    $resp->message('SERVER ERROR: '.$e);
}


1;
