package CPU::Z80::Disassembler;

#------------------------------------------------------------------------------

=head1 NAME

CPU::Z80::Disassembler - Disassemble the flow of a Z80 program

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

use Carp; our @CARP_NOT;		# do not report errors in this package

use CPU::Z80::Disassembler::Memory;
use CPU::Z80::Disassembler::Instruction;
use CPU::Z80::Disassembler::Format;
use CPU::Z80::Disassembler::Labels;

use Path::Tiny;

our $VERSION = '0.07';

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use CPU::Z80::Disassembler;
  $dis = CPU::Z80::Disassembler->new;
  $dis->memory->load_file($file_name, $addr, $opt_skip_bytes, $opt_length);
  $dis->write_dump; $dis->write_dump($file);
  $dis->analyse;
  $dis->write_asm;  $dis->write_asm($file);

  $dis->get_type($addr);
  $dis->set_type_code($addr [,$count]);
  $dis->set_type_byte($addr [,$count]);
  $dis->set_type_word($addr [,$count]);

  $dis->set_call($addr, 1);    # this may be called
  $dis->set_call($addr, $sub); # @next_code = $sub->($self, $next_addr) will be called

  $dis->code($addr [, $label]);
  $dis->defb($addr [, $count][, $label]);
  $dis->defw($addr [, $count][, $label]);
  $dis->defm($addr, $size [, $label]);
  $dis->defmz($addr [, $count][, $label]);
  $dis->defm7($addr [, $count][, $label]);

  $dis->block_comment($addr, $block_comment);
  $dis->line_comments($addr, @line_comments);

  $dis->relative_arg($addr, $label_name);
  $dis->ix_base($addr);
  $dis->iy_base($addr);
  
  $dis->create_control_file($ctl_file, $bin_file, $addr, $arch);
  $dis->load_control_file($ctl_file);

=head1 DESCRIPTION

Implements a Z80 disassembler. Loads a binary file into memory and dumps
an unprocessed disassembly listing (see C<write_dump>).

Alternatively there are functions to tell the disassembler where there are 
data bytes and what are code entry points and labels. The disassembler will
follow the code by simulating a Z80 processor, to find out where the code region
finishes.

As a C<call> instruction may be followed by data, the disassembler tries to find
out if the called routine manipulates the return stack. If it does not, and ends 
with a C<ret>, then the routine is considered safe, and the disassembly continues
after the C<call> instruction. If the routine is not considered safe, a message is 
written at the end of the disassembled file asking the used to check the 
routines manually; the C<set_call> method should then be used to tell how to 
handle calls to that routine on the next iteration.

The C<analyse> function can be called just before dumping the output to try to find 
higher level constructs in the assembly listing. For example, it transforms the
sequence C<ld b,h:ld c,l> into C<ld bc,hl>.

The C<write_asm> dumps an assembly listing that can be re-assembled to obtain the
starting binary file. All the unknown region bytes are disassembled as C<defb> 
instructions, and a map is shown at the end of the file with the code regions (C<C>),
byte regions (C<B>), word regions (C<W>) and unknown regions (C<->).

=head1 FUNCTIONS

=head2 new

Creates the object.

=head2 memory

L<CPU::Z80::Disassembler::Memory|CPU::Z80::Disassembler::Memory> object
containing the memory being analysed.

=head2 instr

Reference to an array that contains all the disassembled instructions
as L<CPU::Z80::Disassembler::Intruction|CPU::Z80::Disassembler::Intruction>
objects, indexed 
by the address of the instruction. The entry is C<undef> if there is no
disassembled instruction at that address (either not known, or pointing to the second,
etc, bytes of a multi-byte instruction).

=head2 labels

Returns the L<CPU::Z80::Disassembler::Labels|CPU::Z80::Disassembler::Labels>
object that contains all the defined labels.

=head2 header, footer

Attributes containing blocks of text to dump before and after the assembly listing.
They are used by C<write_asm>.

=head2 ix_base, iy_base

Base addess for (IX+DIS) and (IY+DIS) instructions, if constant in all the code.
Causes the disassembly to dump:

  IY0 equ 0xHHHH                ; 0xHHHH is iy_base
      ...
      ld  a,(iy+0xHHHH-IY0)     ; 0xHHHH is the absolute address

=cut

#------------------------------------------------------------------------------
# Hold a disassembly session
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(
		'memory',		# memory to disassemble
		'_type',		# identified type of each memory address, TYPE_xxx
		'instr',		# array of Instruction objects at each address
		'labels',		# all defined labels
		'_call_instr',	# hash of all call instructions where we are blocked
		'_can_call',	# hash of all subroutines we may call:
						# 1 	 : can be called, no stack impact
						# 0      : has stack impact, needs to be checked manually
						# sub {} : call sub->($self, $next_addr) to handle 
						#		   stack impact and return next code addresses
						#          to continue disassembly after call
		'_block_comments',	
						# array of block comment string at each address, printed before
						# the address
		'header', 'footer',
						# header and footer sections of disassembled file
		'ix_base', 'iy_base',
						# base addess for (IX+DIS) and (IY+DIS)
);

