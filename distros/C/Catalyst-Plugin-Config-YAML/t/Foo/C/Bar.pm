package Foo::C::Bar;

use base 'Catalyst::Base';

# dummy component

sub new {
	my ($self, $context, $config) = @_;
	
	$self->config($config);
	
	return $self;
}

1;