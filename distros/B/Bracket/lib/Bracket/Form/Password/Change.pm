package Bracket::Form::Password::Change;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Model::DBIC';
with 'HTML::FormHandler::Render::Table';

has '+item_class'            => ( default => 'Player' );
has_field 'current_password' => ( type    => 'Password', );
has_field 'password'         => ( type    => 'Password' );
has_field 'password_confirm' => ( type    => 'PasswordConf' );
has_field 'submit' => ( type => 'Submit', value => 'Change Password' );

sub validate {
	my $self = shift;

	# check current password against what's in the database
	my $is_valid =
	  $self->schema->resultset('Player')->find( { id => $self->item_id } )
	  ->check_password( $self->field('current_password')->value );
	if ( !$is_valid ) {
		$self->field('current_password')
		  ->add_error('Current password incorrect');
	}
	return;
}

no HTML::FormHandler::Moose;
__PACKAGE__->meta->make_immutable;
1
