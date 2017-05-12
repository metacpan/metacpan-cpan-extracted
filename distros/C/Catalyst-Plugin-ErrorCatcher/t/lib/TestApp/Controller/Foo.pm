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

sub crash_user : Local {
    my ( $self, $c ) = @_;

    $c->authenticate(
        {
            username => 'buffy',
            password => 'stake'
        }
    );

    die 'Vampire';
}

sub referer : Local {
    my ( $self, $c ) = @_;

    # manually set a referer so we can test for it
    $c->request->headers->header(Referer => 'http://garlic-weapons.tv');

    $c->forward( 'crash' );
}

1;
