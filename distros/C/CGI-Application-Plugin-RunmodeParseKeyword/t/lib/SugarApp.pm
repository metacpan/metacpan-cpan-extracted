package SugarApp;

BEGIN { $ENV{'CGI_APP_RETURN_ONLY'} = 1 }
use sugar;
use base 'CGI::Application';

startmode hier {
    $self->header_type('none');
    "hier"
}
runmode sweet ($pastry = "cookie") {
    $self->header_type('none');
    "sweet $pastry!";
}

1;
