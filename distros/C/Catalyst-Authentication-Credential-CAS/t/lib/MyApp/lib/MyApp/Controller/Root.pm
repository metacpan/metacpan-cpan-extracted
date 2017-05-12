package MyApp::Controller::Root;

use namespace::autoclean;
use Moose;

BEGIN { extends qw( Catalyst::Controller ) }


__PACKAGE__->config( namespace => '' );


sub index :Path :Args(0) {
  my ( $self, $c ) = @_;

  use Data::Dumper;
  if( $c->authenticate ) {
    $c->res->status( 200 );
    $c->res->body( 'Access Granted' );
  }
  else {
    $c->res->status( 401 );
    $c->res->body( 'Access Denied' );
  }
}

sub default :Path {
  my ( $self, $c ) = @_;

  $c->response->status( 404 );
  $c->response->body( 'Page not found' );
}


__PACKAGE__->meta->make_immutable;

1
__END__
