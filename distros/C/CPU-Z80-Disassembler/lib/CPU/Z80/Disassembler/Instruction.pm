package CPU::Z80::Disassembler::Instruction;

#------------------------------------------------------------------------------

=head1 NAME

CPU::Z80::Disassembler::Instruction - One Z80 disassembled instruction

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

use Asm::Z80::Table;
use CPU::Z80::Disassembler::Memory;
use CPU::Z80::Disassembler::Format;

our $VERSION = '0.07';

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use CPU::Z80::Disassembler::Instruction;
  $instr = CPU::Z80::Disassembler::Instruction->disassemble(
                    $memory, $addr, $limit_addr);
  $instr = CPU::Z80::Disassembler::Instruction->defb($memory, $addr, $count);
  $instr = CPU::Z80::Disassembler::Instruction->defb2($memory, $addr, $count);
  $instr = CPU::Z80::Disassembler::Instruction->defw($memory, $addr, $count);
  $instr = CPU::Z80::Disassembler::Instruction->defm($memory, $addr, $length);
  $instr = CPU::Z80::Disassembler::Instruction->defmz($memory, $addr);
  $instr = CPU::Z80::Disassembler::Instruction->defm7($memory, $addr);
  $instr = CPU::Z80::Disassembler::Instruction->org($memory, $addr);
  
  $instr->addr; $instr->next_addr;
  $instr->bytes; $instr->opcode; $instr->N; $instr->NN; $instr->DIS; $instr->STR;
  $instr->comment;
  print $instr->dump;
  print $instr->asm;		
  print $instr->as_string, "\n";

=head1 DESCRIPTION

This module represents one disassembled instruction. The object is
constructed by one of the factory methods, and has attributes to ease the 
interpretation of the instruction.

=head1 CONSTRUCTORS

=head2 disassemble

Factory method to create a new object by disassembling the given 
L<CPU::Z80::Disassembler::Memory|CPU::Z80::Disassembler::Memory> object
at the given address.

The C<$limit_addr> argument, if defined, tells the disassembler to select
the longest possible instruction, that does not use the byte at C<$limit_add>. 
The default is to select the shortest possible instruction. 

For example, the sequence of bytes C<62 6B> is decoded as C<ld h,d> if 
C<$limit_addr> is undef.

If C<$limit_addr> is defined with any value different from C<$addr + 1>, where
the second byte is stored, then the same sequence of bytes is decoded as
C<ld hl,de>.

To decode standard Z80 instructions, do not pass the C<$limit_addr> argument.

To decode extended Z80 instructions, pass the address of the next label after 
C<$addr>, or 0x10000 to get always the longest instruction.

If the instruction at the given address is an invalid opcode, or if there
are no loaded bytes at the given address, the instrution object is not
constructed and the factory returns C<undef>.

=head2 defb

Factory method to create a new object by disassembling a C<defb> instruction
at the given address, reading one or C<$count> byte(s) from memory. 

=head2 defb2

Same as defb but shows binary data. 

=head2 defw

Factory method to create a new object by disassembling a C<defw> instruction
at the given address, reading one or C<$count> word(s) from memory. 

=head2 defm

Factory method to create a new object by disassembling a C<defm> instruction
at the given address, reading C<$length> character(s) from memory. 

=head2 defmz

Factory method to create a new object by disassembling a C<defmz> instruction
at the given address, reading character(s) from memory until a zero terminator 
is found.

=head2 defm7

Factory method to create a new object by disassembling a C<defm7> instruction
at the given address, reading character(s) from memory until a character
with bit 7 set is found.

=head2 org

Factory method to create a new ORG instruction. 

=cut

#------------------------------------------------------------------------------

=head1 ATTRIBUTES

=head2 memory

Point to the memory object from where this instruction was disassembled.

=head2 addr

Address of the instruction.

=head2 size

Size of the instruction, in bytes.

=head2 next_addr

Returns the address that follows this instruction.

=head2 next_code

Returns the list with the next possible addresses where the code flow can continue. 

