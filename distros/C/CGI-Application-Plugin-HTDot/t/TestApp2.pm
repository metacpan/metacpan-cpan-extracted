package TestApp2;

use strict;
use base ("CGI::Application::Plugin::HTDot", "CGI::Application");

# Extend load_tmpl() with some default options. . .
sub load_tmpl {
    my ($self, $tmpl_file, @extra_params) = @_;

    push @extra_params, "die_on_bad_params", "0";

    return $self->SUPER::load_tmpl($tmpl_file, @extra_params);
}

1;
