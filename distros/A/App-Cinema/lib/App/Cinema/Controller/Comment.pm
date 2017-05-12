package App::Cinema::Controller::Comment;
use Moose;
use namespace::autoclean;

BEGIN {
	extends qw/Catalyst::Controller::FormBuilder/;
	our $VERSION = $App::Cinema::VERSION;
}

=head1 NAME

App::Cinema::Controller::Comment - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
	my ( $self, $c ) = @_;

	$c->response->body('Matched App::Cinema::Controller::Comment in Comment.');
}

=head2 add

=cut

sub add : Local Form {
	my ( $self, $c, $arg ) = @_;
	if ( !$c->user_exists ) {
		$c->flash->{error} = $c->config->{need_login_errmsg};
		$c->res->redirect( $c->uri_for('/menu/about') );
		return 0;
	}
	my $form    = $self->formbuilder;
	my $comment = $form->field('desc');
	if ( $form->submitted && $form->validate ) {
		if ( $form->submitted eq 'Preview' ) {
			$c->stash->{message} = $comment;
		}
		elsif ( $form->submitted eq 'Save' ) {
			$c->model('MD::Comment')->create(
				{
					uid    => $c->user->obj->username(),
					content  => $comment,
					e_time => HTTP::Date::time2iso(time),
				}
			);
			$c->flash->{message} = 'Created Comment.';
			$c->res->redirect( $c->uri_for('/comment/view') );
		}
	}
}

=head2 view

=cut

sub view : Local {
	my ( $self, $c ) = @_;
	my $rs =
	  $c->model('MD::Comment')
	  ->search( undef, { order_by => { -desc => 'e_time' } } );
	$c->stash->{news} = $rs;
}

=head1 AUTHOR

Jeff Mo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

#__PACKAGE__->meta->make_immutable;

