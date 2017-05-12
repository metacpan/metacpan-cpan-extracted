package CatalystX::RoseIntegrator::Action::TT;

use strict;
use base qw/CatalystX::RoseIntegrator::Action/;

sub setup_template_vars {
    my ($self, $controller, $c) = @_;

    $c->stash->{$controller->_rinteg_setup->{obj_name}} = $controller->form;
}

1;
