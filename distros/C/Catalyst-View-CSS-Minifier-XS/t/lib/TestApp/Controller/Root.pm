package TestApp::Controller::Root;

use strict;
use warnings;

use parent 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub test : Local {
   my ( $self, $c ) = @_;
   $c->stash->{css} = 'foo';

   $c->forward( 'TestApp::View::CSS' );
}

1;