use constant TYPE_UNKNOWN	=> '-';
use constant TYPE_CODE		=> 'C';
use constant TYPE_BYTE		=> 'B';
use constant TYPE_WORD		=> 'W';
my $TYPES_RE = qr/^[-CBW]$/;

use Exporter 'import';
our @EXPORT = qw( TYPE_UNKNOWN TYPE_CODE TYPE_BYTE TYPE_WORD );


sub new {
	my($class) = @_;
	my $memory = CPU::Z80::Disassembler::Memory->new;
	my $type   = CPU::Z80::Disassembler::Memory->new;
	my $labels = CPU::Z80::Disassembler::Labels->new;
	return bless {	memory 			=> $memory, 
					_type 			=> $type, 
					instr 			=> [],
					labels			=> $labels,
					_call_instr		=> {},
					_can_call		=> {},
					_block_comments	=> [],
				}, $class;
}
#------------------------------------------------------------------------------

=head2 write_dump

Outputs a disassembly dump on the given file, or standard output if no file
provided.

The disassembly dump shows the address and bytes of each instruction with 
the disassembled instruction.

=cut

#------------------------------------------------------------------------------

sub write_dump {
	my($self, $file) = @_;

	my $fh = _opt_output_fh($file);
	
	my $it = $self->memory->loaded_iter;
	my $instr;
	
	while (my($min, $max) = $it->()) {
		for (my $addr = $min; $addr <= $max; $addr = $instr->next_addr) {
			# either a Z80 instruction, or, if not found, a defb
			$instr = CPU::Z80::Disassembler::Instruction->disassemble(
														$self->memory, $addr)
				  || CPU::Z80::Disassembler::Instruction->defb(
														$self->memory, $addr);
			print $fh $instr->dump;
		}
	}
}

#------------------------------------------------------------------------------

=head2 analyse

Analyse the disassembled information looking for higher level constructs.
For example, it replaces 'ld c,(hl):inc hl' by 'ldi c,(hl)'.

Should be called immediately before C<write_asm>.

=cut

#------------------------------------------------------------------------------
sub analyse {
	my($self) = @_;
	
	# search for composed instructions
	my $it = $self->memory->loaded_iter;
	my $limit_addr = $self->_limit_addr(0);
	while (my($min, $max) = $it->()) {
		for (my $addr = $min; $addr <= $max; ) {
			my $instr = $self->instr->[$addr];
			if (defined $instr) {
				if ($instr->is_code) {
				
					# get address of next label
					if ($addr >= $limit_addr) {
						$limit_addr = $self->_limit_addr($addr + 1);
					}
					
					# disassemble long instruction
					my $long_instr = CPU::Z80::Disassembler::Instruction
										->disassemble($self->memory, 
													  $addr, $limit_addr);
					if ($instr->opcode ne $long_instr->opcode) {
						$instr = $self->_merge_instr($long_instr);
					}
				}
				$addr += $instr->size;		# both code and data
			}
			else {
				$addr++;					# undefined
			}
		}
	}
}

sub _merge_instr {
	my($self, $new_instr) = @_;
	
	my @comments;
	push @comments, $new_instr->comment if defined $new_instr->comment;
	for my $addr ($new_instr->addr .. $new_instr->next_addr - 1) {
		my $old_instr = $self->instr->[$addr];
		if ($old_instr) {
			# copy comments
			push @comments, $old_instr->comment if defined $old_instr->comment;
			
			# copy formats
			if (defined $old_instr->_format) {
				for my $key (keys %{$old_instr->_format}) {
					$new_instr->format->{$key} =
							$old_instr->format->{$key};
				}
			}
			
			# delete old
			$self->instr->[$addr] = undef;
		}
	}
	$new_instr->comment(join("\n", @comments)) if @comments;
	$self->instr->[$new_instr->addr] = $new_instr;
	
	return $new_instr;
}

sub _limit_addr {
	my($self, $addr) = @_;
	my $label = $self->labels->next_label($addr);
	my $limit_addr = (defined $label) ? $label->addr : 0x10000;
	return $limit_addr;
}

#------------------------------------------------------------------------------

=head2 write_asm

Outputs a disassembly listing on the given file, or standard output if no file
provided.

The disassembly listing can be assembled to obtain the original binary file.

=cut

