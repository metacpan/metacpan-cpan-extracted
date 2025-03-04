package CPU::x86_64::InstructionWriter::RipRelative;
our $VERSION = '0.005'; # VERSION
use strict;
use warnings;
use Carp;
use Scalar::Util 'weaken';

# ABSTRACT: Object representing an offset to a label


sub instruction { weaken($_[0]{instruction}= $_[1]) if @_ > 1; $_[0]{instruction} }
sub target { @_ > 1 && carp "Read-only"; $_[0]{target} }
sub name  { 'rip-to-' . $_[0]{target}->name }
sub value {
	my $self= shift;
	if (($self->instruction->relative_to||0) == ($self->target->relative_to||0)) {
		my $rip_ofs= $self->instruction->offset + $self->instruction->len;
		my $label_ofs= $self->target->offset;
		return defined $label_ofs? $label_ofs - $rip_ofs : undef;
	} else {
		my $start= $self->instruction->relative_to->value;
		my $ofs= $self->instruction->offset + $self->instruction->len;
		my $label_val= $self->target->value;
		return !(defined $start && defined $label_val)? undef
			: $label_val - ($start + $ofs);
	}
}

sub clone_into_writer {
	my ($self, $writer, $offset, $label_map)= @_;
	bless {
		instruction => $self->instruction,
		target      => $label_map->{$self->target}
	}, ref $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPU::x86_64::InstructionWriter::RipRelative - Object representing an offset to a label

=head1 VERSION

version 0.005

=head1 DESCRIPTION

The L<CPU::x86_64::InstructionWriter::Label> object resolves to an absolute address.
When you need to resolve a relative offset to a label, use this object instead.

=head1 ATTRIBUTES

=head2 instruction

A reference to the 'unknown' entry for the instruction

=head2 label

The label the RIP-relative instruction should point to

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
