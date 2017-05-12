package TestApp;

use strict;
use warnings;

use Catalyst;

__PACKAGE__->config(
    name                  => 'TestApp',
);

__PACKAGE__->setup;

sub default : Private {
    my ($self, $c) = @_;
    $c->stash->{LOOM} = 'TestApp::Layouts::index';
    $c->forward( 'View::Test' );
}

;1;