For an instruction that does not branch, this is the same as C<next_addr>.

For a decision-branch instruction, these are the C<next_addr> and the C<NN>.

For an instruction that breaks the flow (e.g. C<ret>), this is an empty list.

A C<call> or C<rst> instruction is considered as breaking the flow, because
the called routine might manipulate the return pointer in the stack, and the
bytes after the C<call> or C<rst> instruction can be data bytes.

=head2 bytes

Reference to a list of the instruction bytes. The bytes are retrieved
from the L<CPU::Z80::Disassembler::Memory|CPU::Z80::Disassembler::Memory>
object.

=head2 opcode

Canonical assembly instruction, e.g. 'ld a,(NN)'. 
The possible argument types are N, NN, DIS and STR. 
There is one method to get/set each of the argument types.

=head2 N

8-bit data used by the instruction.

=head2 N2

8-bit data used by the instruction, to be shown in base 2.

=head2 NN

16-bit data used by the instruction.

=head2 DIS

Offset for index register.

=head2 STR

String for defm* instructions.

=head2 comment

Comment to be written after a '; ' at the end of the line.

=head2 format

Returs the hash of special formating functions for each type of argument. These 
functions, if defined, are called instead of the ones in the
L<CPU::Z80::Disassembler::Format|CPU::Z80::Disassembler::Format> module to format
each type of argument.

For example, to format the 8-bit argument of an instruction as decimal:

  $instr->format->{N} = sub { my $v = shift; return "$v" };

=cut

#------------------------------------------------------------------------------

=head1 PREDICATES

=head2 is_code

Return TRUE if the instruction is a Z80 assembly opcode, FALSE if it is one 
of the data definition or org instructions.

=head2 is_call

Return TRUE if the instruction is a call instruction, i.e. C<call> or C<rst>.

=head2 is_branch

Return TRUE if the instruction may branch to another address, the address is
stored in the C<NN> attribute. This is either a jump or a call instruction.

=head2 is_break_flow

Return TRUE if the instruction breaks the flow at this point and jumps to some
other part of the code. A call instruction is considered as breaking the flow,
see C<next_code> above.

=cut

#------------------------------------------------------------------------------
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(
			'memory',		# point to whole memory
			'addr',			# start address
			'size',			# number of bytes of instruction
			'opcode',		# canonical opcode, e.g. 'ld a,(NN)'
			'N',			#  8-bit data
			'N2',			#  8-bit data in binary
			'NN',			# 16-bit data
			'DIS',			# offset for index
			'STR',			# unquoted string for defm*
			'comment',		# comment after instruction
			'_format',		# hash of (N, NN, DIS, STR) => custom function to
							# format each type of argument
			'is_code',		# true for a Z80 assembly instruction, 
							# false for def*, org, ...
);

#------------------------------------------------------------------------------
sub format {
	my($self) = @_;
	$self->_format({}) unless $self->_format;
	$self->_format;
}

#------------------------------------------------------------------------------
my %default_format = (
		N	=> \&format_hex2,
		N2	=> \&format_bin8,
		NN	=> \&format_hex4,
		DIS	=> \&format_dis,
		STR	=> \&format_str,
);

#------------------------------------------------------------------------------
sub next_addr {
	my($self) = @_;
	$self->addr + $self->size;
}

#------------------------------------------------------------------------------
sub next_code {
	my($self) = @_;
	my @ret;
	push @ret, $self->NN            if $self->is_branch;
	push @ret, $self->next_addr unless $self->is_break_flow;
	@ret;
}

#------------------------------------------------------------------------------
sub bytes {
	my($self) = @_;
	my @bytes;
	for my $addr ($self->addr .. $self->next_addr - 1) {
		push @bytes, $self->memory->peek($addr);
	}
	\@bytes;
}

#------------------------------------------------------------------------------
# predicates
sub is_call 		{ shift->opcode =~ /call|rst/ }
sub is_branch		{ shift->opcode =~ /jp .*NN|jr|djnz|call|rst/ }
sub is_break_flow	{ shift->opcode =~ /ret$|reti|retn|call NN|rst|jr NN|jp NN|jp \(\w+\)|org/ }

