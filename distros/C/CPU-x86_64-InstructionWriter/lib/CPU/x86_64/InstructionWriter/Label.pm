package CPU::x86_64::InstructionWriter::Label;
our $VERSION = '0.001'; # VERSION
use strict;
use warnings;
use Carp;

# ABSTRACT: Object representing a jump target in the code


sub relative_to { @_ > 1 && carp "Read-only"; $_[0]{relative_to} }
sub name  { @_ > 1 && carp "Read-only"; $_[0]{name} }
sub offset { @_ > 1 && carp "Read-only"; $_[0]{offset} }
sub value {
	my $offset= $_[0]{offset};
	my $rel= !defined $_[0]{relative_to}? 0
		: ref $_[0]{relative_to}? $_[0]{relative_to}->value
		: $_[0]{relative_to};
	defined $offset && defined $rel? $offset + $rel : undef;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPU::x86_64::InstructionWriter::Label - Object representing a jump target in the code

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Forward-jumps in X86 can be fairly difficult because the instructions are variable length, and
depending on how far the jump needs to go, the jump instruction itself can be variable-length
which affects the address it jumps to.  The InstructionWriter inserts these objects as place
holders and then resolves their address later.

=head1 ATTRIBUTES

=head2 name

The user-readable name of the label

=head2 relative_to

The constant or placeholder object representing the start address for the assembled unit in
which this label was declared.

=head2 offset

The address of this label, relative to 'relative_to'.

=head1 CONSTRUCTOR

Use L<CPU::x86_64::InstructionWriter/get_label> to create labels.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
