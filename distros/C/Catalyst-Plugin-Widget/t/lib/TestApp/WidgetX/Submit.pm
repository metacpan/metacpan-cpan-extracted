package TestApp::WidgetX::Submit;

use Moose;

extends 'Catalyst::Plugin::Widget::Base';

has 'value' => ( is => 'rw', default => '' );


sub render {
	my ( $self ) = @_;

	'<input type="submit" value="' . $self->value . '">';
}


__PACKAGE__->meta->make_immutable;

1;

