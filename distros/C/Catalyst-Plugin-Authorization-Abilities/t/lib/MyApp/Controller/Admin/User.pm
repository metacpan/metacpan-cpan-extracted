package MyApp::Controller::Admin::User;
use Moose;
use namespace::autoclean;
use HTML::FormFu;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

MyApp::Controller::Admin::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

Redirect to '/admin/user/list'

=cut
sub index :Path Args(0) {
    my ( $self, $c ) = @_;
    $c->res->redirect('/admin/user/list');
    $c->detach;
}


=head2 list

List all users

=cut
sub base_user : Chained('/') :PathPart('admin/user') : CaptureArgs(0)   {
  my ( $self, $c ) = @_;

  # Save rs of users
  $c->stash->{users} = $c->model('DBIC::User');
}

=head2 user

used to chained action

=cut
sub user : Chained('/') :PathPart('admin/user') : CaptureArgs(1){
  my ( $self, $c, $id ) = @_;

  # Save id of user
  $c->stash->{user_id} = $id;
  $c->stash->{user} = $c->model('DBIC::User')->find({ id => $id });
}

=head2 list_user

List all users

=cut
sub list_user : Chained('base_user') :PathPart('list') Args(0){
    my ( $self, $c ) = @_;

}

=head2 view_user

View a user

=cut
sub view_user : Chained('user') :PathPart('view') Args(0){
    my ( $self, $c ) = @_;

}

=head2 add_user

add a user

=cut
sub add_user : Chained('base_user') :PathPart('add') Args(0) {
  my ( $self, $c ) = @_;

  $c->stash->{legend} = "Add_a_user";
  $c->forward('edit_user');
}

=head2 del_user

delete a user

=cut
sub del_user : Chained('user') :PathPart('del') Args(0){
    my ( $self, $c ) = @_;

    $c->stash->{user}->delete;

    $c->res->redirect('/admin/user/list');
    $c->detach;
}

=head2 edit_user

edit a user

=cut
sub edit_user : Chained('user') :PathPart('edit') Args(0){
  my ( $self, $c ) = @_;

  if ($c->stash->{user_id} ){
    $c->stash->{legend} = "Edit_a_user";

    my $user_roles_id;
    foreach my $role ( $c->stash->{user}->user_roles ){
      $user_roles_id->{$role->id} = 1;
    }
    $c->stash->{user_roles_id} = $user_roles_id;


    my $user_actions_id;
    foreach my $action ( $c->stash->{user}->actions ){
      $user_actions_id->{$action->id} = 1;
    }
    $c->stash->{user_actions_id} = $user_actions_id;
  }

  $c->stash->{allroles}   = $c->model('DBIC::Role');
  $c->stash->{allactions} = $c->model('DBIC::Action');


  # form FormFu ------------------------------------
  my $form = HTML::FormFu->new;

  my $fs = $form->element('Fieldset')->legend($c->stash->{legend})->attrs({ class => 'alt'});


  $fs->element(
	       {type    => 'Text',
		name    => 'name',
		label   => 'Name',
		constraint => ['Required'],
	       });

  $fs->element(
	       {type    => 'Text',
		name    => 'username',
		label   => 'Login',
		constraint => ['Required'],
	       });

  $fs->element(
	       {type    => 'Password',
		name    => 'password',
		label   => 'Password',
	       });

  $fs->element(
	       {type    => 'Text',
		name    => 'email',
		label   => 'Email',
		constraint => ['Required', 'Email' ],
	       });

  $fs->element(
	       {type    => 'Select',
		name    => 'active',
		label   => 'Status',
		options => [ 
			    [ 1 => 'active'   ],
			    [ 0 => 'noactive' ] ],
	       });

  $fs->element(
	       {type    => 'Submit',
		name    => 'submit',
                value   => 'Save',
		attributes => {
			       class => 'positive',
			      },
	       });

  $form->process($c->request);
  $c->stash->{form} = $form;



  if ( $form->submitted_and_valid ) {

    my $user = $c->model('DBIC::User')->update_or_create({
			      id => $c->stash->{user_id},
			      name        => $c->req->params->{'name'},
			      username    => $c->req->params->{'username'},
                              password    => $c->req->params->{'password'},
                              email       => $c->req->params->{'email'},
                              active      => $c->req->params->{'active'},
                          });
    $c->res->redirect('/admin/user/list');
    $c->detach;
  }
  elsif ( !$form->submitted && $c->stash->{user}) {
    $form->model->default_values( $c->stash->{user} );
  }
}


=head2 userrole

Update roles

=cut
sub userrole : Chained('user') :PathPart('role') Args(0){
    my ( $self, $c ) = @_;


    my @roles = ref ($c->req->params->{'role'}) eq "ARRAY" ?
      $c->req->params->{'role'} : [ $c->req->params->{'role'}];



    $c->model('DBIC::UserRole')->search({
					    user_id => $c->stash->{user_id},
					    })->delete;


    if (  $c->req->params->{'role'} ){
      foreach my $role ( @{$roles[0]} ){
	$c->model('DBIC::UserRole')->update_or_create({
					     user_id => $c->stash->{user_id},
 					     role_id => $role,
					   });
      }
    }


    $c->res->redirect('/admin/user/' .  $c->stash->{user_id} . '/edit');
    $c->detach;
}

=head2 useraction

Update actions

=cut
sub useraction : Chained('user') :PathPart('action') Args(0){
    my ( $self, $c ) = @_;


    my @actions = ref ($c->req->params->{'action'}) eq "ARRAY" ?
      $c->req->params->{'action'} : [ $c->req->params->{'action'}];



    $c->model('DBIC::UserAction')->search({
					    user_id => $c->stash->{user_id},
					    })->delete;


    if (  $c->req->params->{'action'} ){
      foreach my $action ( @{$actions[0]} ){
	$c->model('DBIC::UserAction')->update_or_create({
					     user_id => $c->stash->{user_id},
 					     action_id => $action,
					   });
      }
    }


    $c->res->redirect('/admin/user/' .  $c->stash->{user_id} . '/edit');
    $c->detach;
}






=head1 AUTHOR

Daniel Brosseau <dab@catapulse.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
