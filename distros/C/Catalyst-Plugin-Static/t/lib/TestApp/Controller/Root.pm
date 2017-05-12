package TestApp::Controller::Root;
use strict;
use warnings;
use base qw/Catalyst::Controller/;

__PACKAGE__->config(namespace => '');

sub default : Private {
    my ( $self, $c ) = @_;
    $c->serve_static;
}

1;

