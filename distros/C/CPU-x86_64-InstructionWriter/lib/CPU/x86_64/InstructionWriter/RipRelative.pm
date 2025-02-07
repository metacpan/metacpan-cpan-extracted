package CPU::x86_64::InstructionWriter::RipRelative;
our $VERSION = '0.004'; # VERSION
use strict;
use warnings;
use Carp;

# ABSTRACT: Object representing an offset to a label


sub rip { @_ > 1 && carp "Read-only"; $_[0]{rip} }
sub label { @_ > 1 && carp "Read-only"; $_[0]{label} }
sub name  { 'rip-to-' . $_[0]{label}->name }
sub value {
	my $self= shift;
	if (($self->rip->relative_to||0) == ($self->label->relative_to||0)) {
		my $rip_ofs= $self->rip->offset;
		my $label_ofs= $self->label->offset;
		return defined $rip_ofs && defined $label_ofs? $label_ofs - $rip_ofs : undef;
	} else {
		my $rip_val= $self->rip->value;
		my $label_val= $self->label->value;
		return defined $rip_val && defined $label_val? ($label_val - $rip_val) : undef;
	}
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPU::x86_64::InstructionWriter::RipRelative - Object representing an offset to a label

=head1 VERSION

version 0.004

=head1 DESCRIPTION

The L<CPU::x86_64::InstructionWriter::Label> object resolves to an absolute address.
When you need to resolve a relative offset to a label, use this object instead.

=head1 ATTRIBUTES

=head2 rip

A reference to the label marking the end of the RIP-relative instruction

=head2 label

The label the RIP-relative instruction should point to

=head1 CONSTRUCTOR

Use L<CPU::x86_64::InstructionWriter/get_label> to create labels.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
