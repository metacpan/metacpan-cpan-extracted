package TestApp::Widget::Button;

use Moose;

extends 'Catalyst::Plugin::Widget::Base';
with    'Catalyst::Plugin::Widget::ThroughView';

has '+view' => ( is => 'rw', default => 'TT' );
has 'value' => ( is => 'rw', default => '' );


after populate_stash => sub {
	my ( $self ) = @_;

	$self->context->stash( value => $self->value );
};

__PACKAGE__->meta->make_immutable;

1;

