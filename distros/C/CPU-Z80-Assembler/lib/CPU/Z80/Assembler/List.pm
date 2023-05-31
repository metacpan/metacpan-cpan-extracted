# $Id$

package CPU::Z80::Assembler::List;

#------------------------------------------------------------------------------

=head1 NAME

CPU::Z80::Assembler::List - Assembly listing output class

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

use Text::Tabs;
use Iterator::Simple::Lookahead;

our $VERSION = '2.25';

use Class::Struct (
		output			=> '$',		# output file handle for the list
		input			=> '$',		# input lines or iterators passed to z80asm
		
		_line_stream	=> '$',		# input line stream with whole program
		_address		=> '$',		# output address
		
		_current_line	=> '$',		# line of the current opcode(s)
		_current_address => '$',	# address of the current opcode(s)
		_current_bytes	=> '$',		# all bytes of all opcodes of _current_line
);

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use CPU::Z80::Assembler::List;
  my $lst = CPU::Z80::Assembler::List->new(input => $asm_input, output => \*STDOUT);
  $lst->add($line, $address, $bytes);
  $lst->flush();

=head1 DESCRIPTION

This module handles the output of the assembly listing file.
It is fead with each assembled opcode and generates the full 
assembly list file on the given output handle.

If output is undef, does not generate any output.

=head1 EXPORTS

Nothing.

=head1 FUNCTIONS

=head2 new

  my $lst = CPU::Z80::Assembler::List->new(input => $asm_input, output => \*STDOUT);

Creates a new object, see L<Class::Struct|Class::Struct>.

=head2 input

input is the input as passed to z80asm, i.e. list of text lines to parse or iterators
that return text lines to parse.

=head2 output

output is the output file handle to receive the listing file. It can be an open
file for writing, or one of the standard output file handles.

If output is undefined, no output is generated.

=cut

#------------------------------------------------------------------------------

=head2 add

  $self->add($line, $address, $bytes);

Adds a new opcode to the output listing. Receives the opcode L<Asm::Preproc::Line|Asm::Preproc::Line>, 
address and bytes. Generates the output lines including this new opcode.

The output is held in an internal buffer until an opcode for the next line is passed to a
subsequent add() call. 

The last output line 
is only output on flush() or DESTROY()

=cut

#------------------------------------------------------------------------------

sub add { my($self, $opcode_line, $address, $bytes) = @_;
	my $output = $self->output;
	if ($output) {
		if ($self->_current_line && $self->_current_line != $opcode_line) {
			$self->flush();								# different line
		}
		
		if (! $self->_current_line) {					# new or different line
			$self->_current_line($opcode_line);
			$self->_current_address($address);
			$self->_current_bytes($bytes);
		}
		else {											# same line as last	
			$self->_current_bytes($self->_current_bytes . $bytes);
		}
	}
}

#------------------------------------------------------------------------------

=head2 flush

  $self->flush();

Dumps the current line to the output. Called on DESTROY().

=cut

#------------------------------------------------------------------------------

sub flush { my($self) = @_;
	my $output = $self->output;
	if ($output && $self->_current_line) {

		# print all input lines up to the current position
		my $rewind_count;
		my $line;
		for (;;) {
			while (! defined($self->_line_stream) ||
				   ! defined($line = $self->_line_stream->next)) {
				$rewind_count++;						# end of input, rewind
				die "Cannot find $line in list" if $rewind_count > 1;	
														# assert input is OK
				$self->_line_stream(CPU::Z80::Assembler::z80preprocessor(
														@{$self->input}));
			}
			
			last if $line == $self->_current_line;		# found current line
			print $output $self->_format_line($self->_address, $line), "\n";
		}
	
		print $output $self->_format_line($self->_current_address, $self->_current_line);
		for (split(//, $self->_current_bytes)) {
			print $output sprintf("%02X ", ord($_));
		}
		print $output "\n";

		$self->_address($self->_current_address);
		$self->_current_line(undef);
		$self->_current_address(undef);
		$self->_current_bytes(undef);
	}
}

sub DESTROY { my($self) = @_;
	$self->flush();
}

#------------------------------------------------------------------------------

sub _format_line { my($self, $address, $line) = @_;
	$address ||= 0;
	my $text = $line->text;
	$text = expand($text);								# untabify
	$text =~ s/\s+$//;
	substr($text, 34) = ' ...' if(length($text) > 37);
	return sprintf("0x%04X: %-38s | ", $address, $text);
}
	