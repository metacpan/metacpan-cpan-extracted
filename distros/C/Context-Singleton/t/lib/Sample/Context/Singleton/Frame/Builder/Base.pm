
use strict;
use warnings;

package Sample::Context::Singleton::Frame::Builder::Base;

our $VERSION = v1.0.0;

package Sample::Context::Singleton::Frame::Builder::Base::__::Builtin::Deps;
use parent 'Context::Singleton::Frame::Builder::Base';

sub _build_required {
	my ($self) = @_;

	$self->SUPER::_build_required, 'foo', 'bar';
}

sub build_callback_args {
	my ($self, $resolved) = @_;

	$self->SUPER::build_callback_args ($resolved), $resolved->{foo}, $resolved->{bar};
}

package Sample::Context::Singleton::Frame::Builder::Base::__::Builder;

sub new {
	my ($class, $value) = @_;
	bless [ @_ ], $class;
}

sub method {
	[ @_ ];
}

1;
