package CPU::x86_64::InstructionWriter::LazyEncode;
our $VERSION = '0.005'; # VERSION
use strict;
use warnings;
use Carp;
use parent 'CPU::x86_64::InstructionWriter::Label';

# ABSTRACT: Object representing a partially encoded instruction


sub name {
	@_ > 1 && croak "Read-only";
	$_[0]{name} // do {
		my $op= $_[0]{caller}? $_[0]{caller}[3] : 'instruction';
		$op =~ s/.*:://;
		$op . " at start+".$_[0]{offset};
	}
}

sub encoder { @_ > 1 && croak "Read-only"; $_[0]{encoder} }
sub unknown { @_ > 1 && croak "Read-only"; $_[0]{unknown} }
sub caller  { @_ > 1 && croak "Read-only"; $_[0]{caller} }
sub target  { @_ > 1 && croak "Read-only"; $_[0]{target} }


sub clone_into_writer {
	my ($self, $writer, $offset, $label_map)= @_;
	my $new= bless {
		%$self,
		relative_to => $writer->start_address,
		offset => $self->offset + $offset,
		target => !$self->target? undef : $label_map->{$self->target},
		unknown => !$self->unknown? undef
			: $self->unknown->clone_into_writer($writer, $offset, $label_map)
	}, ref $self;
	$new->unknown->instruction($new)
		if $new->unknown && $new->unknown->can('instruction');
	$new;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPU::x86_64::InstructionWriter::LazyEncode - Object representing a partially encoded instruction

=head1 VERSION

version 0.005

=head1 DESCRIPTION

When an instruction references unknown values, we write a placeholder into the instruction
buffer and then describe that range with one of these objects.  This object has an 'encode'
function that can be called later to pack the resolved value into the bytes of the instruction.

=head1 ATTRIBUTES

=head2 name

A human-readable name describing the instruction

=head2 relative_to

The constant or placeholder object representing the start address for the assembled unit in
which this label was declared.

=head2 offset

The address where the instruction begins, relative to 'relative_to'.

=head2 len

The number of bytes of placeholder for this instruction.

=head2 encoder

A coderef which can be called as a method of the InstructionWriter, and returns the new bytes
to be spliced into the instruction buffer.

=head2 caller

Caller information about the top-level method that created the instruction.

=head1 CONSTRUCTOR

Use L<CPU::x86_64::InstructionWriter/get_label> to create labels.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