#------------------------------------------------------------------------------
sub write_asm {
	my($self, $file) = @_;

	my $fh = _opt_output_fh($file);

	$self->_write_header($fh);
	
	my $comment_it = $self->_block_comments_iter;
	my $it = $self->memory->loaded_iter;
	while (my($min, $max) = $it->()) {
		my $instr = CPU::Z80::Disassembler::Instruction
					->org($self->memory, $min);
		print $fh $instr->asm;
		
		for (my $addr = $min; $addr <= $max; ) {
			# block comments
			print $fh $comment_it->($addr);
			
			$addr = $self->_write_instr($fh, $addr, $max);
		}
		
		print $fh "\n";
	}
	
	# final comments
	print $fh $comment_it->();
	
	print $fh $self->footer if defined $self->footer;

	$self->_write_map($fh);
	$self->_write_labels($fh);
	$self->_write_check_calls($fh);	
}

#------------------------------------------------------------------------------
# iterator to return block comments up to given address
sub _block_comments_iter {
	my($self) = @_;
	my $i = 0;
	return sub {
		my($addr) = @_;
		my $max = $#{$self->_block_comments};
		$addr = $max unless defined $addr;
		
		my $return = "";
		while ($i <= $addr && $i <= $max) {
			my $comment = $self->_block_comments->[$i++];
			$return .= $comment if defined $comment;
		}
		$return;
	};
}

#------------------------------------------------------------------------------
use constant BPL => 16;

#------------------------------------------------------------------------------
# write the file header and the label equates
sub _write_header {
	my($self, $fh) = @_;
	
	my $label_width = $self->labels->max_length + 1;
	
	print $fh $self->header if defined $self->header;
	
	my @labels = sort { $a->addr <=> $b->addr } $self->labels->search_all;
	for my $label (@labels) {
		next if defined $self->instr->[$label->addr];	# no need for EQU
		print $fh $label->equ_string($label_width);
	}
	print $fh "\n" if @labels;
	
	# create IX0 / IY0 base
	my $printed_base;
	for (['IX0', 'ix_base'], ['IY0', 'iy_base']) {
		my($base, $func) = @$_;
		my $addr = $self->$func;
		if (defined $addr) {
			my $label = $self->labels->search_addr($addr);
			if (defined $label) {
				$addr = $label->name;
			}
			else {
				$addr = format_hex4($addr);
			}
			
			print $fh sprintf("%-*s equ %s\n", $label_width-1, $base, $addr);
			$printed_base++;
		}
	}

	print $fh "\n" if $printed_base;
}
	
#------------------------------------------------------------------------------
# write one instruction
sub _write_instr {
	my($self, $fh, $addr, $max) = @_;
	
	# label
	my $label = $self->labels->search_addr($addr);
	print $fh "\n", $label->label_string if (defined $label);

	my $instr = $self->instr->[$addr];
	if (defined $instr) {
		# instruction
		if (defined($instr->NN) && !defined($instr->format->{NN})) {
			# nac the special case of 16-bit (defw) values which can
			# nac potentially be converted to a label
			if (ref($instr->NN)) {
				my $max = scalar(@{$instr->NN});
				for (my $i=0; $i<$max; $i++) {
					my $NN = $instr->NN->[$i];
					my $ref_label = $self->labels->search_addr($NN);
					if (defined($ref_label)) {
						$instr->NN->[$i] = $ref_label->name;
						$instr->format->{NN} = 
							sub { my $foo=shift; 
								if (/^\d+$/) {return format_hex4($foo)} 
								else {return $foo}
							};
					}
				}
			}
			else {
				my $NN = $instr->NN;
				my $ref_label = $self->labels->search_addr($NN);
				if (defined($ref_label)) {
					$instr->format->{NN} = sub { $ref_label->name };
				}
			}
		}
		elsif (defined($instr->DIS) && !defined($instr->format->{DIS})) {
			for (['ix', 'ix_base'], ['iy', 'iy_base']) {
				my($reg, $func) = @$_;
				if ($instr->opcode =~ /$reg/ && defined(my $base = $self->$func)) {
					my $addr = $base + $instr->DIS;
					my $ref_label = $self->labels->search_addr($addr);
					if (defined $ref_label) {
						$instr->format->{DIS} = 
							sub { '+'.$ref_label->name.'-'.uc($reg).'0' };
					}
				}
			}
		}
		print $fh $instr->asm;
		
		return $instr->next_addr;
	}
	else {
		# block of defb

		# search for next defined instr
		my $p;
		for ($p = $addr; $p <= $max && ! defined($self->instr->[$p]) ; $p++) {
			;
		}

		my $comment = "unknown area ".format_hex4($addr)." to ".format_hex4($p-1);
		print $fh "\n", " " x 8, "; Start of $comment\n";
		
		# print for $addr in blocks of 16
		while ($addr < $p) {
			my $max_count = $p - $addr;
			my $count = BPL - ($addr % BPL);				# until end of addr block
			$count = $max_count if $count > $max_count;		# until $p
			
			my $instr = CPU::Z80::Disassembler::Instruction
							->defb($self->memory, $addr, $count);
			print $fh $instr->asm;
			$addr += $count;
		}

		print $fh " " x 8, "; End of $comment\n\n";
			
		return $addr;
	}
}

