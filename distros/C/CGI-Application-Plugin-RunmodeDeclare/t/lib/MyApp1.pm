package MyApp1;

BEGIN { $ENV{'CGI_APP_RETURN_ONLY'} = 1 }

use base 'CGI::Application';
use CGI::Application::Plugin::RunmodeDeclare invocant => '$c';

sub cgiapp_prerun
{
    shift->header_type('none')
}

errormode oops($error)
{
    "Oh noez!";
}

startmode begin
{
    "Go"
}

runmode other($foo, $bar, @more)
{
    return $c->get_current_runmode
}

1;

