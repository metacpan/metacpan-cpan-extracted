
use strict;
use warnings;

package Context::Singleton::Frame::Promise::Rule;
$Context::Singleton::Frame::Promise::Rule::VERSION = '1.0.8';
use Moo;

use namespace::clean;

BEGIN { extends q (Context::Singleton::Frame::Promise) }

use namespace::clean;

has q (rule)
	=> is       => q (ro)
	;

sub notify_deducible {
	my ($self, $in_depth) = @_;

	$self->set_deducible ($in_depth)
		if $self->deducible_dependencies
		;
}

sub deducible_builder {
	my ($self) = @_;

	for my $dependency ($self->deducible_dependencies) {
		next
			unless $dependency->deduced_in_depth == $self->deduced_in_depth
			;

		return $dependency;
	}
}

1;

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::Frame::Promise::Rule - Represents all rules of one singleton

=head1 DESCRIPTION

This is internal package.

=head1 AUTHOR

Branislav Zahradník <barney.cpan@gmail.com>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