#------------------------------------------------------------------------------
sub _write_map {
	my($self, $fh) = @_;
	
	my $it = $self->memory->loaded_iter;
	while (my($min, $max) = $it->()) {
		for my $addr ($min .. $max-1) {
			if ($addr == $min || ($addr % 0x50) == 0) {
				print $fh "\n; ", format_hex4($addr), " ";
			}
			print $fh $self->get_type($addr);
		}
		print $fh "\n";
	}
}

#------------------------------------------------------------------------------
sub _write_labels {
	my($self, $fh) = @_;
	
	my @labels = $self->labels->search_all;
	return unless @labels;
	
	my $len = $self->labels->max_length;
	
	my @by_name = sort { lc($a->name) cmp lc($b->name) } @labels;
	my @by_addr = sort {    $a->addr  <=>    $b->addr  } @labels;

	print $fh "\n; Labels\n;\n";
	for (0 .. $#labels) {
		print $fh "; ", format_hex4($by_addr[$_]->addr), " => ", 
						sprintf("%-${len}s", $by_addr[$_]->name),
						" " x 8,
						sprintf("%-${len}s", $by_name[$_]->name), " => ", 
						format_hex4($by_name[$_]->addr), "\n";
	}
}

#------------------------------------------------------------------------------
sub _write_check_calls {
	my($self, $fh) = @_;

	my %unknown_calls;
	for my $addr (keys %{$self->_can_call}) {
		$unknown_calls{$addr}++ unless $self->_can_call->{$addr};
	}
	for my $addr (keys %{$self->_call_instr}) {
		my $instr = $self->_get_instr($addr);
		$unknown_calls{$instr->NN}++;
	}
	
	if (%unknown_calls) {
		print $fh "\n\n; Check these calls manualy: ",
				  join(", ", sort map {format_hex4($_)} keys %unknown_calls), 
				  "\n\n";
	}
}

#------------------------------------------------------------------------------
sub _opt_output_fh {
	my($file) = @_;
	
	# open file
	my $fh;
	if (defined $file) {
		open($fh, ">", $file) or croak("write $file: $!");
	}
	else {
		$fh = \*STDOUT;
	}

	$fh;
}

#------------------------------------------------------------------------------

=head2 set_type_code, set_type_byte, set_type_word

Sets the type of the given address. An optional count allows the definitions of
the type of consecutive memory locations.

It is an error to set a type of a not-defined memory location, 
or to redefine a type.

=cut

#------------------------------------------------------------------------------
sub _set_type {
	my($self, $type, $addr, $count) = @_;
	$count ||= 1;
	
	croak("Invalid type $type") unless $type =~ /$TYPES_RE/;
	
	for ( ; $count > 0 ; $count--, $addr++ ) {
		my $current_type = $self->get_type($addr);
		
		croak("Changing type of address ".format_hex4($addr)." from ".
			  "$current_type to $type")
			if ($current_type ne TYPE_UNKNOWN &&
			    $type         ne TYPE_UNKNOWN &&
				$current_type ne $type);
		
		$self->_type->poke($addr, ord($type));
	}
}
sub set_type_code { shift->_set_type( TYPE_CODE, @_ ) }
sub set_type_byte { shift->_set_type( TYPE_BYTE, @_ ) }
sub set_type_word { shift->_set_type( TYPE_WORD, @_ ) }
		
#------------------------------------------------------------------------------

=head2 get_type

Gets the type at the given address, one of TYPE_UNKNOWN, TYPE_CODE, TYPE_BYTE or 
TYPE_WORD constants.

It is an error to set a type of a not-defined memory location.

=cut

#------------------------------------------------------------------------------
sub get_type {
	my($self, $addr) = @_;
	
	croak("Getting type of unloaded memory at ".format_hex4($addr))
		unless defined $self->memory->peek($addr);
	
	my $current_type = $self->_type->peek($addr);
	$current_type = defined($current_type) ? chr($current_type) : TYPE_UNKNOWN;
	
	croak("Invalid type $current_type") unless $current_type =~ /$TYPES_RE/;
	
	return $current_type;
}

#------------------------------------------------------------------------------

=head2 set_call

