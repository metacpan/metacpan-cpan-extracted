package PDL::Role::Enumerable;
$PDL::Role::Enumerable::VERSION = '0.003';
use strict;
use warnings;

use Tie::IxHash;
use Tie::IxHash::Extension;
use Moo::Role;
use Try::Tiny;
use List::AllUtils ();

with qw(PDL::Role::Stringifiable);

has _levels => ( is => 'rw', default => sub { Tie::IxHash->new; } );

sub element_stringify_max_width {
	my ($self, $element) = @_;
	my @where_levels = @{ $self->{PDL}->uniq->unpdl };
	my @which_levels = @{ $self->levels }[@where_levels];
	my @lengths = map { length $_ } @which_levels;
	List::AllUtils::max( @lengths );
}

sub element_stringify {
	my ($self, $element) = @_;
	( $self->_levels->Keys )[ $element ];
}

sub number_of_levels {
	my ($self) = @_;
	$self->_levels->Length;
}

sub levels {
	my ($self, @levels) = @_;
	if( @levels ) {
		try {
			$self->_levels->RenameKeys( @levels );
		} catch {
			die "incorrect number of levels" if /@{[ Tie::IxHash::ERROR_KEY_LENGTH_MISMATCH ]}/;
		};
	}
	[ $self->_levels->Keys ];
}

around qw(slice uniq dice) => sub {
	my $orig = shift;
	my ($self) = @_;
	my $ret = $orig->(@_);
	# TODO _levels needs to be copied
	$ret->_levels( $self->_levels );
	$ret;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PDL::Role::Enumerable

=head1 VERSION

version 0.003

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
