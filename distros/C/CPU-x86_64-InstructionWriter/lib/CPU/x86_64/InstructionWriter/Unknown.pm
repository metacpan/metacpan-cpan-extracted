package CPU::x86_64::InstructionWriter::Unknown;
our $VERSION = '0.004'; # VERSION
use strict;
use warnings;
use Carp;

# ABSTRACT: Placeholder for a constant that will be assembled


sub new {
	my ($class, %fields)= @_;
	bless \%fields, $class;
}

sub name { $_[0]{name}= $_[1] if @_ > 1; $_[0]{name} }

sub bits {
	my $self= shift;
	return $self->{bits} unless @_;
	my $val= shift;
	!defined $self->{bits} || $self->{bits} == $val
		or croak "Can't change bits from $self->{bits} to $val for unknown($self->{name})";
	$self->{bits}= $val;
}

sub value { $_[0]{value}= $_[1] if @_ > 1; $_[0]{value} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPU::x86_64::InstructionWriter::Unknown - Placeholder for a constant that will be assembled

=head1 VERSION

version 0.004

=head1 DESCRIPTION

This object represents a calculated constant that is not initially known.

=head1 ATTRIBUTES

=head2 name

Human-readable name for the unknown value

=head2 bits

The number of bits in the value (sometimes known before the value itself).
May be C<undef>

=head2 value

The numeric value.  Starts as C<undef> and gets assigned a value during assembly.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