Declares a subroutine at the given address, either with no stack impact
(if 1 is passed as argument) or with a stack impact to be computed by the
given code reference. This function is called with $self and the address
after the call instruction as arguments and should return the next address(es)
where the code stream shall continue.

=cut

#------------------------------------------------------------------------------
sub set_call {
	my($self, $addr, $can_call) = @_;
	$self->_can_call->{$addr} = $can_call;
}

#------------------------------------------------------------------------------

=head2 code

Declares the given address and all following instructions up to an unconditional
jump as a block of code, with an optional label.

=cut

#------------------------------------------------------------------------------
sub _get_instr {
	my($self, $addr) = @_;

	# read from cache or disassemble
	$self->instr->[$addr] ||= 
			CPU::Z80::Disassembler::Instruction->disassemble($self->memory, $addr);
}
	
sub code {
	my($self, $addr, $label) = @_;

	defined($label) and $self->labels->add($addr, $label);
	
	my @stack = ($addr);						# all addresses to investigate
	
	# check calls
	while (@stack) {
		# follow all streams of code
		while (@stack) {
			my $addr = pop @stack;
			
			# if address is not loaded, assume a ROM entry point
			if (!defined $self->memory->peek($addr)) {
				if (!$self->labels->search_addr($addr)) {
					my $instr = $self->labels->add($addr);
				}
				next;
			}
			
			# skip if already checked
			next if $self->get_type($addr) eq TYPE_CODE;
			
			# get instruction and mark as code
			my $instr = $self->_get_instr($addr);
			$self->set_type_code($addr, $instr->size);
			
			# create labels for branches (jump or call)
			if ($instr->is_branch) {
				my $branch_addr = $instr->NN;
				my $label = $self->labels->add($branch_addr, undef, $addr);
				$instr->format->{NN} = sub { $label->name };
			}
			
			# check call / rst addresses
			if ($instr->is_call) {
				my $call_addr = $instr->NN;
				my $can_call = $self->_can_call->{$call_addr};
				if (! defined $can_call) {
					$self->_call_instr->{$addr}++;		# mark road block
				}
				elsif (ref $can_call) {
					push @stack, $can_call->($self, $instr->next_addr);
														# call sub to handle impact
				}
				elsif ($can_call) {
					push @stack, $instr->next_addr;		# can continue
				}
			}
			
			# continue on next addresses
			push @stack, $instr->next_code;
		}
	
		# check if we can unwind any blocked calls, after all paths without calls are
		# exhausted
		push @stack, $self->_check_call_instr;
	}
}

#------------------------------------------------------------------------------
sub _check_call_instr {
	my($self) = @_;

	my @stack;
	
	# check simple call instructions where we blocked
	for my $addr (keys %{$self->_call_instr}) {
		my $instr = $self->_get_instr($addr);
		my $call_addr = $instr->NN;
		
		if (	# if any of the calls is conditional, then _can_call
				$instr->opcode =~ /call \w+,NN/
			||	
				# if address after the call is CODE, then _can_call
				$self->get_type($instr->next_addr) eq TYPE_CODE
			) {
			
			# mark for later; do not call code() directly because we are 
			# iterating over _call_instr that might be changed by code()
			$self->_can_call->{$call_addr} = 1;
			push @stack, $instr->next_addr;				# code from here
			delete $self->_call_instr->{$addr};			# processed
		}
	}
	
	# check remaining by following code flow
	for my $addr (keys %{$self->_call_instr}) {
		my $instr = $self->_get_instr($addr);
		my $call_addr = $instr->NN;
		
		# if call flow in called subroutine 
		# does not pop return address, than _can_call
		my $can_call = $self->_check_call($call_addr);
		if (defined $can_call) {
			$self->_can_call->{$call_addr} = $can_call;
			push @stack, $addr;							# re-check call to call can_call 
			$self->_set_type(TYPE_UNKNOWN, $addr, $instr->size);
														# allow recheck to happen
			delete $self->_call_instr->{$addr};			# processed
		}
	}
	
	return @stack;
}

