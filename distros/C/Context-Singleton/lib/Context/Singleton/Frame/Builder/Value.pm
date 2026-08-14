
use strict;
use warnings;

package Context::Singleton::Frame::Builder::Value;
$Context::Singleton::Frame::Builder::Value::VERSION = '1.0.9';
use Moo;

use namespace::clean;

BEGIN { extends q (Context::Singleton::Frame::Builder::Base) }

has q (value)
	=> is       => q (ro)
	;

sub build {
	my ($self) = @_;

	return $self->value;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::Frame::Builder::Value - Build constant value

=head1 DESCRIPTION

This is internal package.

=head1 AUTHOR

Branislav Zahradník <barney.cpan@gmail.com>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

