package TestApp3;

use strict;
use base ("CGI::Application::Plugin::HTDot", "CGI::Application");

sub setup {
    my $self = shift;
    $self->add_callback( 'load_tmpl', \&my_load_tmpl );
}

# Extend load_tmpl() with some default options. . .
sub my_load_tmpl {
    my ( $self, $ht_params, $tmpl_params, $tmpl_file ) = @_;

    $ht_params->{ die_on_bad_params } = 0;
}

1;
