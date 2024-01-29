package ErrBodySyntax;

BEGIN { $ENV{'CGI_APP_RETURN_ONLY'} = 1 }
use sugar;
use base 'CGI::Application';

runmode hier ($k) {
    nope;
}

1;
