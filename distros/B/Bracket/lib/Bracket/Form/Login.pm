package Bracket::Form::Login;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
with 'HTML::FormHandler::Render::Table';

has_field 'email'    => ( type    => 'Email', );
has_field 'password' => ( type    => 'Password' );
has_field 'submit'   => ( type => 'Submit', value => 'Login' );

no HTML::FormHandler::Moose;
__PACKAGE__->meta->make_immutable;
1
