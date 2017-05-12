package Bracket::Form::Password::ResetEmail;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Model::DBIC';
with 'HTML::FormHandler::Render::Simple';

has '+item_class' => ( default => 'Player' );
has_field 'email' => ( type    => 'Email', noupdate => 1 );
has_field 'submit' => ( type => 'Submit', value => 'Send email to reset password' );

sub validate {
	my $self = shift;

	# Check the given email to see that it exists in the database
	my $is_valid =
	  $self->schema->resultset('Player')
	  ->find( { email => $self->field('email')->value } );
	if ( !$is_valid ) {
		$self->field('email')->add_error('Email not on file');
	}
	
	return;
}

# Turn off update_model 

sub update_model {}

no HTML::FormHandler::Moose;
__PACKAGE__->meta->make_immutable;
1
