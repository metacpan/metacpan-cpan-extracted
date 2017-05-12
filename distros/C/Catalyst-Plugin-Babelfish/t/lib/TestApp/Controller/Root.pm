package TestApp::Controller::Root;
use warnings;
use strict;

use base 'Catalyst::Controller';

__PACKAGE__->config( namespace => q{} );

sub hello : Global {
    my( $self, $c ) = @_;
    $c->res->body( $c->l10n->t( 'main.hello' ) );
}

sub hello_fr : Global {
    my( $self, $c, $key ) = @_;
    $c->l10n->locale('fr_FR');
    $c->res->body( $c->l10n->t( 'main.hello' ) );
}

sub plural : Global {
    my( $self, $c ) = @_;
    my $count = $c->request->params->{count};

    $c->res->body( $c->l10n->t( 'main.nails' ,  { test => $count } ) );
}

1;