#------------------------------------------------------------------------------
sub _check_call {
	my($self, $call_addr) = @_;
	
	my %seen;									# addresses we have checked
	my($addr, $sp_level) = ($call_addr, 0);
	my @stack = ([$addr, $sp_level]);			# all addresses to investigate
	
	# follow code
	while (@stack) {
		($addr, $sp_level) = @{pop @stack};
		next if $seen{$addr}++;					# prevent loops
		
		# run into some known code
		my $can_call = $self->_can_call->{$addr};
		if (defined $can_call) {
			return $can_call if $sp_level == 0;
		}

		# if address is not loaded, return "dont know"
		if (!defined $self->memory->peek($addr)) {
			return undef;
		}

		# get the instruction
		my $instr = $self->_get_instr($addr);
		local $_ = $instr->opcode;
		
		# check stack impact
		if (/ret/) {
			return 1 if $sp_level == 0;			# can call if stack empty
		}
		elsif (/push/) {
			$sp_level += 2;
		}
		elsif (/pop/) {
			$sp_level -= 2;
			return 0 if $sp_level < 0;			# STACK IMPACT!
		}
		elsif (/dec sp/) {
			$sp_level++;
		}
		elsif (/inc sp/) {
			$sp_level--;
			return 0 if $sp_level < 0;			# STACK IMPACT!
		}
		elsif (/ex \(sp\),/) {
			return 0 if $sp_level < 2;			# STACK IMPACT!
		}
		elsif (/ld sp/) {
			return 0;							# STACK IMPACT!
		}
		
		# continue on next address, but dont follow calls
		if ($instr->is_call) {
			my $can_call = $self->_can_call->{$instr->NN};
			if (defined($can_call) && !ref($can_call) && $can_call) {
				push @stack, [$instr->next_addr, $sp_level];	# continue after call
			}
		}
		elsif ($instr->is_branch) {
			push @stack, [$instr->NN, $sp_level];
		}
		
		push @stack, [$instr->next_addr, $sp_level]	unless $instr->is_break_flow;
	}
	
	return undef;								# don't know
}

#------------------------------------------------------------------------------

=head2 defb, defb2, defw, defm, defmz, defm7

Declares the given address as a def* instruction
with an optional label.

=cut

#------------------------------------------------------------------------------
sub _def {
	my($self, $factory, $set_type,
	   $addr, $count, $label) = @_;

	defined($label) and $self->labels->add($addr, $label);
	
	my $instr = CPU::Z80::Disassembler::Instruction
					->$factory($self->memory, $addr, $count);
	$self->instr->[$addr] = $instr;
	$self->$set_type($addr, $instr->size);
	
	return $instr;
}

sub defb {
	my($self, $addr, $count, $label) = @_;
	$self->_def('defb', 'set_type_byte', $addr, $count, $label);
}

sub defb2 {
	my($self, $addr, $count, $label) = @_;
	$self->_def('defb2', 'set_type_byte', $addr, $count, $label);
}

sub defw {
	my($self, $addr, $count, $label) = @_;
	$self->_def('defw', 'set_type_word', $addr, $count, $label);
}

sub defm {
	my($self, $addr, $length, $label) = @_;
	$self->_def('defm', 'set_type_byte', $addr, $length, $label);
}

sub defmz {
	my($self, $addr, $count, $label) = @_;
	$self->_def('defmz', 'set_type_byte', $addr, $count, $label);
}

sub defm7 {
	my($self, $addr, $count, $label) = @_;
	$self->_def('defm7', 'set_type_byte', $addr, $count, $label);
}

#------------------------------------------------------------------------------

=head2 block_comment

Creates a block comment to insert before the given address.

=cut

#------------------------------------------------------------------------------
sub block_comment {
	my($self, $addr, $block_comment) = @_;
	
	if (defined $block_comment) {
		chomp($block_comment);
		$self->_block_comments->[$addr] ||= "";
		$self->_block_comments->[$addr] .= "$block_comment\n";
	}
}

#------------------------------------------------------------------------------

=head2 line_comments

Appends each of the given line comments to the instrutions starting at 
the given address, one comment per instruction.

=cut

#------------------------------------------------------------------------------
sub line_comments {
	my($self, $addr, @line_comments) = @_;
	
	for (@line_comments) {
		my $instr = $self->instr->[$addr];
		croak("Cannot set comment of unknown instruction at ".format_hex4($addr))
			unless $instr;
		my $old_comment = $instr->comment // "";
		$old_comment .= "\n" if $old_comment;
		$instr->comment($old_comment . $_);
		$addr += $instr->size;
	}
}

#------------------------------------------------------------------------------

=head2 relative_arg

Shows the instruction argument (NN or N) relative to a given label name.
Label name can be '$' for a value relative to the instruction pointer.

=cut

#------------------------------------------------------------------------------

=head2 create_control_file

  $dis->create_control_file($ctl_file, $bin_file, $addr, $arch);

Creates a new control file for the given input binary file, starting at the given address
and for the given architecture. 

The address defaults to zero, and the architecture to undefined. The architecture may be
implemented in the future, for example to define system variable equates for the given
architecture.

It is an error to overwrite a control file.

The Control File is the input file for a disassembly run in an interactive disassembly
session, and the outout is the <bin_file>.asm. After each run, the user studies the output
.asm file, and includes new commands in the control file to add information to the 
.asm file on the next run.

