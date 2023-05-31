# $Id$

package CPU::Z80::Assembler::JumpOpcode;

#------------------------------------------------------------------------------

=head1 NAME

CPU::Z80::Assembler::JumpOpcode - Represents one jump assembly instruction to be 
computed at link time

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

our $VERSION = '2.25';

use Asm::Preproc::Line;

sub new { 
	my($class, %args) = @_;
	bless [
		$args{short_jump}	|| CPU::Z80::Assembler::Opcode->new(),
											# short jump opcode
		$args{long_jump}	|| CPU::Z80::Assembler::Opcode->new(),
											# long jump opcode
	], $class;
}
sub short_jump 	{ defined($_[1]) ? $_[0][0] = $_[1] : $_[0][0] }
sub long_jump	{ defined($_[1]) ? $_[0][1] = $_[1] : $_[0][1] }

# address and line : read from short_jump, write to short_jump and long_jump
sub address	{ 
	my($self, $address) = @_;
	if (defined $address) {
		$self->short_jump->address($address);
		$self->long_jump->address($address);
		return $address;
	}
	else {
		return $self->short_jump->address;
	}
}

sub line { 
	my($self, $line) = @_;
	if (defined $line) {
		$self->short_jump->line($line);
		$self->long_jump->line($line);
		return $line;
	}
	else {
		return $self->short_jump->line;
	}
}

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use CPU::Z80::Assembler::JumpOpcode;
  $opcode = CPU::Z80::Assembler::Opcode->new(
                short_jump => CPU::Z80::Assemble::Opcode->new( ... JR instr ...),
                long_jump  => CPU::Z80::Assemble::Opcode->new( ... JP instr ...));
  $opcode->address;
  $opcode->line;
  $dist = short_jump_dist($address, \%symbol_table);
  $bytes = $opcode->bytes($address, \%symbol_table);
  $size = $opcode->size;

=head1 DESCRIPTION

This module defines the class that represents one jump instruction to be
added to the object code. The object contains both the short jump form and 
the long jump form. 

During address allocation all short jumps that are out of range are replaced 
by long jumps.

=head1 EXPORTS

Nothing.

=head1 FUNCTIONS

=head2 new

Creates a new object.

=head2 address

Address where this opcode is loaded, computed at link time.

=head2 short_jump

Returns the L<CPU::Z80::Assembler::Opcode|CPU::Z80::Assembler::Opcode> object representing the short jump.

=head2 long_jump

Returns the L<CPU::Z80::Assembler::Opcode|CPU::Z80::Assembler::Opcode> object representing the long jump.

=head2 line

Get/set the line - text, file name and line number where the token was read.

=cut

#------------------------------------------------------------------------------

=head2 short_jump_dist

Gets the short jump distance, in relation to the address of the next
instruction.

Returns more than 127 or less than -128 if the short jump is out of range.

=cut

#------------------------------------------------------------------------------

sub short_jump_dist {
	my($self, $address, $symbol_table) = @_;
	
	# expr in a short jump is always second byte
	my $dist = $self->short_jump->child->[1]->evaluate($address, $symbol_table);
	return $dist;
}

#------------------------------------------------------------------------------

=head2 bytes

  $bytes = $opcode->bytes($address, \%symbol_table);

Computes all the expressions in the short jump and returns the bytes string
with the result object code.

=cut

#------------------------------------------------------------------------------

sub bytes { 
	my($self, $address, $symbol_table) = @_;
	return $self->short_jump->bytes($address, $symbol_table);
}

#------------------------------------------------------------------------------

=head2 size

  $size = $opcode->size;

Return the number of bytes that the short_jump opcode will generate.

=cut

#------------------------------------------------------------------------------

sub size { 
	my($self) = @_;
	return $self->short_jump->size;
}

#------------------------------------------------------------------------------

=head1 BUGS and FEEDBACK

See L<CPU::Z80::Assembler|CPU::Z80::Assembler>.

=head1 SEE ALSO

L<CPU::Z80::Assembler|CPU::Z80::Assembler>
L<CPU::Z80::Assembler::Opcode|CPU::Z80::Assembler::Opcode>
L<Asm::Preproc::Line|Asm::Preproc::Line>

=head1 AUTHORS, COPYRIGHT and LICENCE

See L<CPU::Z80::Assembler|CPU::Z80::Assembler>.

=cut

#------------------------------------------------------------------------------

1;

