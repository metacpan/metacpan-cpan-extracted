package CGIAPP_TestApp2;

use strict;
use base ("CGI::Application::Plugin::HTCompiled", "CGI::Application");

# Extend load_tmpl() with some default options. . . 
sub load_tmpl
{
    my ($self, $tmpl_file, @extra_params) = @_;

    return $self->SUPER::load_tmpl($tmpl_file, @extra_params);
}

1;

