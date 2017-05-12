package Articulate::Routes::Login;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Routes';
use Articulate::Syntax::Routes;
use Articulate::Service;

post '/login' => sub {
  my ( $self, $request ) = @_;
  my $user_id  = $request->params->{'user_id'};
  my $password = $request->params->{'password'};
  my $redirect = $request->params->{'redirect'} // '/';
  $self->service->process_request(
    login => {
      user_id  => $user_id,
      password => $password
    }
  );
};

post '/logout' => sub {
  my ( $self, $request ) = @_;
  my $redirect = $request->params->{'redirect'} // '/';
  $self->service->process_request( logout => {} );
};
