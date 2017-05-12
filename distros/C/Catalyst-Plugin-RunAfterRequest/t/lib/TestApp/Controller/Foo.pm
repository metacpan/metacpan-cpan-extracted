package TestApp::Controller::Foo;
use base qw(Catalyst::Controller);

use strict;
use warnings;

our @data;

sub demonstrate_model : Local {
    my ( $self, $c ) = @_;
    $c->res->body('YAY');
    $c->model('Foo')->demonstrate;
}

sub demonstrate_model_with_around : Local {
    my ( $self, $c ) = @_;
    $c->res->body('YAY');
    $c->model('Bar')->demonstrate;
}

sub demonstrate_plugin : Local {
    my ( $self, $c ) = @_;
    $c->res->body('YAY');

    $c->run_after_request(
        sub { push @data, 'alpha' },
        sub { push @data, 'beta' },
        sub { push @data, ref shift },
    );

}

1;
