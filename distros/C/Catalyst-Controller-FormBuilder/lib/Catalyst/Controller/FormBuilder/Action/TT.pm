package Catalyst::Controller::FormBuilder::Action::TT;

use strict;
use base qw/Catalyst::Controller::FormBuilder::Action/;

sub setup_template_vars {
    my ( $self, $controller, $c ) = @_;

    my $stash_name = $controller->_fb_setup->{stash_name};
    $c->stash->{$stash_name} = $controller->_formbuilder->prepare;
    $c->stash->{ $controller->_fb_setup->{obj_name} } =
      $controller->_formbuilder;
}

1;
