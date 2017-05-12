package MyApp::Controller::Admin::Role;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

MyApp::Controller::Admin::Role - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

Redirect to '/admin/role/list'

=cut


sub index :Path Args(0) {
    my ( $self, $c ) = @_;
    $c->res->redirect('/admin/role/list');
    $c->detach;
}


=head2 list

List all roles

=cut
sub base_role : Chained('/') :PathPart('admin/role') : CaptureArgs(0)   {
  my ( $self, $c ) = @_;

  # Save rs of roles
  $c->stash->{roles} = $c->model('DBIC::Role');
}

=head2 role

used to chained action

=cut
sub role : Chained('/') :PathPart('admin/role') : CaptureArgs(1){
  my ( $self, $c, $id ) = @_;

  # Save id of role
  $c->stash->{role_id} = $id;
  $c->stash->{role} = $c->model('DBIC::Role')->find($id);

}

=head2 list_role

List all roles

=cut
sub list_role : Chained('base_role') :PathPart('list') Args(0){
    my ( $self, $c ) = @_;
}

=head2 view_role

View a role

=cut
sub view_role : Chained('role') :PathPart('view') Args(0){
    my ( $self, $c ) = @_;

}

=head2 add_role

add a role

=cut
sub add_role : Chained('base_role') :PathPart('add') Args(0) {
  my ( $self, $c ) = @_;

  $c->stash->{legend} = "Add_a_role";
  $c->forward('edit_role');
}

=head2 del_role

delete a role

=cut
sub del_role : Chained('role') :PathPart('del') Args(0){
    my ( $self, $c ) = @_;

    $c->stash->{role}->delete;

    $c->res->redirect('/admin/role/list');
    $c->detach;
}



=head2 edit_role

edit a role

=cut
sub edit_role : Chained('role') :PathPart('edit') Args(0){

  my ( $self, $c ) = @_;

  if ($c->stash->{role_id} ){

    $c->stash->{legend} = "Edit_a_role";

    my $role_roles_id;
    foreach my $role ( $c->stash->{role}->roles ){
      $role_roles_id->{$role->id} = 1;
    }
    $c->stash->{role_roles_id} = $role_roles_id;

    my $role_actions_id;
    foreach my $action ( $c->stash->{role}->actions ){
      $role_actions_id->{$action->id} = 1;
    }
    $c->stash->{role_actions_id} = $role_actions_id;

  }

  $c->stash->{allroles}   = $c->model('DBIC::Role');
  $c->stash->{allactions} = $c->model('DBIC::Action');

  # form FormFu ------------------------------------
  my $form = HTML::FormFu->new;

  my $fs = $form->element('Fieldset')->legend($c->stash->{legend})->attrs({ class => 'alt'});


  $fs->element(
	       {type    => 'Text',
		name    => 'name',
		label   => 'Role Name',
		constraint => ['Required'],
	       });


  $fs->element(
	       {type    => 'Select',
		name    => 'active',
		label   => 'Status',
		options => [ 
			    [ 1 => 'active'   ],
			    [ 0 => 'noactive' ] ],
                default => 1,
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

    my $role = $c->model('DBIC::Role')->update_or_create({
			      id      => $c->stash->{role_id},
			      name    => $c->req->params->{'name'},
			      active  => $c->req->params->{'active'},
                          });
    $c->res->redirect('/admin/role/list');
    $c->detach;
  }
  elsif ( !$form->submitted && $c->stash->{role}) {
    $form->model->default_values( $c->stash->{role} );
  }
}


=head2 action

Update actions

=cut
sub roleaction : Chained('role') :PathPart('action') Args(0){
    my ( $self, $c ) = @_;


    my @actions = ref ($c->req->params->{'action'}) eq "ARRAY" ?
      $c->req->params->{'action'} : [ $c->req->params->{'action'}];



    $c->model('DBIC::RoleAction')->search({
					    role_id => $c->stash->{role_id},
					    })->delete;


    if (  $c->req->params->{'action'} ){
      foreach my $action ( @{$actions[0]} ){
	$c->model('DBIC::RoleAction')->update_or_create({
					     role_id => $c->stash->{role_id},
 					     action_id => $action,
					   });
      }
    }


    $c->res->redirect('/admin/role/' .  $c->stash->{role_id} . '/edit');
    $c->detach;
}


=head2 role

Update roles

=cut
sub rolerole : Chained('role') :PathPart('role') Args(0){
    my ( $self, $c ) = @_;

    my @roles = ref ($c->req->params->{'inherits_from_id'}) eq "ARRAY" ?
      $c->req->params->{'inherits_from_id'} : [ $c->req->params->{'inherits_from_id'}];


    $c->model('DBIC::RoleRole')->search({
        				    role_id => $c->stash->{role_id},
        				    })->delete;

    if (  $c->req->params->{'inherits_from_id'} ){
      foreach my $role ( @{$roles[0]} ){

	$c->model('DBIC::RoleRole')->update_or_create({
					     role_id => $c->stash->{role_id},
 					     inherits_from_id => $role,
					   });
      }
    }


    $c->res->redirect('/admin/role/' .  $c->stash->{role_id} . '/edit');
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
