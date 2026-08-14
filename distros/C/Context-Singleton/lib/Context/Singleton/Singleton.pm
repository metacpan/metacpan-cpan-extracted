
use v5.10;
use strict;
use warnings;

package Context::Singleton::Singleton;
$Context::Singleton::Singleton::VERSION = '1.0.9';
{
	use Moo;

	use Context::Singleton::Frame::Builder::Value;
	use Context::Singleton::Frame::Builder::Hash;
	use Context::Singleton::Frame::Builder::Array;

	use namespace::clean;

	has singleton
		=> is       => ro
		=> required => 1
		;

	has _builders
		=> is       => ro
		=> default  => sub { [] }
		=> init_arg => undef
		;

	has _on_destroy
		=> is       => ro
		=> default  => sub { [] }
		=> init_arg => undef
		;

	sub _build_builder {
		my ($db, $def) = @_;

		$db->_guess_builder_class ($def)->new (%$def);
	}

	sub _guess_builder_class {
		my ($db, $def) = @_;

		return Context::Singleton::Frame::Builder::Value::
			if exists $def->{value}
			;

		return Context::Singleton::Frame::Builder::Hash::
			if Ref::Util::is_hashref ($def->{dep})
			;

		return Context::Singleton::Frame::Builder::Array::;
	}

	sub add_builder {
		my ($self, $def) = @_;

		push @{ $self->_builders }, $self->_build_builder ($def);

		return;
	}

	sub add_on_destroy {
		my ($self, $code) = @_;

		push @{ $self->_on_destroy }, $code;

		return;
	}

	sub builders {
		my ($self) = @_;

		return @{ $self->_builders };
	}

	sub on_destroy {
		my ($self) = @_;

		return @{ $self->_on_destroy };
	}

	1;
}

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::Singleton - Internal class holding one singleton's builders and destroy callbacks.

=head1 DESCRIPTION

This is internal package.

=head1 AUTHOR

Branislav Zahradník <barney.cpan@gmail.com>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut
