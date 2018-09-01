
use v5.12;
use strict;
use warnings;

package Context::Singleton::Singleton v1.0.0;
$Context::Singleton::Singleton::VERSION = '1.0.3';
use Ref::Util qw[ is_plain_arrayref ];

use namespace::clean;

sub new {
	my ($class, %params) = @_;

	my $self = bless {
		name => delete $params{name},
		params => {},
		triggers => [],
		builders => [],
	}, $class;

	$self->set_params( %params );

	$self;
}

sub add_builder {
	my ($self, @builders) = @_;
	push @{ $self->{builders} },
		grep defined,
		map { is_plain_arrayref ($_) ? @$_ : $_ }
		@builders
}

sub add_trigger {
	my ($self, @triggers) = @_;
	push @{ $self->{triggers} },
		grep defined,
		map { is_plain_arrayref ($_) ? @$_ : $_ }
		@triggers
}

sub builders {
	my ($self) = @_;

	@{ $self->{builders} };
}

sub param {
	my ($self, $name) = @_;
	$self->{params}{$name};
}

sub set_params {
	my ($self, %params) = @_;

	delete $params{name};

	$self->add_builder( delete $params{builder} );
	$self->add_trigger( delete $params{trigger} );

	%{ $self->{params} } = (%{ $self->{params} }, %params )
		if %params;

	()
}

sub triggers {
	my ($self) = @_;

	@{ $self->{triggers} };
}

1;
