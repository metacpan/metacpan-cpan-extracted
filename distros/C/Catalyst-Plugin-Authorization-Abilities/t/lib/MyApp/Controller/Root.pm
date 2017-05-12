package MyApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

MyApp::Controller::Root - Root Controller for MyApp

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

}

=head2 with_role_admin

Page '/with_role_admin'

=cut

sub with_role_admin :Path('with_role_admin') :Args(0) {
    my ( $self, $c ) = @_;

    if (! $c->check_user_roles(qw/admin/)) {
      $c->res->redirect('/access_denied');
    }
    $c->response->body( 'OK : role : admin' );
}

=head2 with_role_member_and_moderator

Page '/with_role_member_and_moderator'

=cut

sub with_role_member_and_moderator :Path('with_role_member_and_moderator' ):Args(0) {
    my ( $self, $c ) = @_;

  if (! $c->check_user_roles(qw/member moderator/)) {
      $c->res->redirect('/access_denied');
  }
    $c->response->body( 'OK : role member and moderator' );
}


=head2 can_create_Page

Page '/can_create_Page'

=cut

sub can_create_Page :Path('can_create_Page' ):Args(0) {
    my ( $self, $c ) = @_;

    eval { $c->assert_user_ability('create_Page') };
    if ( $@ ){
      $c->res->redirect('/access_denied');
    }
    $c->response->body( 'OK : can create_Page' );
}

=head2 can_delete_Comment

Page '/can_delete_Comment'

=cut

sub can_delete_Comment :Path('can_delete_Comment' ):Args(0) {
    my ( $self, $c ) = @_;

    eval { $c->assert_user_ability('delete_Comment') };
    if ( $@ ) {
      $c->res->redirect('/access_denied');
    }
    $c->response->body( 'OK : can delete_Comment' );
}


=head2 can_recursive_roles

Page '/can_recursive_roles'

=cut

sub can_recursive_roles :Path('can_recursive_roles' ):Args(0) {
    my ( $self, $c ) = @_;

    eval { $c->assert_user_ability('can_recursive_roles') };
    if ( $@ ){
      $c->res->redirect('/access_denied');
    }
    $c->response->body( 'OK : recursive roles work' );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}


=head2 access_denied

access_denied page

=cut

sub access_denied :Path('access_denied') {
    my ( $self, $c ) = @_;
    $c->response->body( 'Access_denied !' );
    $c->response->status(401);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Daniel Brosseau C<dab@catapulse.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
