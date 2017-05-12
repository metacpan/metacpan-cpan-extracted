package TestApp::Controller::Disable;

use strict;
use warnings;
use base 'Catalyst::Controller::AllowDisable';

sub foo : Local {
    my ( $s , $c ) = @_;
    $c->res->body('foo');
}

1;