#------------------------------------------------------------------------------
sub disassemble {
	my($class, $memory, $addr, $limit_addr) = @_;

	my $self = bless { 	memory 	=> $memory, 
						addr 	=> $addr, 
						is_code	=> 1,
					}, $class;

	# save bytes of all decoded instructions
	my @found;				# other instructions found
	
	my $table = Asm::Z80::Table->disasm_table;
	for ( 	; 
			# exit if second instruction goes over limit, e.g. label
			! (defined($limit_addr) && @found && $addr == $limit_addr) ;
			$addr++ 
		) {
		# fetch
		my $byte = $memory->peek($addr);
		last unless defined $byte;				# unloaded memory
		
		# lookup in table
		if (exists $table->{N}) {
			die if defined $self->N;
			$self->N( $byte );
			$table = $table->{N};
		}
		elsif (exists $table->{NNl}) {
			die if defined $self->NN;
			$self->NN( $memory->peek16u($addr++) );
			$table = $table->{NNl}{NNh};
		}
		elsif (exists $table->{NNo}) {
			die if defined $self->NN;
			$self->NN( $addr + 1 + $memory->peek8s($addr) );
			$table = $table->{NNo};
		}
		elsif (exists $table->{DIS}) {
			die if defined $self->DIS;
			$self->DIS( $memory->peek8s($addr) );
			$table = $table->{DIS};
		}
		elsif (exists $table->{'DIS+1'}) {
			die unless defined $self->DIS;
			if ( $self->DIS + 1 != $memory->peek8s($addr) ) {
				last;							# abort search
			}
			$table = $table->{'DIS+1'};
		}
		elsif (! exists $table->{$byte}) {	
			last;								# abort search
		}
		else {
			$table = $table->{$byte};
		}
		
		# check for end
		if (exists $table->{''}) {				# possible finish
			push @found, [ [@{$table->{''}}], $addr + 1 ]; 
												# save this instance, copy
			last unless defined $limit_addr;	# no limit -> shortest instr
			
			# continue for composite instruction
		}
	}
	
	# return undef if no instrution found
	return undef unless @found;
	
	# collect last complete instruction found
	my($opcode, @args) = @{$found[-1][0]};
	$opcode .= ' '.join('', @args) if @args;
	$opcode =~ s/,\s*/, /g;
	
	$self->opcode($opcode);
	$self->size($found[-1][1] - $self->addr);
		
	# special case: rst -> show address in hex
	if ($opcode =~ /rst (\d+)/) {
		$self->N($1);			# set N for display
		$self->NN($1);			# set NN for analysis
		$self->opcode('rst N');
	}
	
	$self;
}

#------------------------------------------------------------------------------
sub _def_value {
	my($class, $peek, $size, $def, $N, 
	   $memory, $addr, $count) = @_;
	
	$count ||= 1;
	my $values = [];
	for my $i (0 .. $count - 1) {
		my $value = $memory->$peek($addr + $size * $i);	# read values
		return undef unless defined $value;				# unloaded memory
		
		$values->[$i] = $value;
	}
	
	return bless {	memory	=> $memory,
					addr 	=> $addr, 
					size	=> $size * $count,
					opcode 	=> "$def $N", 
					$N 		=> $values,
				}, $class;
}

#------------------------------------------------------------------------------
sub defb	{ shift->_def_value('peek8u',  1, 'defb', 'N',  @_) }
sub defb2	{ shift->_def_value('peek8u',  1, 'defb', 'N2',  @_) }
sub defw	{ shift->_def_value('peek16u', 2, 'defw', 'NN', @_) }

#------------------------------------------------------------------------------
sub _def_str {
	my($class, $peek, $eos_length, $def,
	   $memory, $addr, $length) = @_;
	   
	my $str = $memory->$peek($addr, $length);
	return undef unless defined $str;				# unloaded memory
	
	return $class->new({memory	=> $memory,
						addr 	=> $addr, 
						size	=> length($str) + $eos_length,
						opcode 	=> "$def STR", 
						STR 	=> $str});
}

