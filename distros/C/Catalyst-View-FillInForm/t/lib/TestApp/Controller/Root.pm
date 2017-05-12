package # Hide from PAUSE
    TestApp::Controller::Root;
use strict;
use warnings;

__PACKAGE__->config(namespace => '');

use base 'Catalyst::Controller';

sub main :Path 
{ 
   my ( $self, $c ) = @_;

   my $params = {
      firstname => "John",
      lastname => "Doe",
      email => 'jdoe@gmail.com'
   };
   $c->stash( fillinform => $params );
   $c->forward( $c->view('TT' ) );
}

sub alt :Local 
{
  my ($self, $c) = @_;

   my $params = {
      firstname => "Mary",
      lastname => "Muffet",
      email => 'mmfuffet@gmail.com'
   };
  $c->req->params( $params ); 
  $c->stash( fillinform => 1 );
}

sub end : ActionClass('RenderView') {}

1;
