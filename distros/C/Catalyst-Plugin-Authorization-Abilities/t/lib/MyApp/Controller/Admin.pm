package MyApp::Controller::Admin;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

MyApp::Controller::Admin - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub auto : Private {
  my ( $self, $c ) = @_;

  if ( ! $c->check_user_roles(qw/admin/) ){
    $c->response->redirect( '/access_denied' );
    $c->detach;
  }
  return 1;
}

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;

}


=head1 AUTHOR

Daniel Brosseau C<dab@catapulse.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