This function creates a template control file that contains just the hex dump of the 
binary file and the decoded assembly instruction at each address, e.g.

  0000                         :F <bin_file>
  0000 D3FD       out ($FD),a
  0002 01FF7F     ld bc,$7FFF
  0005 C3CB03     jp $03CB

The control file commands start with a ':' and refer to the hexadecimal address at the 
start of the line. 

Some commands operate on a range of addresses and accept the inclusive range limits separated
by a single '-'.

A line starting with a blank uses the same address as the previous command.

A semicolon starts a comment in the control file.

  0000      :;        define next address as 0x0000
            :<cmd>  ; <cmd> at the same address 0x0000
  0000-001F :B      ; define a range address of bytes

The dump between the address and the ':' is ignored and is helpfull as a guide while adding 
information to the control file.

=head2 load_control_file

  $dis->load_control_file($ctl_file);

Load the control file created by <create_control_file> and subsequently edited by the user
and create a new .asm disassembly file.

=head1 Control File commands

=head2 Include

Include another control file at the current location.

  #include vars.ctl

=head2 File

Load a binary file at the given address.

  0000 :F zx81.rom

=head2 Code

Define the start of a code routine, with an optional label. The code is not known to be
stack-safe, i.e. not to have data bytes following the call instruction. The disassembler
stops disassembly when it cannot determine if the bytes after a call instruction are 
data or code.

  0000 :C START

=head2 Procedure

Define the start of a procedure with a possible list of arguments following the call
instruction.

The signature is a list of {'B','W','C'}+, identifing each of the following items
after the call instruction (Byte, Word or Code). In the following example the call 
istruction is followed by one byte and one word, and the procedure returns 
to the address after the word.

  0000 P proc B,W,C

The signature defaults to a single 'C', meaning the procedure returns to the point after call.

A signature without a 'C' means that the call never returns.

=head2 Bytes and Words

Define data bytes and words in the given address range.

  0000-0003 :B label
  0000-0003 :B label
  0000-0003 :B2[1] label	; one byte per line, binary data
  0000-0003 :W label

=head2 Define a symbol

Define the name of a symbol.

  4000 := ERR_NO  comment\nline 2 of comment

=head2 IX and IY base

Define base address for IX and IY indexed mode.

  4000 :IX
  4000 :IY

=head2 Header block

Define a text block to be output before the given address. The block is inserted vervbatin,
so include ';' if a comment is intended.

  0000 :# ; header
       :# ; continuation
       :# abc EQU 23

=head2 Line comment

Define a line comment to show at the given address.

  0000 :; comment

=head2 Header and Footer

Define a text block to be output at the top and the bottom of the assembly file. 
The block is inserted vervbatin, so include ';' if a comment is intended.

  0000 :< ; header
       :< ; continuation
       :> ; footer

=cut

#------------------------------------------------------------------------------

sub _find_file {
	my($self, $from_file, $include_file) = @_;
	
	return $include_file if -f $include_file;
	
	# test relative to parent
	my $relative = path(path($from_file)->parent, path($include_file)->basename);
	return $relative if -f $relative;
	
	return $from_file;
}

#------------------------------------------------------------------------------

sub create_control_file {
  my($class, $ctl_file, $bin_file, $addr, $arch) = @_;
  
  -f $ctl_file and die "Error: $ctl_file exists\n";
  
  my $dis = $class->new;
  $dis->memory->load_file($bin_file, $addr);
  $dis->write_dump($ctl_file);
  my @lines = ( <<END,
;------------------------------------------------------------------------------
; CPU::Z80::Disassembler control file
;------------------------------------------------------------------------------

END
		sprintf("%04X :F $bin_file\n\n", $addr),
		path($ctl_file)->lines
	);
	path($ctl_file)->spew(@lines);
}

#------------------------------------------------------------------------------