#------------------------------------------------------------------------------
sub defm	{ shift->_def_str('peek_str',  0, 'defm',  @_) }
sub defmz	{ shift->_def_str('peek_strz', 1, 'defmz', @_) }
sub defm7	{ shift->_def_str('peek_str7', 0, 'defm7', @_) }

#------------------------------------------------------------------------------
sub org { 
	my($class, $memory, $addr) = @_;

	return bless {	memory	=> $memory,
					addr 	=> $addr, 
					size	=> 0,
					opcode 	=> "org NN", 
					NN	 	=> $addr,
				}, $class;
}

#------------------------------------------------------------------------------

=head1 FUNCTIONS

=head2 as_string

Returns the disassembled instruction opcode and arguments.

=cut

#------------------------------------------------------------------------------
# Format of the disassembled output
#           1         2         3         4         5         6         7
# 0123456789012345678901234567890123456789012345678901234567890123456789012
# #       #       #       #       #       #       #       #       #       #
# AAAA H1H2H3H4H5 INSTR           ; COMMENT
#
sub as_string {
	my($self) = @_;

	# decode opcode
	my $opcode = $self->opcode;
	$opcode =~ s{\b ( N | N2 | NN | \+(DIS) | STR ) \b
			   }{
					$self->_format_arg($2 || $1)
				}gex;
	
	my $comment = $self->comment;
	
	if (defined $comment) {
		$comment =~ s/\n/ "\n" . " " x 32 . "; " /ge;	# multi-line comment
	}
	
	return !defined($comment) ? 
				$opcode :
				length($opcode) >= 24 ?
					$opcode . "\n" . " " x 32 . "; " . $comment :
					sprintf("%-24s; %s", $opcode, $comment);
}

sub _format_arg {
	my($self, $arg) = @_;

	my $ffunc = ( $self->_format && $self->format->{$arg} ?
						$self->format->{$arg} :
						$default_format{$arg}
				);
	my $value = $self->$arg;
	$value = [$value] unless ref($value);
	
	return join(", ", map {$ffunc->($_)} @$value)
}

#------------------------------------------------------------------------------

=head2 dump

Returns the disassembly dump ready to print, containing address, bytes and
instruction, followed by newline.

=cut

#------------------------------------------------------------------------------
use constant BPL => 5;

sub dump {
	my($self) = @_;

	# address
	my $ret = sprintf("%04X ", $self->addr);
	
	# bytes
	my $bytes = '';
	for (@{$self->bytes}) {
		$bytes .= sprintf("%02X", $_);
	}
	
	# first line of bytes
	$ret .= sprintf("%-*s ", BPL*2, substr($bytes, 0, BPL*2));
	$bytes = length($bytes) < BPL*2 ? '' : substr($bytes, BPL*2);
	
	# opcode
	$ret .= $self->as_string . "\n";
	
	# next lines of bytes
	while ($bytes ne '') {
		$ret .= " " x 5 . sprintf("%-*s \n", BPL*2, substr($bytes, 0, BPL*2));
		$bytes = length($bytes) < BPL*2 ? '' : substr($bytes, BPL*2);
	}
	
	$ret;
}

#------------------------------------------------------------------------------

=head2 asm

Returns the disassembly asm line ready to print, containing 
instruction and comments, followed by newline.

=cut

#------------------------------------------------------------------------------
sub asm {
	my($self) = @_;
	
	sprintf("%-7s %s\n%s", '', 
			$self->as_string,
			($self->is_break_flow && ! $self->is_call) ? "\n" : "");
}

#------------------------------------------------------------------------------

=head1 AUTHOR, BUGS, FEEDBACK, LICENSE AND COPYRIGHT

See L<CPU::Z80::Disassembler|CPU::Z80::Disassembler>.

=cut

#------------------------------------------------------------------------------

1;
