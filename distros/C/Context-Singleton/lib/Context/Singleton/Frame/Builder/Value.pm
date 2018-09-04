
use strict;
use warnings;

package Context::Singleton::Frame::Builder::Value;

our $VERSION = v1.0.4;

use parent qw[ Context::Singleton::Frame::Builder::Base ];

sub new {
	my ($class, %def) = @_;

	return $class->SUPER::new (value => $def{value});
}

sub build {
	my ($self) = @_;

	return $self->{value};
}

1;