sub load_control_file {
	my($self, $file) = @_;
	
	my $addr = 0; my $end_addr = 0;
	open(my $fh, $file) or die "cannot open $file\n";
	while (<$fh>) {
		chomp;
		s/^\s*;.*$//; 		# remove comments
		s/\s+$//;
		next unless /\S/;

		if (/^ \#include \s+ (\S+) /ix) {
			$self->load_control_file($self->_find_file($file, $1));
		}
		else {
			# decode start address
			if (s/^ ([0-9a-f]+) //ix) {
				$addr = hex($1);
			}

			# decode end address
			$end_addr = $addr;
			if (s/^ -([0-9a-f]+) //ix) {
				$end_addr = hex($1);
			}

			# remove all chars up to ':', ignore lines without ':'
			/:\s*/ or next;
			$_ = $';
			next unless /\S/;
			
			# decode command
			my($include_file, $label, $comment, $signature, $type);
			
			# File
			if (($include_file) = /^ F \s+ (\S+) /ix) {
				$self->memory->load_file($self->_find_file($file, $include_file), $addr);
			}
			
			# Code
			elsif (($label) = /^ C \s* (\w+)? /ix) {
				$self->code($addr, $label);
			}
			
			# Define label
			elsif (($label, $comment) = /^ = \s+ (\S+) \s* ;? \s*(.*)/ix) {
				$comment =~ s/ \\ n /\n/gx;
				my $instr = $self->labels->add($addr, $label);
				$instr->comment($comment) if $comment;
			}
			
			# Block comment
			elsif (($comment) = /^ \# \s? (.*)/ix) {
				$self->block_comment($addr, $comment);
			}
			
			# Header
			elsif (($comment) = /^ \< \s? (.*)/ix) {
				my $header = $self->header // "";
				$header .= "\n" if $header;
				$self->header($header.$comment);
			}
			
			# Footer
			elsif (($comment) = /^ \> \s? (.*)/ix) {
				my $footer = $self->footer // "";
				$footer .= "\n" if $footer;
				$self->footer($footer.$comment);
			}
			
			# Line comment
			elsif (($comment) = /^ \; [\s;]* (.*)/ix) {
				$self->line_comments($addr, $comment);
			}
			
			# Procedure
			elsif (($label, $signature) = /^ P \s+ (\w+) \s* (.*)/ix) {
				$self->code($addr, $label);
				$signature =~ s/,/ /g;
				my @types = split(' ', $signature);
				@types = ('C') if !@types;
				$self->set_call($addr, sub {
					my($self, $addr) = @_;
					for (@types) {
						if ($_ eq 'B') {
							$self->defb($addr); 
							$addr++
						}
						elsif ($_ eq 'W') {
							$self->defW($addr); 
							$addr += 2;
						}
						elsif ($_ eq 'C') {
							return $addr;
						}
						else {
							die "procedure argument type $_ unknown";
						}
					}
					return;
				});
			}
			
			# Byte | Word
			elsif (my($type, $ipl, $label) = /^ (B2 | B | W | M) (?: \[ (\d+) \] )? \s* (\w+)?/ix) {
				$self->labels->add($addr, $label) if defined $label;
				$ipl = 16 unless $ipl;

				my($func, $size);
				if    ($type eq 'B') {	($func, $size) = ('defb', 1); }
				elsif ($type eq 'B2') {	($func, $size) = ('defb2', 1); }
				elsif ($type eq 'W') {	($func, $size) = ('defw', 2); }
				elsif ($type eq 'M') {	($func, $size) = ('defm', 1); $ipl = 32; }
				else {					die "type $type unknown"; }
				
				if ($size == 2 && $addr == $end_addr) {
					$end_addr++;		# a word uses two addresses
				}
				
				for (my $a = $addr; $a <= $end_addr; ) {
					my $items = int(($end_addr - $a + 1) / $size);
					$items = $ipl if $items > $ipl;
					
					$self->$func($a, $items);
					$a += $size * $items;
				}
			}
			
			# IX
			elsif (/^ IX /ix) {
				$self->ix_base($addr);
			}
			
			# IY
			elsif (/^ IY /ix) {
				$self->iy_base($addr);
			}
			
			# undefined
			else {
				die "Load '$file': cannot parse '$_'";
			}
		}
	}
}
 
#------------------------------------------------------------------------------
sub relative_arg {
	my($self, $addr, $label_name) = @_;

	# disassemble from here, if needed
	$self->code($addr);
	my $instr = $self->_get_instr($addr) or die;
	
	my $label_addr;
	if ($label_name eq '$') {
		$label_addr = $instr->addr;
	}
	else {
		my $label = $self->labels->search_name($label_name)
			or croak("Label '$label_name' not found");
		$label_addr = $label->addr;
	}
	
	my $NN = 	defined($instr->NN) ? 'NN' :
				defined($instr->N ) ? 'N'  :
				croak("Instruction at address ".format_hex4($addr).
					  " has no arguments");
	my $arg = $instr->$NN; 
	$arg = [$arg] unless ref $arg;	# defb stores as [N]
	
	my $delta = $arg->[0] - $label_addr;
	my $expr = $label_name . format_dis($delta);
	$instr->format->{$NN} = sub { $expr };
}

#------------------------------------------------------------------------------

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Paulo Custodio, C<< <pscust at cpan.org> >>

=head1 BUGS and FEEDBACK

Please report any bugs or feature requests through
the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPU-Z80-Disassembler>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Paulo Custodio.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

The Spectrum 48K ROM used in the test scripts is Copyright by Amstrad. 
Amstrad have kindly given their permission for the
redistribution of their copyrighted material but retain that copyright
(see L<http://www.worldofspectrum.org/permits/amstrad-roms.txt>).

=cut

1;
