package Bracket::Form::Password::Reset;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Model::DBIC';
with 'HTML::FormHandler::Render::Table';

has '+item_class' => ( default => 'Player' );
has_field 'password' => ( type    => 'Password' );
has_field 'confirm_password' => ( type    => 'PasswordConf' );
has_field 'submit' => ( type => 'Submit', value => 'Reset password' );

#sub validate {
#	my $self = shift;
#
#	# Check the given email to see that it exists in the database
#	my $is_valid =
#	  $self->schema->resultset('Player')
#	  ->find( { email => $self->field('email')->value } );
#	if ( !$is_valid ) {
#		$self->field('email')->add_error('Email not on file');
#	}
#	
#	return;
#}

no HTML::FormHandler::Moose;
__PACKAGE__->meta->make_immutable;
1
