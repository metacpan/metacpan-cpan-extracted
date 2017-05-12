package TestApp3::Controller::Root;

use strict;
use warnings;

use parent 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub station : Local {
   my ( $self, $c ) = @_;
   $c->stash->{js} = 'station';
}

sub test : Local {
   my ( $self, $c ) = @_;
   $c->stash->{js} = 'test';

   $c->forward( 'TestApp3::View::JS' );
}

1;
