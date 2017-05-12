package MyApp::Controller::Admin::Action;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

MyApp::Controller::Admin::Action - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

Redirect to '/admin/action/list'

=cut
sub index :Path Args(0) {
    my ( $self, $c ) = @_;
    $c->res->redirect('/admin/action/list');
    $c->detach;
}

=head2 list

List all actions

=cut
sub base_action : Chained('/') :PathPart('admin/action') : CaptureArgs(0)   {
  my ( $self, $c ) = @_;

  # Save rs of actions
  $c->stash->{actions} = $c->model('DBIC::Action')->search({});
}

=head2 action

used to chained action

=cut
sub action : Chained('/') :PathPart('admin/action') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;

  $c->stash->{action_id} = $id;
  $c->stash->{action} = $c->model('DBIC::Action')->find(
                                                    { id => $id }
                                                   );
}



=head2 list_action

List all actions

=cut
sub list_action : Chained('base_action') :PathPart('list') Args(0){
    my ( $self, $c ) = @_;
}

=head2 view_action

View a action

=cut
sub view_action : Chained('action') :PathPart('view') Args(0){
    my ( $self, $c ) = @_;

}

=head2 add_action

add a action

=cut
sub add_action : Chained('base_action') :PathPart('add') Args(0) {
  my ( $self, $c ) = @_;

  $c->stash->{legend} = "Add_a_action";
  $c->forward('edit_action');
}

=head2 del_action

delete a action

=cut
sub del_action : Chained('action') :PathPart('del') Args(0){
    my ( $self, $c ) = @_;

    $c->stash->{action}->delete;

    $c->flash->{message} = "action deleted";
    $c->res->redirect('/admin/action/list');
    $c->detach;
}


=head2 edit

edit a action

=cut
sub edit_action : Chained('action') :PathPart('edit') Args(0){
  my ( $self, $c ) = @_;


  if (defined $c->stash->{action} ){
    $c->stash->{legend} = "Edit_a_action";
  }



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

    my $actions = $c->model('DBIC::Action'); 

    # Build action-----------
    my $action  = $actions->update_or_create({
                             id   => $c->stash->{action_id},
                             name => $c->req->params->{'name'},
                          });


    $c->flash->{message} = "action added";

    $c->res->redirect( $c->uri_for( '/admin/action/list' ));
    $c->detach;
  }
  elsif ( !$form->submitted && $c->stash->{action}) {
    $form->model->default_values( $c->stash->{action} );
  }
}


=head1 AUTHOR

Daniel Brosseau E<lt>dab@catapulse.orgE<gt>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
