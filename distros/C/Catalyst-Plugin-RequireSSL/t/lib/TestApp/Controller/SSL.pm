package TestApp::Controller::SSL;

use strict;
use base 'Catalyst::Controller';

sub secured : Local {
    my ( $self, $c ) = @_;
    
    $c->require_ssl;
    
    $c->res->output( 'Secured' );
}

sub unsecured : Local {
    my ( $self, $c ) = @_;
    
    $c->res->output( 'Unsecured' );
}

sub maybe_secured : Local {
    my ( $self, $c ) = @_;
    
    $c->allow_ssl;
    
    $c->res->output( 'Maybe secured' );
}

sub test_detach : Local {
    my ( $self, $c ) = @_;
    
    $c->require_ssl;

    $c->res->redirect('http://www.mydomain.com/redirect_from_the_action');
    
    $c->res->output( 'Test detach' );
}


1;
