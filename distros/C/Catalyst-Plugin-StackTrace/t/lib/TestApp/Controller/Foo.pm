package TestApp::Controller::Foo;

use strict;
use warnings;
use base 'Catalyst::Controller';

use TestApp::Exception;

sub ok : Local {
    my ( $self, $c ) = @_;
    
    $c->res->output( 'ok' );
}

sub not_ok : Local {
    my ( $self, $c ) = @_;
    
    $c->forward( 'crash' );
}

sub not_ok_obj : Local {
    my ( $self, $c ) = @_;
    
    $c->forward( 'crash_obj' );
}

sub crash : Local {
    my ( $self, $c ) = @_;
    
    three();
}

sub crash_obj : Local {
    my ( $self, $c ) = @_;

    die TestApp::Exception->new;
}

1;
