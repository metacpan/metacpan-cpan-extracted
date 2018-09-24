
use v5.10;
use strict;
use warnings;

package Context::Singleton::Frame::Builder::Base;

our $VERSION = v1.0.5;

use List::MoreUtils;

sub new {
	my ($class, %params) = @_;

	$params{default} //= {};

	my $self = bless \%params, $class;

	$self->{required} = [ List::MoreUtils::uniq $self->_build_required ];

	return $self;
}

sub _build_required {
	my ($self) = @_;

	return grep defined, $self->{this};
}

sub dep {
	my ($self) = @_;
	return $self->{dep};
}

sub required {
	my ($self) = @_;

	return @{ $self->{required} };
}

sub unresolved {
	my ($self, $resolved) = @_;
	my $default = $self->{default};
	$resolved //= {};

	return
		grep ! exists $default->{$_},
		grep ! exists $resolved->{$_},
		$self->required
		;
}

sub default {
	my ($self) = @_;

	return %{ $self->{default} };
}

sub build {
	my ($self, $resolved) = @_;

	$resolved = { %{ $self->{default} }, %{ $resolved // {} } };
	my @args = $self->build_callback_args ($resolved);

	return $self->{as}->(@args)
		if $self->{as};

	my $this = shift @args;

	return $this->can ($self->{call})->(@args)
		if exists $self->{call};

	return $this->${\ $self->{builder} } (@args);
}

sub build_callback_args {
	my ($self, $resolved) = @_;

	return map $resolved->{$_}, grep $_, $self->{this};
}

1;

