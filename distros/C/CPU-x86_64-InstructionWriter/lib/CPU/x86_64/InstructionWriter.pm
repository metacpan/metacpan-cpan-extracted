package CPU::x86_64::InstructionWriter;
our $VERSION = '0.001'; # VERSION
use v5.10;
use Moo 2;
use Carp;
use Scalar::Util 'looks_like_number';
use Exporter 'import';
use CPU::x86_64::InstructionWriter::Unknown;
use CPU::x86_64::InstructionWriter::Label;

# ABSTRACT: Assemble x86-64 instructions using a pure-perl API


(0x7FFFFFFE << 31) > 0 && (0x7FFFFFFE << 63) == 0
	or die "Author is lazy and requires 64-bit perl integers\n";
no warnings 'portable';

my @byte_registers= qw( AH AL BH BL CH CL DH DL SPL BPL SIL DIL R8B R9B R10B R11B R12B R13B R14B R15B );
my %byte_register_alias= ( map {; "R${_}L" => "R${_}B" } 8..15 );
my @word_registers= qw( AX BX CX DX SI DI SP BP R8W R9W R10W R11W R12W R13W R14W R15W );
my @long_registers= qw( EAX EBX ECX EDX ESI EDI ESP EBP R8D R9D R10D R11D R12D R13D R14D R15D );
my @quad_registers= qw( RAX RBX RCX RDX RSI RDI RSP RBP R8 R9 R10 R11 R12 R13 R14 R15 RIP RFLAGS );
my @registers= ( @byte_registers, @word_registers, @long_registers, @quad_registers );
{
	# Create a constant for each register name
	no strict 'refs';
	eval 'sub '.$_.' { \''.$_.'\' } 1' || croak $@
		for @registers;
	*{__PACKAGE__."::$_"}= *{__PACKAGE__."::$byte_register_alias{$_}"}
		for keys %byte_register_alias;
}

# Map 64-bit register names to the numeric register number
my %regnum64= (
	RAX => 0, RCX => 1, RDX => 2, RBX => 3,
	rax => 0, rcx => 1, rdx => 2, rbx => 3,
	RSP => 4, RBP => 5, RSI => 6, RDI => 7,
	rsp => 4, rbp => 5, rsi => 6, rdi => 7,
	map { $_ => $_, "R$_" => $_, "r$_" => $_ } 0..15
);

my %regnum32= (
	EAX => 0, ECX => 1, EDX => 2, EBX => 3,
	eax => 0, ecx => 1, edx => 2, ebx => 3,
	ESP => 4, EBP => 5, ESI => 6, EDI => 7,
	esp => 4, ebp => 5, esi => 6, edi => 7,
	map { $_ => $_, "R${_}D" => $_, "r${_}d" => $_ } 0..15
);

my %regnum16= (
	AX => 0, CX => 1, DX => 2, BX => 3,
	ax => 0, cx => 1, dx => 2, bx => 3,
	SP => 4, BP => 5, SI => 6, DI => 7,
	sp => 4, bp => 5, si => 6, di => 7,
	map { $_ => $_, "R${_}W" => $_, "r${_}w" => $_ } 0..15
);

my %regnum8= (
	AL => 0, CL => 1, DL => 2, BL => 3,
	al => 0, cl => 1, dl => 2, bl => 3,
	SPL => 4, BPL => 5, SIL => 6, DIL => 7,
	spl => 4, bpl => 5, sil => 6, dil => 7,
	map { $_ => $_, "R${_}B" => $_, "r${_}b" => $_, "R${_}L" => $_, "r${_}l" => $_ } 0..15
);
my %regnum8_high= (
	AH => 4, CH => 5, DH => 6, BH => 7,
	ah => 4, ch => 5, dh => 6, bh => 7,
);
my %register_bits= (
	(map { $_ => 64 } keys %regnum64),
	(map { $_ => 32 } keys %regnum32),
	(map { $_ => 16 } keys %regnum16),
	(map { $_ =>  8 } keys %regnum8),
);

sub unknown   { CPU::x86_64::InstructionWriter::Unknown->new(name => $_[0]); }
sub unknown8  { CPU::x86_64::InstructionWriter::Unknown->new(bits =>  8, name => $_[0]); }
sub unknown16 { CPU::x86_64::InstructionWriter::Unknown->new(bits => 16, name => $_[0]); }
sub unknown32 { CPU::x86_64::InstructionWriter::Unknown->new(bits => 32, name => $_[0]); }
sub unknown64 { CPU::x86_64::InstructionWriter::Unknown->new(bits => 64, name => $_[0]); }
sub unknown7  { CPU::x86_64::InstructionWriter::Unknown->new(bits =>  7, name => $_[0]); }
sub unknown15 { CPU::x86_64::InstructionWriter::Unknown->new(bits => 15, name => $_[0]); }
sub unknown31 { CPU::x86_64::InstructionWriter::Unknown->new(bits => 31, name => $_[0]); }
sub unknown63 { CPU::x86_64::InstructionWriter::Unknown->new(bits => 63, name => $_[0]); }

our %EXPORT_TAGS= (
	registers    => \@registers,
	unknown      => [qw( unknown unknown8 unknown16 unknown32 unknown64 unknown7 unknown15 unknown31 unknown63 )],
);
our @EXPORT_OK= ( map { @{$_} } values %EXPORT_TAGS );


has start_address         => ( is => 'rw', default => sub { unknown64() } );
has debug                 => ( is => 'rw' );

has _buf                  => ( is => 'rw', default => sub { '' } );
has _unresolved           => ( is => 'rw', default => sub { [] } );


has labels                => ( is => 'rw', default => sub {; {} } );


sub get_label {
	my ($self, $name)= @_;
	my $labels= $self->labels;
	unless (defined $name && defined $labels->{$name}) {
		my $label= bless { relative_to => $self->start_address }, __PACKAGE__.'::Label';
		$name= "$label" unless defined $name;
		$label->{name}= $name;
		$labels->{$name}= $label;
	}
	$labels->{$name};
}


sub label {
	@_ == 2 or croak "Invalid arguments to 'mark'";
	
	# If they gave an undefined label, we auto-populate it, which modifies
	# the variable they passed to this function.
	$_[1]= $_[0]->get_label
		unless defined $_[1];
	
	my ($self, $label)= @_;
	# If they give a label by name, auto-inflate it
	$label= $self->get_label($label)
		unless ref $label;
	
	# A label can only exist once
	defined $label->{offset} and croak "Can't mark label '$label->{name}' twice";
	
	# Set the label's current location
	$label->{offset}= length($self->{_buf});
	$label->{len}= 0;
	
	# Add it to the list of unresolved things, so its position can be updated
	push @{ $self->_unresolved }, $label;
	return $self;
}


sub bytes {
	my $self= shift;
	$self->_resolve;
	return $self->_buf;
}


sub data     { $_[0]{_buf} .= $_[1] }
sub data_i8  { $_[0]{_buf} .= chr($_[1]) }
sub data_i16 { $_[0]{_buf} .= pack('v', $_[1]) }
sub data_i32 { $_[0]{_buf} .= pack('V', $_[1]) }
sub data_i64 { $_[0]{_buf} .= pack('<Q', $_[1]) }


sub data_f32 { $_[0]{_buf} .= pack('f', $_[1]) }
sub data_f64 { $_[0]{_buf} .= pack('d', $_[1]) }


sub align { # ( self, bytes, fill_byte)
	my ($self, $bytes, $fill)= @_;
	($bytes & ($bytes-1))
		and croak "Bytes must be a power of 2";
	$self->_align(~($bytes-1), $fill);
}
sub _align {
	my ($self, $mask, $fill)= @_;
	$fill //= "\x90";
	length($fill) == 1 or croak "Fill byte must be 1 byte long";
	$self->_mark_unresolved(
		0,
		encode => sub {
			#warn "start=$_[1]{start}, mask=$mask, ~mask=${\~$mask} ".((($_[1]{start} + ~$mask) & $mask) - $_[1]{start})."\n";
			$fill x ((($_[1]{offset} + ~$mask) & $mask) - $_[1]{offset})
		}
	);
}
sub align2 { splice @_, 1, 0, ~1; &_align; }
sub align4 { splice @_, 1, 0, ~3; &_align; }
sub align8 { splice @_, 1, 0, ~7; &_align; }


sub _autodetect_signature_dst_src {
	my ($self, $opname, $dst, $src, $bits)= @_;
	$bits ||= $register_bits{$dst} || $register_bits{$src}
		or croak "Can't determine bit-width of ".uc($opname)." instruction. "
		        ."Use ->$opname(\$dst, \$src, \$bits) to clarify, when there is no register";
	my $dst_type= looks_like_number($dst)? 'imm'
	            : ref $dst eq 'ARRAY'? 'mem'
	            : ref $dst && ref($dst)->can('value')? 'imm'
	            : $register_bits{$dst}? 'reg'
	            : croak "Can't identify type of destination operand $dst";
	my $src_type= looks_like_number($src)? 'imm'
	            : ref $src eq 'ARRAY'? 'mem'
	            : ref $src && ref($src)->can('value')? 'imm'
	            : $register_bits{$src}? 'reg'
	            : croak "Can't identify type of source operand $src";
	my $method= "$opname${bits}_${dst_type}_${src_type}";
	($self->can($method) || croak "No ".uc($opname)." variant $method available")
		->($self, $dst, $src);
}

sub _autodetect_signature_1op {
	my ($self, $opname, $operand, $bits)= @_;
	my $opr_type= $register_bits{$operand};
	$bits ||= $opr_type
		or croak "Can't determine bit-width of ".uc($opname)." instruction. "
		        ."Use ->$opname(\$arg, \$bits) to clarify, when \$arg is not a register";
	$opr_type= $opr_type? 'reg'
	         : ref $operand eq 'ARRAY'? 'mem'
	         : looks_like_number($operand)? 'imm'
	         : croak "Can't identify type of operand $operand";
	my $method= "$opname${bits}_${opr_type}";
	($self->can($method) || croak "No ".uc($opname)." variant $method available")
		->($self, $operand);
}


sub nop {
	$_[0]{_buf} .= (defined $_[1]? "\x90" x $_[1] : "\x90");
	$_[0];
}

sub pause {
	$_[0]{_buf} .= (defined $_[1]? "\xF3\x90" x $_[1] : "\xF3\x90");
	$_[0]
}


sub call_label {
	@_ == 2 or croak "Wrong arguments";
	$_[1]= $_[0]->get_label
		unless defined $_[1];
	my ($self, $label)= @_;
	use integer;
	$label= $self->get_label($label)
		unless ref $label;
	$self->_mark_unresolved(
		5, # estimated length
		encode => sub {
			my ($self, $params)= @_;
			defined $label->{offset} or croak "Label $label is not marked";
			my $ofs= $label->{offset} - ($params->{offset}+$params->{len});
			($ofs >> 31) == ($ofs >> 32) or croak "Offset must be within 31 bits";
			return pack('CV', 0xE8, $ofs);
		}
	);
	$self;
}

sub call_rel {
	my ($self, $immed)= @_;
	$self->{_buf} .= pack('CV', 0xE8, ref $immed? 0 : $immed);
	$self->_mark_unresolved(-4, encode => '_repack', bits => 32, value => $immed)
		if ref $immed;
	$self;
}

sub call_abs_reg {
	my ($self, $reg)= @_;
	$self->{_buf} .= $self->_encode_op_reg_reg(0, 0xFF, 2,
		$regnum64{$reg} // croak("$reg is not a 64-bit register"),
	);
	$self;
}

sub call_abs_mem { $_[0]->_append_op64_reg_mem(0, 0xFF, 2, $_[1]) }


sub ret {
	my ($self, $pop_bytes)= @_;
	if ($pop_bytes) {
		$self->{_buf} .= pack('Cv', 0xC2, ref $pop_bytes? 0 : $pop_bytes);
		$self->_mark_unresolved(-2, encode => '_repack', bits => 16, value => $pop_bytes)
			if ref $pop_bytes;
	}
	else {
		$self->{_buf} .= "\xC3";
	}
	$self;
}


sub jmp {
	@_ == 2 or croak "Wrong arguments";
	$_[1]= $_[0]->get_label
		unless defined $_[1];
	my ($self, $label)= @_;
	use integer;
	$label= $self->get_label($label)
		unless ref $label;
	$self->_mark_unresolved(
		2, # estimated length
		encode => sub {
			my ($self, $params)= @_;
			defined $label->{offset} or croak "Label $label is not marked";
			my $ofs= $label->{offset} - ($params->{offset}+$params->{len});
			my $short= (($ofs>>7) == ($ofs>>8));
			return $short?
				pack('Cc', 0xEB, $ofs)
				: pack('CV', 0xE9, $ofs);
		}
	);
	$self;
}


sub jmp_abs_reg {
	my ($self, $reg)= @_;
	$self->{_buf} .= $self->_encode_op_reg_reg(0, 0xFF, 4,
		$regnum64{$reg} // croak("$reg is not a 64-bit register"),
	);
	$self;
}


sub jmp_abs_mem {
	$_[0]->_append_op64_reg_mem(0, 0xFF, 4, $_[1]);
}


sub jmp_if_eq { shift->_append_jmp_cond(4, shift) }
*jz= *jmp_if_eq;
*je= *jmp_if_eq;

sub jmp_if_ne { shift->_append_jmp_cond(5, shift) }
*jne= *jmp_if_ne;
*jnz= *jmp_if_ne;


sub jmp_if_unsigned_lt { shift->_append_jmp_cond(2, shift) }
*jb= *jmp_if_unsigned_lt;
*jc= *jmp_if_unsigned_lt;

sub jmp_if_unsigned_gt { shift->_append_jmp_cond(7, shift) }
*ja= *jmp_if_unsigned_gt;

sub jmp_if_unsigned_le { shift->_append_jmp_cond(6, shift) }
*jbe= *jmp_if_unsigned_le;

sub jmp_if_unsigned_ge { shift->_append_jmp_cond(3, shift) }
*jae= *jmp_if_unsigned_ge;
*jnc= *jmp_if_unsigned_ge;


sub jmp_if_signed_lt { shift->_append_jmp_cond(12, shift) }
*jl= *jmp_if_signed_lt;

sub jmp_if_signed_gt { shift->_append_jmp_cond(15, shift) }
*jg= *jmp_if_signed_gt;

sub jmp_if_signed_le { shift->_append_jmp_cond(14, shift) }
*jle= *jmp_if_signed_le;

sub jmp_if_signed_ge { shift->_append_jmp_cond(13, shift) }
*jge= *jmp_if_signed_ge;


sub jmp_if_sign         { shift->_append_jmp_cond(8, shift) }
*js= *jmp_if_sign;

sub jmp_unless_sign     { shift->_append_jmp_cond(9, shift) }
*jns= *jmp_unless_sign;

sub jmp_if_overflow     { shift->_append_jmp_cond(0, shift) }
*jo= *jmp_if_overflow;

sub jmp_unless_overflow { shift->_append_jmp_cond(1, shift) }
*jno= *jmp_unless_overflow;

sub jmp_if_parity_even  { shift->_append_jmp_cond(10, shift) }
*jpe= *jmp_if_parity_even;
*jp= *jmp_if_parity_even;

sub jmp_if_parity_odd   { shift->_append_jmp_cond(11, shift) }
*jpo= *jmp_if_parity_odd;
*jnp= *jmp_if_parity_odd;


sub jmp_cx_zero { shift->_append_jmp_cx(0xE3, shift) }
*jrcxz= *jmp_cx_zero;

sub loop        { shift->_append_jmp_cx(0xE2, shift) }

sub loopz       { shift->_append_jmp_cx(0xE1, shift) }
*loope= *loopz;

sub loopnz      { shift->_append_jmp_cx(0xE0, shift) }
*loopne= *loopnz;


sub mov { splice(@_,1,0,'mov'); &_autodetect_signature_dst_src }


sub mov64_reg_reg { shift->_append_op64_reg_reg(0x89, $_[1], $_[0]) }
sub mov32_reg_reg { shift->_append_op32_reg_reg(0x89, $_[1], $_[0]) }
sub mov16_reg_reg { shift->_append_op16_reg_reg(0x89, $_[1], $_[0]) }
sub mov8_reg_reg  { shift->_append_op8_reg_reg (0x89, $_[1], $_[0]) }


sub mov64_mem_reg { $_[0]->_append_mov_reg_mem($_[2], $_[1], 64, 0x89, 0xA3); }
sub mov64_reg_mem { $_[0]->_append_mov_reg_mem($_[1], $_[2], 64, 0x8B, 0xA1); }
sub mov32_mem_reg { $_[0]->_append_mov_reg_mem($_[2], $_[1], 32, 0x89, 0xA3); }
sub mov32_reg_mem { $_[0]->_append_mov_reg_mem($_[1], $_[2], 32, 0x8B, 0xA1); }
sub mov16_mem_reg { $_[0]->_append_mov_reg_mem($_[2], $_[1], 16, 0x89, 0xA3); }
sub mov16_reg_mem { $_[0]->_append_mov_reg_mem($_[1], $_[2], 16, 0x8B, 0xA1); }
sub mov8_mem_reg  { $_[0]->_append_mov_reg_mem($_[2], $_[1],  8, 0x88, 0xA2); }
sub mov8_reg_mem  { $_[0]->_append_mov_reg_mem($_[1], $_[2],  8, 0x8A, 0xA0); }

sub _append_mov_reg_mem {
	my ($self, $reg, $mem, $bits, $opcode, $ax_opcode)= @_;
	# AX is allowed to load/store 64-bit addresses, if the address is a single constant
	if (!defined $mem->[0] && $mem->[1] && !defined $mem->[2] && ($mem->[1] > 0x7FFFFFFF || ref $mem->[1])) {
		my $disp= $mem->[1];
		if (lc($reg) eq ($bits == 64? 'rax' : $bits == 32? 'eax' : $bits == 16? 'ax' : 'al')) {
			my $opstr= chr($ax_opcode);
			$opstr= "\x48".$opstr if $bits == 64;
			$opstr= "\x66".$opstr if $bits == 16;
			# Do the dance for values which haven't been resolved yet
			my $val= ref $disp? $disp->value : $disp;
			if (!defined $val) {
				$self->_mark_unresolved(
					10, # longest instruction possible, not the greatest guess.
					encode => sub {
						my $v= $disp->value;
						defined $v or croak "Placeholder $disp has not been assigned";
						return $v > 0x7FFFFFFF? $opstr . pack('Q<', $v)
							: ($bits == 16? "\x66":'')
							. $_[0]->_encode_op_reg_mem($bits == 64? 8 : 0, $opcode, 0, undef, $v);
					}
				);
			} else {
				$self->{_buf} .= $opstr . pack('Q<', $val);
			}
			return $self;
		}
	}
	# Else normal encoding for reg,mem
	return $self->_append_op64_reg_mem(8, $opcode, $reg, $mem) if $bits == 64;
	return $self->_append_op32_reg_mem(0, $opcode, $reg, $mem) if $bits == 32;
	return $self->_append_op16_reg_mem(0, $opcode, $reg, $mem) if $bits == 16;
	return $self->_append_op8_reg_mem (0, $opcode, $reg, $mem) if $bits ==  8;
}



sub mov64_reg_imm {
	my ($self, $reg, $immed)= @_;
	$reg= $regnum64{$reg} // croak("$reg is not a 64-bit register");
	$self->_append_possible_unknown('_encode_mov64_imm', [$reg, $immed], 1, 10);
}
sub _encode_mov64_imm {
	my ($self, $reg, $immed)= @_;
	use integer;
	# If the number fits in 32-bits, encode as the classic instruction
	if (!($immed >> 32)) {
		return $reg > 7? # need REX byte if extended register
			pack('CCL<', 0x41, 0xB8 + ($reg&7), $immed)
			: pack('CL<', 0xB8 + $reg, $immed);
	}
	# If the number can sign-extend from 32-bits, encode as 32-bit sign-extend
	elsif (($immed >> 31) == -1) {
		return pack('CCCl<', 0x48 | (($reg & 8) >> 3), 0xC7, 0xC0 + ($reg & 7), $immed);
	}
	# else encode as new 64-bit immediate
	else {
		return pack('CCQ<', 0x48 | (($reg & 8) >> 3), 0xB8 + ($reg & 7), $immed);
	}
}
sub mov32_reg_imm {
	my ($self, $reg, $immed)= @_;
	$reg= $regnum32{$reg} // croak("$reg is not a 32-bit register");
	$self->{_buf} .= "\x41" if $reg > 7;
	$self->{_buf} .= pack('C' , 0xB8 | ($reg & 7));
	$self->_append_possible_unknown(sub { pack('V', $_[1]) }, [$immed], 0, 4);
}
sub mov16_reg_imm {
	my ($self, $reg, $immed)= @_;
	$reg= $regnum16{$reg} // croak("$reg is not a 16-bit register");
	$self->{_buf} .= "\x66";
	$self->{_buf} .= "\x41" if $reg > 7;
	$self->{_buf} .= pack('C', 0xB8 | ($reg & 7));
	$self->_append_possible_unknown(sub { pack('v', $_[1]) }, [$immed], 0, 2);
}
sub mov8_reg_imm {
	my ($self, $reg, $immed)= @_;
	$reg= $regnum8{$reg};
	# Special case for the high-byte registers available without the REX prefix
	if (!defined $reg) {
		$reg= $regnum8_high{$_[1]} // croak("$_[1] is not a 8-bit register");
	} else {
		$self->{_buf} .= pack('C', 0x40|(($reg&8)>>3)) if $reg > 3;
	}
	$self->{_buf} .= pack('C', 0xB0 | ($reg & 7));
	$self->_append_possible_unknown(sub { pack('C', $_[1]&0xFF) }, [$immed], 0, 1);
}


sub mov64_mem_imm { $_[0]->_append_op64_const_to_mem(0xC7, 0, $_[2], $_[1]) }
sub mov32_mem_imm { $_[0]->_append_op32_const_to_mem(0xC7, 0, $_[2], $_[1]) }
sub mov16_mem_imm { $_[0]->_append_op16_const_to_mem(0xC7, 0, $_[2], $_[1]) }
sub mov8_mem_imm  { $_[0]->_append_op8_const_to_mem (0xC6, 0, $_[2], $_[1]) }


sub lea { splice(@_,1,0,'lea'); &_autodetect_signature_dst_src }

sub lea16_reg_reg { $_[0]->_append_op16_reg_reg(   0x8D, $_[1], $_[2]) }
sub lea16_reg_mem { $_[0]->_append_op16_reg_mem(0, 0x8D, $_[1], $_[2]) }
sub lea32_reg_reg { $_[0]->_append_op32_reg_reg(   0x8D, $_[1], $_[2]) }
sub lea32_reg_mem { $_[0]->_append_op32_reg_mem(0, 0x8D, $_[1], $_[2]) }
sub lea64_reg_reg { $_[0]->_append_op64_reg_reg(   0x8D, $_[1], $_[2]) }
sub lea64_reg_mem { $_[0]->_append_op64_reg_mem(8, 0x8D, $_[1], $_[2]) }


sub add { splice(@_,1,0,'add'); &_autodetect_signature_dst_src }

sub add64_reg_reg { $_[0]->_append_op64_reg_reg(0x01, $_[2], $_[1]) }
sub add32_reg_reg { $_[0]->_append_op32_reg_reg(0x01, $_[2], $_[1]) }
sub add16_reg_reg { $_[0]->_append_op16_reg_reg(0x01, $_[2], $_[1]) }
sub add8_reg_reg  { $_[0]->_append_op8_reg_reg (0x00, $_[2], $_[1]) }

sub add64_reg_mem { $_[0]->_append_op64_reg_mem(8, 0x03, $_[1], $_[2]); }
sub add32_reg_mem { $_[0]->_append_op32_reg_mem(0, 0x03, $_[1], $_[2]); }
sub add16_reg_mem { $_[0]->_append_op16_reg_mem(0, 0x03, $_[1], $_[2]); }
sub add8_reg_mem  { $_[0]->_append_op8_reg_mem (0, 0x02, $_[1], $_[2]); }

sub add64_mem_reg { $_[0]->_append_op64_reg_mem(8, 0x01, $_[2], $_[1]); }
sub add32_mem_reg { $_[0]->_append_op32_reg_mem(0, 0x01, $_[2], $_[1]); }
sub add16_mem_reg { $_[0]->_append_op16_reg_mem(0, 0x01, $_[2], $_[1]); }
sub add8_mem_reg  { $_[0]->_append_op8_reg_mem (0, 0x00, $_[2], $_[1]); }

sub add64_reg_imm { shift->_append_mathop64_const(0x05, 0x83, 0x81, 0, @_) }
sub add32_reg_imm { shift->_append_mathop32_const(0x05, 0x83, 0x81, 0, @_) }
sub add16_reg_imm { shift->_append_mathop16_const(0x05, 0x83, 0x81, 0, @_) }
sub add8_reg_imm  { shift->_append_mathop8_const (0x04, 0x80, 0, @_) }

sub add64_mem_imm { $_[0]->_append_mathop64_const_to_mem(0x83, 0x81, 0, $_[2], $_[1]) }
sub add32_mem_imm { $_[0]->_append_mathop32_const_to_mem(0x83, 0x81, 0, $_[2], $_[1]) }
sub add16_mem_imm { $_[0]->_append_mathop16_const_to_mem(0x83, 0x81, 0, $_[2], $_[1]) }
sub add8_mem_imm  { $_[0]->_append_mathop8_const_to_mem (0x80, 0, $_[2], $_[1]) }


sub addcarry { splice(@_,1,0,'addcarry'); &_autodetect_signature_dst_src }
*adc= *addcarry;

sub addcarry64_reg_reg { $_[0]->_append_op64_reg_reg(0x11, $_[2], $_[1]) }
sub addcarry32_reg_reg { $_[0]->_append_op32_reg_reg(0x11, $_[2], $_[1]) }
sub addcarry16_reg_reg { $_[0]->_append_op16_reg_reg(0x11, $_[2], $_[1]) }
sub addcarry8_reg_reg  { $_[0]->_append_op8_reg_reg (0x10, $_[2], $_[1]) }

sub addcarry64_reg_mem { $_[0]->_append_op64_reg_mem(8, 0x13, $_[1], $_[2]); }
sub addcarry32_reg_mem { $_[0]->_append_op32_reg_mem(0, 0x13, $_[1], $_[2]); }
sub addcarry16_reg_mem { $_[0]->_append_op16_reg_mem(0, 0x13, $_[1], $_[2]); }
sub addcarry8_reg_mem  { $_[0]->_append_op8_reg_mem (0, 0x12, $_[1], $_[2]); }

sub addcarry64_mem_reg { $_[0]->_append_op64_reg_mem(8, 0x11, $_[2], $_[1]); }
sub addcarry32_mem_reg { $_[0]->_append_op32_reg_mem(0, 0x11, $_[2], $_[1]); }
sub addcarry16_mem_reg { $_[0]->_append_op16_reg_mem(0, 0x11, $_[2], $_[1]); }
sub addcarry8_mem_reg  { $_[0]->_append_op8_reg_mem (0, 0x10, $_[2], $_[1]); }

sub addcarry64_reg_imm { shift->_append_mathop64_const(0x15, 0x83, 0x81, 2, @_) }
sub addcarry32_reg_imm { shift->_append_mathop32_const(0x15, 0x83, 0x81, 2, @_) }
sub addcarry16_reg_imm { shift->_append_mathop16_const(0x15, 0x83, 0x81, 2, @_) }
sub addcarry8_reg_imm  { shift->_append_mathop8_const (0x14, 0x80, 2, @_) }

sub addcarry64_mem_imm { $_[0]->_append_mathop64_const_to_mem(0x83, 0x81, 2, $_[2], $_[1]) }
sub addcarry32_mem_imm { $_[0]->_append_mathop32_const_to_mem(0x83, 0x81, 2, $_[2], $_[1]) }
sub addcarry16_mem_imm { $_[0]->_append_mathop16_const_to_mem(0x83, 0x81, 2, $_[2], $_[1]) }
sub addcarry8_mem_imm  { $_[0]->_append_mathop8_const_to_mem (0x80, 2, $_[2], $_[1]) }


sub sub { splice(@_,1,0,'sub'); &_autodetect_signature_dst_src }

sub sub64_reg_reg { $_[0]->_append_op64_reg_reg(0x29, $_[2], $_[1]) }
sub sub32_reg_reg { $_[0]->_append_op32_reg_reg(0x29, $_[2], $_[1]) }
sub sub16_reg_reg { $_[0]->_append_op16_reg_reg(0x29, $_[2], $_[1]) }
sub sub8_reg_reg  { $_[0]->_append_op8_reg_reg (0x28, $_[2], $_[1]) }

sub sub64_reg_mem { $_[0]->_append_op64_reg_mem(8, 0x2B, $_[1], $_[2]); }
sub sub32_reg_mem { $_[0]->_append_op32_reg_mem(0, 0x2B, $_[1], $_[2]); }
sub sub16_reg_mem { $_[0]->_append_op16_reg_mem(0, 0x2B, $_[1], $_[2]); }
sub sub8_reg_mem  { $_[0]->_append_op8_reg_mem (0, 0x2A, $_[1], $_[2]); }

sub sub64_mem_reg { $_[0]->_append_op64_reg_mem(8, 0x29, $_[2], $_[1]); }
sub sub32_mem_reg { $_[0]->_append_op32_reg_mem(0, 0x29, $_[2], $_[1]); }
sub sub16_mem_reg { $_[0]->_append_op16_reg_mem(0, 0x29, $_[2], $_[1]); }
sub sub8_mem_reg  { $_[0]->_append_op8_reg_mem (0, 0x28, $_[2], $_[1]); }

sub sub64_reg_imm { shift->_append_mathop64_const(0x2D, 0x83, 0x81, 5, @_) }
sub sub32_reg_imm { shift->_append_mathop32_const(0x2D, 0x83, 0x81, 5, @_) }
sub sub16_reg_imm { shift->_append_mathop16_const(0x2D, 0x83, 0x81, 5, @_) }
sub sub8_reg_imm  { shift->_append_mathop8_const (0x2C, 0x80, 5, @_) }

sub sub64_mem_imm { $_[0]->_append_mathop64_const_to_mem(0x83, 0x81, 5, $_[2], $_[1]) }
sub sub32_mem_imm { $_[0]->_append_mathop32_const_to_mem(0x83, 0x81, 5, $_[2], $_[1]) }
sub sub16_mem_imm { $_[0]->_append_mathop16_const_to_mem(0x83, 0x81, 5, $_[2], $_[1]) }
sub sub8_mem_imm  { $_[0]->_append_mathop8_const_to_mem (0x80, 5, $_[2], $_[1]) }


sub and { splice(@_,1,0,'and'); &_autodetect_signature_dst_src }

sub and64_reg_reg { $_[0]->_append_op64_reg_reg(0x21, $_[2], $_[1]) }
sub and32_reg_reg { $_[0]->_append_op32_reg_reg(0x21, $_[2], $_[1]) }
sub and16_reg_reg { $_[0]->_append_op16_reg_reg(0x21, $_[2], $_[1]) }
sub and8_reg_reg  { $_[0]->_append_op8_reg_reg (0x20, $_[2], $_[1]) }

sub and64_reg_mem { $_[0]->_append_op64_reg_mem(8, 0x23, $_[1], $_[2]); }
sub and32_reg_mem { $_[0]->_append_op32_reg_mem(0, 0x23, $_[1], $_[2]); }
sub and16_reg_mem { $_[0]->_append_op16_reg_mem(0, 0x23, $_[1], $_[2]); }
sub and8_reg_mem  { $_[0]->_append_op8_reg_mem (0, 0x22, $_[1], $_[2]); }

sub and64_mem_reg { $_[0]->_append_op64_reg_mem(8, 0x21, $_[2], $_[1]); }
sub and32_mem_reg { $_[0]->_append_op32_reg_mem(0, 0x21, $_[2], $_[1]); }
sub and16_mem_reg { $_[0]->_append_op16_reg_mem(0, 0x21, $_[2], $_[1]); }
sub and8_mem_reg  { $_[0]->_append_op8_reg_mem (0, 0x20, $_[2], $_[1]); }

sub and64_reg_imm { shift->_append_mathop64_const(0x25, 0x83, 0x81, 4, @_) }
sub and32_reg_imm { shift->_append_mathop32_const(0x25, 0x83, 0x81, 4, @_) }
sub and16_reg_imm { shift->_append_mathop16_const(0x25, 0x83, 0x81, 4, @_) }
sub and8_reg_imm  { shift->_append_mathop8_const (0x24, 0x80, 4, @_) }

sub and64_mem_imm { $_[0]->_append_mathop64_const_to_mem(0x83, 0x81, 4, $_[2], $_[1]) }
sub and32_mem_imm { $_[0]->_append_mathop32_const_to_mem(0x83, 0x81, 4, $_[2], $_[1]) }
sub and16_mem_imm { $_[0]->_append_mathop16_const_to_mem(0x83, 0x81, 4, $_[2], $_[1]) }
sub and8_mem_imm  { $_[0]->_append_mathop8_const_to_mem (0x80, 4, $_[2], $_[1]) }


sub or { splice(@_,1,0,'or'); &_autodetect_signature_dst_src }

sub or64_reg_reg { $_[0]->_append_op64_reg_reg(0x09, $_[2], $_[1]) }
sub or32_reg_reg { $_[0]->_append_op32_reg_reg(0x09, $_[2], $_[1]) }
sub or16_reg_reg { $_[0]->_append_op16_reg_reg(0x09, $_[2], $_[1]) }
sub or8_reg_reg  { $_[0]->_append_op8_reg_reg (0x08, $_[2], $_[1]) }

sub or64_reg_mem { $_[0]->_append_op64_reg_mem(8, 0x0B, $_[1], $_[2]); }
sub or32_reg_mem { $_[0]->_append_op32_reg_mem(0, 0x0B, $_[1], $_[2]); }
sub or16_reg_mem { $_[0]->_append_op16_reg_mem(0, 0x0B, $_[1], $_[2]); }
sub or8_reg_mem  { $_[0]->_append_op8_reg_mem (0, 0x0A, $_[1], $_[2]); }

sub or64_mem_reg { $_[0]->_append_op64_reg_mem(8, 0x09, $_[2], $_[1]); }
sub or32_mem_reg { $_[0]->_append_op32_reg_mem(0, 0x09, $_[2], $_[1]); }
sub or16_mem_reg { $_[0]->_append_op16_reg_mem(0, 0x09, $_[2], $_[1]); }
sub or8_mem_reg  { $_[0]->_append_op8_reg_mem (0, 0x08, $_[2], $_[1]); }

sub or64_reg_imm { shift->_append_mathop64_const(0x0D, 0x83, 0x81, 1, @_) }
sub or32_reg_imm { shift->_append_mathop32_const(0x0D, 0x83, 0x81, 1, @_) }
sub or16_reg_imm { shift->_append_mathop16_const(0x0D, 0x83, 0x81, 1, @_) }
sub or8_reg_imm  { shift->_append_mathop8_const (0x0C, 0x80, 1, @_) }

sub or64_mem_imm { $_[0]->_append_mathop64_const_to_mem(0x83, 0x81, 1, $_[2], $_[1]) }
sub or32_mem_imm { $_[0]->_append_mathop32_const_to_mem(0x83, 0x81, 1, $_[2], $_[1]) }
sub or16_mem_imm { $_[0]->_append_mathop16_const_to_mem(0x83, 0x81, 1, $_[2], $_[1]) }
sub or8_mem_imm  { $_[0]->_append_mathop8_const_to_mem (0x80, 1, $_[2], $_[1]) }


sub xor { splice(@_,1,0,'xor'); &_autodetect_signature_dst_src }

sub xor64_reg_reg { $_[0]->_append_op64_reg_reg(0x31, $_[2], $_[1]) }
sub xor32_reg_reg { $_[0]->_append_op32_reg_reg(0x31, $_[2], $_[1]) }
sub xor16_reg_reg { $_[0]->_append_op16_reg_reg(0x31, $_[2], $_[1]) }
sub xor8_reg_reg  { $_[0]->_append_op8_reg_reg (0x30, $_[2], $_[1]) }

sub xor64_reg_mem { $_[0]->_append_op64_reg_mem(8, 0x33, $_[1], $_[2]); }
sub xor32_reg_mem { $_[0]->_append_op32_reg_mem(0, 0x33, $_[1], $_[2]); }
sub xor16_reg_mem { $_[0]->_append_op16_reg_mem(0, 0x33, $_[1], $_[2]); }
sub xor8_reg_mem  { $_[0]->_append_op8_reg_mem (0, 0x32, $_[1], $_[2]); }

sub xor64_mem_reg { $_[0]->_append_op64_reg_mem(8, 0x31, $_[2], $_[1]); }
sub xor32_mem_reg { $_[0]->_append_op32_reg_mem(0, 0x31, $_[2], $_[1]); }
sub xor16_mem_reg { $_[0]->_append_op16_reg_mem(0, 0x31, $_[2], $_[1]); }
sub xor8_mem_reg  { $_[0]->_append_op8_reg_mem (0, 0x30, $_[2], $_[1]); }

sub xor64_reg_imm { shift->_append_mathop64_const(0x35, 0x83, 0x81, 6, @_) }
sub xor32_reg_imm { shift->_append_mathop32_const(0x35, 0x83, 0x81, 6, @_) }
sub xor16_reg_imm { shift->_append_mathop16_const(0x35, 0x83, 0x81, 6, @_) }
sub xor8_reg_imm  { shift->_append_mathop8_const (0x34, 0x80, 6, @_) }

sub xor64_mem_imm { $_[0]->_append_mathop64_const_to_mem(0x83, 0x81, 6, $_[2], $_[1]) }
sub xor32_mem_imm { $_[0]->_append_mathop32_const_to_mem(0x83, 0x81, 6, $_[2], $_[1]) }
sub xor16_mem_imm { $_[0]->_append_mathop16_const_to_mem(0x83, 0x81, 6, $_[2], $_[1]) }
sub xor8_mem_imm  { $_[0]->_append_mathop8_const_to_mem (0x80, 6, $_[2], $_[1]) }


sub shl { splice(@_,1,0,'shl'); &_autodetect_signature_dst_src }

sub shl64_reg_imm { $_[0]->_append_shiftop_reg_imm(64, 0xD1, 0xC1, 4, $_[1], $_[2]) }
sub shl32_reg_imm { $_[0]->_append_shiftop_reg_imm(32, 0xD1, 0xC1, 4, $_[1], $_[2]) }
sub shl16_reg_imm { $_[0]->_append_shiftop_reg_imm(16, 0xD1, 0xC1, 4, $_[1], $_[2]) }
sub shl8_reg_imm  { $_[0]->_append_shiftop_reg_imm( 8, 0xD0, 0xC0, 4, $_[1], $_[2]) }

sub shl64_reg_cl  { $_[0]->_append_op64_reg_reg(0xD3, 4, $_[1]) }
sub shl32_reg_cl  { $_[0]->_append_op32_reg_reg(0xD3, 4, $_[1]) }
sub shl16_reg_cl  { $_[0]->_append_op16_reg_reg(0xD3, 4, $_[1]) }
sub shl8_reg_cl   { $_[0]->_append_op8_opreg_reg(0xD2, 4, $_[1]) }

sub shl64_mem_imm { $_[0]->_append_shiftop_mem_imm(64, 0xD1, 0xC1, 4, $_[1], $_[2]) }
sub shl32_mem_imm { $_[0]->_append_shiftop_mem_imm(32, 0xD1, 0xC1, 4, $_[1], $_[2]) }
sub shl16_mem_imm { $_[0]->_append_shiftop_mem_imm(16, 0xD1, 0xC1, 4, $_[1], $_[2]) }
sub shl8_mem_imm  { $_[0]->_append_shiftop_mem_imm( 8, 0xD0, 0xC0, 4, $_[1], $_[2]) }

sub shl64_mem_cl  { $_[0]->_append_op64_reg_mem(8, 0xD3, 4, $_[1]) }
sub shl32_mem_cl  { $_[0]->_append_op32_reg_mem(0, 0xD3, 4, $_[1]) }
sub shl16_mem_cl  { $_[0]->_append_op16_reg_mem(0, 0xD3, 4, $_[1]) }
sub shl8_mem_cl   { $_[0]->_append_op8_opreg_mem(0, 0xD2, 4, $_[1]) }


sub shr { splice(@_,1,0,'shr'); &_autodetect_signature_dst_src }

sub shr64_reg_imm { $_[0]->_append_shiftop_reg_imm(64, 0xD1, 0xC1, 5, $_[1], $_[2]) }
sub shr32_reg_imm { $_[0]->_append_shiftop_reg_imm(32, 0xD1, 0xC1, 5, $_[1], $_[2]) }
sub shr16_reg_imm { $_[0]->_append_shiftop_reg_imm(16, 0xD1, 0xC1, 5, $_[1], $_[2]) }
sub shr8_reg_imm  { $_[0]->_append_shiftop_reg_imm( 8, 0xD0, 0xC0, 5, $_[1], $_[2]) }

sub shr64_reg_cl  { $_[0]->_append_op64_reg_reg(0xD3, 5, $_[1]) }
sub shr32_reg_cl  { $_[0]->_append_op32_reg_reg(0xD3, 5, $_[1]) }
sub shr16_reg_cl  { $_[0]->_append_op16_reg_reg(0xD3, 5, $_[1]) }
sub shr8_reg_cl   { $_[0]->_append_op8_opreg_reg(0xD2, 5, $_[1]) }

sub shr64_mem_imm { $_[0]->_append_shiftop_mem_imm(64, 0xD1, 0xC1, 5, $_[1], $_[2]) }
sub shr32_mem_imm { $_[0]->_append_shiftop_mem_imm(32, 0xD1, 0xC1, 5, $_[1], $_[2]) }
sub shr16_mem_imm { $_[0]->_append_shiftop_mem_imm(16, 0xD1, 0xC1, 5, $_[1], $_[2]) }
sub shr8_mem_imm  { $_[0]->_append_shiftop_mem_imm( 8, 0xD0, 0xC0, 5, $_[1], $_[2]) }

sub shr64_mem_cl  { $_[0]->_append_op64_reg_mem(8, 0xD3, 5, $_[1]) }
sub shr32_mem_cl  { $_[0]->_append_op32_reg_mem(0, 0xD3, 5, $_[1]) }
sub shr16_mem_cl  { $_[0]->_append_op16_reg_mem(0, 0xD3, 5, $_[1]) }
sub shr8_mem_cl   { $_[0]->_append_op8_opreg_mem(0, 0xD2, 5, $_[1]) }


sub sar { splice(@_,1,0,'sar'); &_autodetect_signature_dst_src }

sub sar64_reg_imm { $_[0]->_append_shiftop_reg_imm(64, 0xD1, 0xC1, 7, $_[1], $_[2]) }
sub sar32_reg_imm { $_[0]->_append_shiftop_reg_imm(32, 0xD1, 0xC1, 7, $_[1], $_[2]) }
sub sar16_reg_imm { $_[0]->_append_shiftop_reg_imm(16, 0xD1, 0xC1, 7, $_[1], $_[2]) }
sub sar8_reg_imm  { $_[0]->_append_shiftop_reg_imm( 8, 0xD0, 0xC0, 7, $_[1], $_[2]) }

sub sar64_reg_cl  { $_[0]->_append_op64_reg_reg(0xD3, 7, $_[1]) }
sub sar32_reg_cl  { $_[0]->_append_op32_reg_reg(0xD3, 7, $_[1]) }
sub sar16_reg_cl  { $_[0]->_append_op16_reg_reg(0xD3, 7, $_[1]) }
sub sar8_reg_cl   { $_[0]->_append_op8_opreg_reg(0xD2, 7, $_[1]) }

sub sar64_mem_imm { $_[0]->_append_shiftop_mem_imm(64, 0xD1, 0xC1, 7, $_[1], $_[2]) }
sub sar32_mem_imm { $_[0]->_append_shiftop_mem_imm(32, 0xD1, 0xC1, 7, $_[1], $_[2]) }
sub sar16_mem_imm { $_[0]->_append_shiftop_mem_imm(16, 0xD1, 0xC1, 7, $_[1], $_[2]) }
sub sar8_mem_imm  { $_[0]->_append_shiftop_mem_imm( 8, 0xD0, 0xC0, 7, $_[1], $_[2]) }

sub sar64_mem_cl  { $_[0]->_append_op64_reg_mem(8, 0xD3, 7, $_[1]) }
sub sar32_mem_cl  { $_[0]->_append_op32_reg_mem(0, 0xD3, 7, $_[1]) }
sub sar16_mem_cl  { $_[0]->_append_op16_reg_mem(0, 0xD3, 7, $_[1]) }
sub sar8_mem_cl   { $_[0]->_append_op8_opreg_mem(0, 0xD2, 7, $_[1]) }


sub cmp { splice(@_,1,0,'cmp'); &_autodetect_signature_dst_src }

sub cmp64_reg_reg { $_[0]->_append_op64_reg_reg(0x39, $_[2], $_[1]) }
sub cmp32_reg_reg { $_[0]->_append_op32_reg_reg(0x39, $_[2], $_[1]) }
sub cmp16_reg_reg { $_[0]->_append_op16_reg_reg(0x39, $_[2], $_[1]) }
sub cmp8_reg_reg  { $_[0]->_append_op8_reg_reg (0x38, $_[2], $_[1]) }

sub cmp64_reg_mem { $_[0]->_append_op64_reg_mem(8, 0x3B, $_[1], $_[2]); }
sub cmp32_reg_mem { $_[0]->_append_op32_reg_mem(0, 0x3B, $_[1], $_[2]); }
sub cmp16_reg_mem { $_[0]->_append_op16_reg_mem(0, 0x3B, $_[1], $_[2]); }
sub cmp8_reg_mem  { $_[0]->_append_op8_reg_mem (0, 0x3A, $_[1], $_[2]); }

sub cmp64_mem_reg { $_[0]->_append_op64_reg_mem(8, 0x39, $_[2], $_[1]); }
sub cmp32_mem_reg { $_[0]->_append_op32_reg_mem(0, 0x39, $_[2], $_[1]); }
sub cmp16_mem_reg { $_[0]->_append_op16_reg_mem(0, 0x39, $_[2], $_[1]); }
sub cmp8_mem_reg  { $_[0]->_append_op8_reg_mem (0, 0x38, $_[2], $_[1]); }

sub cmp64_reg_imm { shift->_append_mathop64_const(0x3D, 0x83, 0x81, 7, @_) }
sub cmp32_reg_imm { shift->_append_mathop32_const(0x3D, 0x83, 0x81, 7, @_) }
sub cmp16_reg_imm { shift->_append_mathop16_const(0x3D, 0x83, 0x81, 7, @_) }
sub cmp8_reg_imm  { shift->_append_mathop8_const (0x3C, 0x80, 7, @_) }

sub cmp64_mem_imm { $_[0]->_append_mathop64_const_to_mem(0x83, 0x81, 7, $_[2], $_[1]) }
sub cmp32_mem_imm { $_[0]->_append_mathop32_const_to_mem(0x83, 0x81, 7, $_[2], $_[1]) }
sub cmp16_mem_imm { $_[0]->_append_mathop16_const_to_mem(0x83, 0x81, 7, $_[2], $_[1]) }
sub cmp8_mem_imm  { $_[0]->_append_mathop8_const_to_mem (0x80, 7, $_[2], $_[1]) }


sub test { splice(@_,1,0,'test'); &_autodetect_signature_dst_src }

sub test64_reg_reg { $_[0]->_append_op64_reg_reg(0x85, $_[2], $_[1]) }
sub test32_reg_reg { $_[0]->_append_op32_reg_reg(0x85, $_[2], $_[1]) }
sub test16_reg_reg { $_[0]->_append_op16_reg_reg(0x85, $_[2], $_[1]) }
sub test8_reg_reg  { $_[0]->_append_op8_reg_reg (0x84, $_[2], $_[1]) }

sub test64_reg_mem { $_[0]->_append_op64_reg_mem(8, 0x85, $_[1], $_[2]); }
sub test32_reg_mem { $_[0]->_append_op32_reg_mem(0, 0x85, $_[1], $_[2]); }
sub test16_reg_mem { $_[0]->_append_op16_reg_mem(0, 0x85, $_[1], $_[2]); }
sub test8_reg_mem  { $_[0]->_append_op8_reg_mem (0, 0x84, $_[1], $_[2]); }

sub test64_reg_imm { $_[0]->_append_mathop64_const(0xA9, undef, 0xF7, 0, $_[1], $_[2]) }
sub test32_reg_imm { $_[0]->_append_mathop32_const(0xA9, undef, 0xF7, 0, $_[1], $_[2]) }
sub test16_reg_imm { $_[0]->_append_mathop16_const(0xA9, undef, 0xF7, 0, $_[1], $_[2]) }
sub test8_reg_imm  { $_[0]->_append_mathop8_const (0xA8, 0xF6, 0, $_[1], $_[2]) }

sub test64_mem_imm { $_[0]->_append_mathop64_const_to_mem(undef, 0xF7, 0, $_[2], $_[1]) }
sub test32_mem_imm { $_[0]->_append_mathop32_const_to_mem(undef, 0xF7, 0, $_[2], $_[1]) }
sub test16_mem_imm { $_[0]->_append_mathop16_const_to_mem(undef, 0xF7, 0, $_[2], $_[1]) }
sub test8_mem_imm  { $_[0]->_append_mathop8_const_to_mem (0xF6, 0, $_[2], $_[1]) }


sub dec { splice(@_,1,0,'dec'); &_autodetect_signature_1op; }

sub dec64_reg { $_[0]->_append_op64_reg_reg(0xFF, 1, $_[1]) }
sub dec32_reg { $_[0]->_append_op32_reg_reg(0xFF, 1, $_[1]) }
sub dec16_reg { $_[0]->_append_op16_reg_reg(0xFF, 1, $_[1]) }
sub dec8_reg  { $_[0]->_append_op8_reg_reg (0xFE, 1, $_[1]) }

sub dec64_mem { $_[0]->_append_op64_reg_mem(8, 0xFF, 1, $_[1]) }
sub dec32_mem { $_[0]->_append_op32_reg_mem(0, 0xFF, 1, $_[1]) }
sub dec16_mem { $_[0]->_append_op16_reg_mem(0, 0xFF, 1, $_[1]) }
sub dec8_mem  { $_[0]->_append_op8_reg_mem (0, 0xFE, 1, $_[1]) }


sub inc { splice(@_,1,0,'inc'); &_autodetect_signature_1op; }

sub inc64_reg { $_[0]->_append_op64_reg_reg(0xFF, 0, $_[1]) }
sub inc32_reg { $_[0]->_append_op32_reg_reg(0xFF, 0, $_[1]) }
sub inc16_reg { $_[0]->_append_op16_reg_reg(0xFF, 0, $_[1]) }
sub inc8_reg  { $_[0]->_append_op8_reg_reg (0xFE, 0, $_[1]) }

sub inc64_mem { $_[0]->_append_op64_reg_mem(8, 0xFF, 0, $_[1]) }
sub inc32_mem { $_[0]->_append_op32_reg_mem(0, 0xFF, 0, $_[1]) }
sub inc16_mem { $_[0]->_append_op16_reg_mem(0, 0xFF, 0, $_[1]) }
sub inc8_mem  { $_[0]->_append_op8_reg_mem (0, 0xFE, 0, $_[1]) }


sub not { splice(@_,1,0,'not'); &_autodetect_signature_1op; }

sub not64_reg { $_[0]->_append_op64_reg_reg(0xF7, 2, $_[1]) }
sub not32_reg { $_[0]->_append_op32_reg_reg(0xF7, 2, $_[1]) }
sub not16_reg { $_[0]->_append_op16_reg_reg(0xF7, 2, $_[1]) }
sub not8_reg  { $_[0]->_append_op8_reg_reg (0xF6, 2, $_[1]) }

sub not64_mem { $_[0]->_append_op64_reg_mem(8, 0xF7, 2, $_[1]) }
sub not32_mem { $_[0]->_append_op32_reg_mem(0, 0xF7, 2, $_[1]) }
sub not16_mem { $_[0]->_append_op16_reg_mem(0, 0xF7, 2, $_[1]) }
sub not8_mem  { $_[0]->_append_op8_reg_mem (0, 0xF6, 2, $_[1]) }


sub neg { splice(@_,1,0,'neg'); &_autodetect_signature_1op; }

sub neg64_reg { $_[0]->_append_op64_reg_reg(0xF7, 3, $_[1]) }
sub neg32_reg { $_[0]->_append_op32_reg_reg(0xF7, 3, $_[1]) }
sub neg16_reg { $_[0]->_append_op16_reg_reg(0xF7, 3, $_[1]) }
sub neg8_reg  { $_[0]->_append_op8_reg_reg (0xF6, 3, $_[1]) }

sub neg64_mem { $_[0]->_append_op64_reg_mem(8, 0xF7, 3, $_[1]) }
sub neg32_mem { $_[0]->_append_op32_reg_mem(0, 0xF7, 3, $_[1]) }
sub neg16_mem { $_[0]->_append_op16_reg_mem(0, 0xF7, 3, $_[1]) }
sub neg8_mem  { $_[0]->_append_op8_reg_mem (0, 0xF6, 3, $_[1]) }


sub div  { splice(@_,1,0,'div' ); &_autodetect_signature_1op; }
sub idiv { splice(@_,1,0,'idiv'); &_autodetect_signature_1op; }

sub div64_reg { $_[0]->_append_op64_reg_reg (0xF7, 6, $_[1]) }
sub div32_reg { $_[0]->_append_op32_reg_reg (0xF7, 6, $_[1]) }
sub div16_reg { $_[0]->_append_op16_reg_reg (0xF7, 6, $_[1]) }
sub div8_reg  { $_[0]->_append_op8_opreg_reg(0xF6, 6, $_[1]) }

sub div64_mem { $_[0]->_append_op64_reg_mem (8, 0xF7, 6, $_[1]) }
sub div32_mem { $_[0]->_append_op32_reg_mem (0, 0xF7, 6, $_[1]) }
sub div16_mem { $_[0]->_append_op16_reg_mem (0, 0xF7, 6, $_[1]) }
sub div8_mem  { $_[0]->_append_op8_opreg_mem(0, 0xF6, 6, $_[1]) }

sub idiv64_reg { $_[0]->_append_op64_reg_reg (0xF7, 7, $_[1]) }
sub idiv32_reg { $_[0]->_append_op32_reg_reg (0xF7, 7, $_[1]) }
sub idiv16_reg { $_[0]->_append_op16_reg_reg (0xF7, 7, $_[1]) }
sub idiv8_reg  { $_[0]->_append_op8_opreg_reg(0xF6, 7, $_[1]) }

sub idiv64_mem { $_[0]->_append_op64_reg_mem (8, 0xF7, 7, $_[1]) }
sub idiv32_mem { $_[0]->_append_op32_reg_mem (0, 0xF7, 7, $_[1]) }
sub idiv16_mem { $_[0]->_append_op16_reg_mem (0, 0xF7, 7, $_[1]) }
sub idiv8_mem  { $_[0]->_append_op8_opreg_mem(0, 0xF6, 7, $_[1]) }


#=item mul64_reg
#
#=item mul32_reg
#
#=item mul16_reg
#
#=item mul64_mem
#
#=item mul32_mem
#
#=item mul16_mem
#
#=item mul64_reg_imm
#
#=item mul32_reg_imm
#
#=item mul16_reg_imm
#
#=item mul64_mem_imm
#
#=item mul32_mem_imm
#
#=item mul16_mem_imm

sub mul64_dxax_reg { shift->_append_op64_reg_reg(8, 0xF7, 5, @_) }
sub mul32_dxax_reg { shift->_append_op32_reg_reg(0, 0xF7, 5, @_) }
sub mul16_dxax_reg { shift->_append_op16_reg_reg(0, 0xF7, 5, @_) }
sub mul8_ax_reg    { shift->_append_op8_reg_reg (0, 0xF6, 5, @_) }

#sub mul64s_reg { shift->_append_op64_reg_reg(8, 


sub sign_extend_al_ax { $_[0]{_buf} .= "\x66\x98"; $_[0] }
*cbw= *sign_extend_al_ax;

sub sign_extend_ax_eax { $_[0]{_buf} .= "\x98"; $_[0] }
*cwde= *sign_extend_ax_eax;

sub sign_extend_eax_rax { $_[0]{_buf} .= "\x48\x98"; $_[0] }
*cdqe= *sign_extend_eax_rax;

sub sign_extend_ax_dx { $_[0]{_buf} .= "\x66\x99"; $_[0] }
*cwd= *sign_extend_ax_dx;

sub sign_extend_eax_edx { $_[0]{_buf} .= "\x99"; $_[0] }
*cdq= *sign_extend_eax_edx;

sub sign_extend_rax_rdx { $_[0]{_buf} .= "\x48\x99"; $_[0] }
*cqo= *sign_extend_rax_rdx;


my @_carry_flag_op= ( "\xF5", "\xF8", "\xF9" );
sub flag_carry { $_[0]{_buf} .= $_carry_flag_op[$_[1] + 1]; $_[0] }
sub clc { $_[0]{_buf} .= "\xF8"; $_[0] }
sub cmc { $_[0]{_buf} .= "\xF5"; $_[0] }
sub stc { $_[0]{_buf} .= "\xF9"; $_[0] }


# wait til late in compilation to avoid name clash hassle
END { eval q|sub push { splice(@_,1,0,'push' ); &_autodetect_signature_1op; }| };

sub push_reg {
	my ($self, $reg)= @_;
	$reg= ($regnum64{$reg} // croak("$reg is not a 64-bit register"));
	$self->{_buf} .= $reg > 7? pack('CC', 0x41, 0x50+($reg&7)) : pack('C', 0x50+($reg&7));
	$self;
}

sub push_imm {
	my ($self, $imm)= @_;
	use integer;
	my $val= ref $imm? 0x7FFFFFFF : $imm;
	$self->{_buf} .= (($val >> 7) == ($val >> 8))? pack('Cc', 0x6A, $val) : pack('CV', 0x68, $val);
	$self->_mark_unresolved(-4, encode => '_repack', bits => 32, value => $imm)
		if ref $imm;
	$self;
}

sub push_mem { shift->_append_op64_reg_mem(0, 0xFF, 6, shift) }


# wait til late in compilation to avoid name clash hassle
END { eval q|sub pop { splice(@_,1,0,'pop' ); &_autodetect_signature_1op; }| };

sub pop_reg {
	my ($self, $reg)= @_;
	$reg= ($regnum64{$reg} // croak("$reg is not a 64-bit register"));
	$self->{_buf} .= $reg > 7? pack('CC', 0x41, 0x58+($reg&7)) : pack('C', 0x58+($reg&7));
	$self;
}

sub pop_mem { shift->_append_op64_reg_mem(0, 0x8F, 0, shift) }


sub enter {
	my ($self, $varspace, $nesting)= @_;
	$nesting //= 0;
	if (!ref $varspace && !ref $nesting) {
		$self->{_buf} .= pack('CvC', 0xC8, $varspace, $nesting);
	}
	else {
		$self->{_buf} .= pack('Cv', 0xC8, ref $varspace? 0 : $varspace);
		$self->_mark_unresolved(-2, encode => '_repack', bits => 16, value => $varspace)
			if ref $varspace;
		$self->{_buf} .= pack('C', ref $nesting? 0 : $nesting);
		$self->_mark_unresolved(-1, encode => '_repack', bits => 8, value => $nesting)
			if ref $nesting;
	}
	$self
}


sub leave { $_[0]{_buf} .= "\xC9"; $_[0] }


sub syscall {
	$_[0]{_buf} .= "\x0F\x05";
	$_[0];
}


sub rep { $_[0]{_buf} .= "\xF3"; $_[0] }
*repe= *repz= *rep;

sub repnz { $_[0]{_buf} .= "\xF2"; $_[0] }
*repne= *repnz;


my @_direction_flag_op= ( "\xFC", "\xFD" );
sub flag_direction { $_[0]{_buf} .= $_direction_flag_op[0+!!$_[1]]; $_[0] }
sub cld { $_[0]{_buf} .= "\xFC"; $_[0] }
sub std { $_[0]{_buf} .= "\xFD"; $_[0] }


sub movs64 { $_[0]{_buf} .= "\x48\xA5"; $_[0] }
*movsq= *movs64;

sub movs32 { $_[0]{_buf} .= "\xA5"; $_[0] }
*movsd= *movs32;

sub movs16 { $_[0]{_buf} .= "\x66\xA5"; $_[0] }
*movsw= *movs16;

sub movs8  { $_[0]{_buf} .= "\xA4"; $_[0] }
*movsb= *movs8;


sub cmps64 { $_[0]{_buf}.= "\x48\xA7"; $_[0] }
*cmpsq= *cmps64;

sub cmps32 { $_[0]{_buf}.= "\xA7"; $_[0] }
*cmpsd= *cmps32;

sub cmps16 { $_[0]{_buf}.= "\x66\xA7"; $_[0] }
*cmpsw= *cmps16;

sub cmps8  { $_[0]{_buf}.= "\xA6"; $_[0] }
*cmpsb= *cmps8;


sub scas64 { $_[0]{_buf} .= "\x48\xAF"; $_[0] }
*scasq= *scas64;

sub scas32 { $_[0]{_buf} .= "\xAF"; $_[0] }
*scasd= *scas32;

sub scas16 { $_[0]{_buf} .= "\x66\xAF"; $_[0] }
*scasw= *scas16;

sub scas8 { $_[0]{_buf} .= "\xAE"; $_[0] }
*scasb= *scas8;


sub mfence {
	$_[0]{_buf} .= "\x0F\xAE\xF0";
	$_[0];
}
sub lfence {
	$_[0]{_buf} .= "\x0F\xAE\xE8";
	$_[0];
}
sub sfence {
	$_[0]{_buf} .= "\x0F\xAE\xF8";
	$_[0];
}

#sub cache_flush {
#	...;
#}
#*clflush= *cache_flush;


#=head2 _encode_op_reg_reg
#
#Encode standard instruction with REX prefix which refers only to registers.
#This skips all the memory addressing logic since it is only operating on registers,
#and always produces known-length encodings.
#
#=cut

sub _encode_op_reg_reg {
	my ($self, $rex, $opcode, $reg1, $reg2, $immed_pack, $immed)= @_;
	use integer;
	$rex |= (($reg1 & 8) >> 1) | (($reg2 & 8) >> 3);
	return $rex?
		(defined $immed?
			pack('CCC'.$immed_pack, 0x40|$rex, $opcode, 0xC0 | (($reg1 & 7) << 3) | ($reg2 & 7), $immed)
			: pack('CCC', 0x40|$rex, $opcode, 0xC0 | (($reg1 & 7) << 3) | ($reg2 & 7))
		)
		: (defined $immed?
			pack('CC'.$immed_pack, $opcode, 0xC0 | (($reg1 & 7) << 3) | ($reg2 & 7), $immed)
			: pack('CC', $opcode, 0xC0 | (($reg1 & 7) << 3) | ($reg2 & 7))
		);
}

sub _append_op64_reg_reg {
	my ($self, $opcode, $reg1, $reg2)= @_;
	$reg1= ($regnum64{$reg1} // croak("$reg1 is not a 64-bit register"));
	$reg2= ($regnum64{$reg2} // croak("$reg2 is not a 64-bit register"));
	use integer;
	$self->{_buf} .= pack('CCC',
		0x48 | (($reg1 & 8) >> 1) | (($reg2 & 8) >> 3),
		$opcode, 0xC0 | (($reg1 & 7) << 3) | ($reg2 & 7));
	$self;
}
sub _append_op32_reg_reg {
	my ($self, $opcode, $reg1, $reg2)= @_;
	$reg1= ($regnum32{$reg1} // croak("$reg1 is not a 32-bit register"));
	$reg2= ($regnum32{$reg2} // croak("$reg2 is not a 32-bit register"));
	use integer;
	my $rex= (($reg1 & 8) >> 1) | (($reg2 & 8) >> 3);
	$self->{_buf} .= $rex?
		pack('CCC', 0x40|$rex, $opcode, 0xC0 | (($reg1 & 7) << 3) | ($reg2 & 7))
		: pack('CC', $opcode, 0xC0 | (($reg1 & 7) << 3) | ($reg2 & 7));
	$self;
}
sub _append_op16_reg_reg {
	my ($self, $opcode, $reg1, $reg2)= @_;
	$reg1= ($regnum16{$reg1} // croak("$reg1 is not a 16-bit register"));
	$reg2= ($regnum16{$reg2} // croak("$reg2 is not a 16-bit register"));
	use integer;
	my $rex= (($reg1 & 8) >> 1) | (($reg2 & 8) >> 3);
	$self->{_buf} .= $rex?
		pack('CCCC', 0x66, 0x40|$rex, $opcode, 0xC0 | (($reg1 & 7) << 3) | ($reg2 & 7))
		: pack('CCC', 0x66, $opcode, 0xC0 | (($reg1 & 7) << 3) | ($reg2 & 7));
	$self;
}
sub _append_op8_reg_reg {
	my ($self, $opcode, $reg1, $reg2)= @_;
	use integer;
	$reg1= $regnum8{$reg1};
	$reg2= $regnum8{$reg2};
	# special case for the "high byte" registers.  They can't be used in an
	# instruction that uses the REX prefix.
	if (!defined $reg1 || !defined $reg2) {
		my $old_reg1= $reg1;
		my $old_reg2= $reg2;
		$reg1= $regnum8_high{$_[2]} // croak "$_[2] is not a valid 8-bit register";
		$reg2= $regnum8_high{$_[3]} // croak "$_[3] is not a valid 8-bit register";
		if (($old_reg1 && $old_reg1 > 3) || ($old_reg2 && $old_reg2 > 3)) {
			croak "Can't combine $_[2] with $_[3] in same instruction"; 
		}
		$self->{_buf} .= pack('CC', $opcode, 0xC0 | ($reg1 << 3) | $reg2);
	}
	else {
		$self->{_buf} .= ($reg1 > 3 || $reg2 > 3)?
			pack('CCC', 0x40|(($reg1 & 8) >> 1) | (($reg2 & 8) >> 3), $opcode, 0xC0 | (($reg1 & 7) << 3) | ($reg2 & 7))
			: pack('CC', $opcode, 0xC0 | ($reg1 << 3) | $reg2);
	}
	$self;
}

# Like above, but the first register argument isn't really a register argument
# and therefore doesn't require a 0x40 prefix for values > 3
sub _append_op8_opreg_reg {
	my ($self, $opcode, $opreg, $reg2)= @_;
	use integer;
	$reg2= $regnum8{$reg2};
	# special case for the "high byte" registers.  They can't be used in an
	# instruction that uses the REX prefix.
	if (!defined $reg2) {
		my $old_reg2= $reg2;
		$reg2= $regnum8_high{$_[3]} // croak "$_[3] is not a valid 8-bit register";
		$self->{_buf} .= pack('CC', $opcode, 0xC0 | ($opreg << 3) | $reg2);
	}
	else {
		$self->{_buf} .= ($reg2 > 3)?
			pack('CCC', 0x40| (($reg2 & 8) >> 3), $opcode, 0xC0 | ($opreg << 3) | ($reg2 & 7))
			: pack('CC', $opcode, 0xC0 | ($opreg << 3) | $reg2);
	}
	$self;
}

#=head2 _append_op##_reg_mem
#
#Encode standard ##-bit instruction with REX prefix which addresses memory for one of its operands.
#The encoded length might not be resolved until later if an unknown displacement value was given.
#
#=cut

sub _append_op64_reg_mem {
	my ($self, $rex, $opcode, $reg, $mem)= @_;
	my ($base_reg, $disp, $index_reg, $scale)= @$mem;
	$reg= $regnum64{$reg} // croak "$reg is not a valid 64-bit register"
		if defined $reg;
	$base_reg= $regnum64{$base_reg} // croak "$base_reg is not a valid 64-bit register"
		if defined $base_reg;
	$index_reg= $regnum64{$index_reg} // croak "$index_reg is not a valid 64-bit register"
		if defined $index_reg;
	$self->_append_possible_unknown('_encode_op_reg_mem', [$rex, $opcode, $reg, $base_reg, $disp, $index_reg, $scale], 4, 7);
	$self;
}

sub _append_op32_reg_mem {
	my ($self, $rex, $opcode, $reg, $mem)= @_;
	my ($base_reg, $disp, $index_reg, $scale)= @$mem;
	$reg= $regnum32{$reg} // croak "$reg is not a valid 32-bit register"
		if defined $reg;
	$base_reg= $regnum64{$base_reg} // croak "$base_reg is not a valid 64-bit register"
		if defined $base_reg;
	$index_reg= $regnum64{$index_reg} // croak "$index_reg is not a valid 64-bit register"
		if defined $index_reg;
	$self->_append_possible_unknown('_encode_op_reg_mem', [$rex, $opcode, $reg, $base_reg, $disp, $index_reg, $scale], 4, 7);
}

sub _append_op16_reg_mem {
	my ($self, $rex, $opcode, $reg, $mem)= @_;
	my ($base_reg, $disp, $index_reg, $scale)= @$mem;
	$reg= $regnum16{$reg} // croak "$reg is not a valid 16-bit register"
		if defined $reg;
	$base_reg= $regnum64{$base_reg} // croak "$base_reg is not a valid 64-bit register"
		if defined $base_reg;
	$index_reg= $regnum64{$index_reg} // croak "$index_reg is not a valid 64-bit register"
		if defined $index_reg;
	$self->{_buf} .= "\x66";
	$self->_append_possible_unknown('_encode_op_reg_mem', [$rex, $opcode, $reg, $base_reg, $disp, $index_reg, $scale], 4, 7);
}

sub _append_op8_reg_mem {
	my ($self, $rex, $opcode, $reg, $mem)= @_;
	my ($base_reg, $disp, $index_reg, $scale)= @$mem;
	$base_reg= $regnum64{$base_reg} // croak "$base_reg is not a valid 64-bit register"
		if defined $base_reg;
	$index_reg= $regnum64{$index_reg} // croak "$index_reg is not a valid 64-bit register"
		if defined $index_reg;
	$reg= $regnum8{$reg};
	# special case for the "high byte" registers
	if (!defined $reg) {
		$reg= $regnum8_high{$_[3]} // croak "$_[3] is not a valid 8-bit register";
		!$rex && ($base_reg//0) < 8 && ($index_reg//0) < 8
			or croak "Cannot use $_[3] in instruction with REX prefix";
	}
	# special case for needing REX byte for SPL, BPL, DIL, and SIL
	elsif ($reg > 3) {
		$rex |= 0x40;
	}
	$self->_append_possible_unknown('_encode_op_reg_mem', [$rex, $opcode, $reg, $base_reg, $disp, $index_reg, $scale], 4, 7);
}
# Like above, but the first register is a constant and don't need to test it for
# requiring a REX prefix if >3.
sub _append_op8_opreg_mem {
	my ($self, $rex, $opcode, $opreg, $mem)= @_;
	my ($base_reg, $disp, $index_reg, $scale)= @$mem;
	$base_reg= $regnum64{$base_reg} // croak "$base_reg is not a valid 64-bit register"
		if defined $base_reg;
	$index_reg= $regnum64{$index_reg} // croak "$index_reg is not a valid 64-bit register"
		if defined $index_reg;
	$self->_append_possible_unknown('_encode_op_reg_mem', [$rex, $opcode, $opreg, $base_reg, $disp, $index_reg, $scale], 4, 7);
}

#=head2 _append_op##_const_to_mem
#
#Encode standard ##-bit instruction with REX prefix which operates on a constant and then
#writes to a memory location.
#
#=cut

sub _append_op8_const_to_mem {
	my ($self, $opcode, $opreg, $value, $mem)= @_;
	my ($base_reg, $disp, $index_reg, $scale)= @$mem;
	$base_reg= ($regnum64{$base_reg} // croak "$base_reg is not a 64-bit register")
		if defined $base_reg;
	$index_reg= ($regnum64{$index_reg} // croak "$index_reg is not a 64-bit register")
		if defined $index_reg;
	$self->_append_possible_unknown('_encode_op_reg_mem', [ 0, $opcode, $opreg, $base_reg, $disp, $index_reg, $scale, 'C', $value ], ref $disp? 4 : 8, defined $disp? 16:12);
}
sub _append_op16_const_to_mem {
	my ($self, $opcode, $opreg, $value, $mem)= @_;
	my ($base_reg, $disp, $index_reg, $scale)= @$mem;
	$base_reg= ($regnum64{$base_reg} // croak "$base_reg is not a 64-bit register")
		if defined $base_reg;
	$index_reg= ($regnum64{$index_reg} // croak "$index_reg is not a 64-bit register")
		if defined $index_reg;
	$self->{_buf} .= "\x66";
	$self->_append_possible_unknown('_encode_op_reg_mem', [ 0, $opcode, $opreg, $base_reg, $disp, $index_reg, $scale, 'v', $value ], ref $disp? 4 : 8, defined $disp? 16:12);
}
sub _append_op32_const_to_mem {
	my ($self, $opcode, $opreg, $value, $mem)= @_;
	my ($base_reg, $disp, $index_reg, $scale)= @$mem;
	$base_reg= ($regnum64{$base_reg} // croak "$base_reg is not a 64-bit register")
		if defined $base_reg;
	$index_reg= ($regnum64{$index_reg} // croak "$index_reg is not a 64-bit register")
		if defined $index_reg;
	$self->_append_possible_unknown('_encode_op_reg_mem', [ 0, $opcode, $opreg, $base_reg, $disp, $index_reg, $scale, 'V', $value ], ref $disp? 4 : 8, defined $disp? 16:12);
}
sub _append_op64_const_to_mem {
	my ($self, $opcode, $opreg, $value, $mem)= @_;
	my ($base_reg, $disp, $index_reg, $scale)= @$mem;
	$base_reg= ($regnum64{$base_reg} // croak "$base_reg is not a 64-bit register")
		if defined $base_reg;
	$index_reg= ($regnum64{$index_reg} // croak "$index_reg is not a 64-bit register")
		if defined $index_reg;
	$self->_append_possible_unknown('_encode_op_reg_mem', [ 8, $opcode, $opreg, $base_reg, $disp, $index_reg, $scale, 'V', $value ], ref $disp? 4 : 8, defined $disp? 16:12);
}


# scale values for the SIB byte
my %SIB_scale= (
	1 => 0x00,
	2 => 0x40,
	4 => 0x80,
	8 => 0xC0
);

sub _encode_op_reg_mem {
	my ($self, $rex, $opcode, $reg, $base_reg, $disp, $index_reg, $scale, $immed_pack, $immed)= @_;
	use integer;
	$rex |= ($reg & 8) >> 1;
	
	my $tail;
	if (defined $base_reg) {
		$rex |= ($base_reg & 8) >> 3;
		
		# RBP,R13 always gets mod_rm displacement to differentiate from Null base register
		my ($mod_rm, $suffix)= !$disp? ( ($base_reg&7) == 5? (0x40, "\0") : (0x00, '') )
			: (($disp >>  7) == ($disp >>  8))? (0x40, pack('c', $disp))
			: (($disp >> 31) == ($disp >> 32))? (0x80, pack('V', $disp))
			: croak "address displacement out of range: $disp";
		
		if (defined $index_reg) {
			my $scale= $SIB_scale{$scale // 1} // croak "invalid index multiplier $scale";
			$index_reg != 4 or croak "RSP cannot be used as index register";
			$rex |= ($index_reg & 8) >> 2;
			$tail= pack('CC', $mod_rm | (($reg & 7) << 3) | 4, $scale | (($index_reg & 7) << 3) | ($base_reg & 7)) . $suffix;
		}
		# RSP,R12 always gets a SIB byte
		elsif (($base_reg&7) == 4) {
			$tail= pack('CC', $mod_rm | (($reg & 7) << 3) | 4, 0x24) . $suffix;
		}
		else {
			# Null index register is encoded as RSP
			$tail= pack('C', $mod_rm | (($reg & 7) << 3) | ($base_reg & 7)) . $suffix;
		}
	} else {
		# Null base register is encoded as RBP + 32bit displacement
		
		(($disp >> 31) == ($disp >> 32))
			or croak "address displacement out of range: $disp";
		
		if (defined $index_reg) {
			my $scale= $SIB_scale{$scale // 1} // croak "invalid index multiplier $scale";
			$index_reg != 4 or croak "RSP cannot be used as index register";
			$rex |= ($index_reg & 8) >> 2;
			$tail= pack('CCV', (($reg & 7) << 3) | 4, $scale | (($index_reg & 7) << 3) | 5, $disp);
		}
		else {
			# Null index register is encoded as RSP
			$tail= pack('CCV', (($reg & 7) << 3) | 4, 0x25, $disp);
		}
	}
	$tail .= pack($immed_pack, $immed)
		if defined $immed;
	
	return $rex?
		pack('CC', ($rex|0x40), $opcode) . $tail
		: pack('C', $opcode) . $tail;
}

#=head2 _append_mathopNN_const
#
#This is so bizarre I don't even know where to start.  Most "math-like" instructions have an opcode
#for an immediate the size of the register (except 64-bit which only gets a 32-bit immediate), an
#opcode for an 8-bit immediate, and another opcode specifically for the AX register which is a byte
#shorter than the normal, which is the only redeeming reason to bother using it.
#Also, there is a constant stored in the 3 bits of the unused register in the ModRM byte which acts
#as an extension of the opcode.
#
#These 4 methods are the generic implementation for encoding this mess.
#Each implementation also handles the possibility that the immediate value is an unknown variable
#resolved while the instructions are assembled.
#
#=over
#
#=item C<_append_mathop64_const($opcodeAX32, $opcode8, $opcode32, $opcode_reg, $reg, $immed)>
#
#This one is annoying because it only gets a sign-extended 32-bit value, so you actually only get
#31 bits of an immediate value for a 64-bit instruction.
#
#=cut

sub _append_mathop64_const {
	my ($self, @args)= @_; # $opcodeAX32, $opcode8, $opcode32, $opcode_reg, $reg, $immed
	$args[4]= $regnum64{$args[4]} // croak("$args[4] is not a 64-bit register");
	$self->_append_possible_unknown('_encode_mathop64_imm', \@args, 5, 7);
}
sub _encode_mathop64_imm {
	my ($self, $opcodeAX32, $opcode8, $opcode32, $opcode_reg, $reg, $value)= @_;
	use integer;
	my $rex= 0x48 | (($reg & 8)>>3);
	defined $opcode8 && (($value >> 7) == ($value >> 8))?
		pack('CCCc', $rex, $opcode8, 0xC0 | ($opcode_reg << 3) | ($reg & 7), $value)
	: (($value >> 31) == ($value >> 32))? (
		# Ops on AX get encoded as a special instruction
		$reg? pack('CCCV', $rex, $opcode32, 0xC0 | ($opcode_reg << 3) | ($reg & 7), $value)
			: pack('CCV', $rex, $opcodeAX32, $value)
	)
	# 64-bit only supports 32-bit sign-extend immediate
	: croak "$value is wider than 32-bit";
}

#=item C<_append_mathop32_const($opcodeAX32, $opcode8, $opcode32, $opcode_reg, $reg, $immed)>
#
#=cut

sub _append_mathop32_const {
	my ($self, @args)= @_; # $opcodeAX32, $opcode8, $opcode32, $opcode_reg, $reg, $immed
	$args[4]= $regnum32{$args[4]} // croak("$args[4] is not a 32-bit register");
	$self->_append_possible_unknown('_encode_mathop32_imm', \@args, 5, 7);
}
sub _encode_mathop32_imm {
	my ($self, $opcodeAX32, $opcode8, $opcode32, $opcode_reg, $reg, $value)= @_;
	use integer;
	my $rex= (($reg & 8)>>3);
	defined $opcode8 && (($value >> 7) == ($value >> 8) or ($value >> 8 == 0xFFFFFF))?
		(	$rex? pack('CCCC', 0x40|$rex, $opcode8, 0xC0 | ($opcode_reg << 3) | ($reg & 7), $value&0xFF)
				: pack('CCC', $opcode8, 0xC0 | ($opcode_reg << 3) | ($reg & 7), $value&0xFF)
		)
		: (($value >> 32) == ($value >> 33))? (
			# Ops on AX get encoded as a special instruction
			$rex? pack('CCCV', 0x40|$rex, $opcode32, 0xC0 | ($opcode_reg << 3) | ($reg & 7), $value)
			: $reg? pack('CCV', $opcode32, 0xC0 | ($opcode_reg << 3) | ($reg & 7), $value)
			: pack('CV', $opcodeAX32, $value)
		)
		: croak "$value is wider than 32-bit";
}

#=item C<_append_mathop16_const($opcodeAX16, $opcode8, $opcode16, $opcode_reg, $reg, $immed)>
#
#=cut

sub _append_mathop16_const {
	my ($self, @args)= @_; # $opcodeAX16, $opcode8, $opcode16, $opcode_reg, $reg, $immed
	$args[4]= $regnum16{$args[4]} // croak("$args[4] is not a 16-bit register");
	$self->_append_possible_unknown('_encode_mathop16_imm', \@args, 5, 8);
}
sub _encode_mathop16_imm {
	my ($self, $opcodeAX16, $opcode8, $opcode16, $opcode_reg, $reg, $value)= @_;
	use integer;
	my $rex= (($reg & 8)>>3);
	defined $opcode8 && (($value >> 7) == ($value >> 8) or ($value >> 8 == 0xFF))?
		(	$rex? pack('CCCCC', 0x66, 0x40|$rex, $opcode8, 0xC0 | ($opcode_reg << 3) | ($reg & 7), $value&0xFF)
				: pack('CCCC', 0x66, $opcode8, 0xC0 | ($opcode_reg << 3) | ($reg & 7), $value&0xFF)
		)
		: (($value >> 16) == ($value >> 17))? (
			# Ops on AX get encoded as a special instruction
			$rex? pack('CCCCv', 0x66, 0x40|$rex, $opcode16, 0xC0 | ($opcode_reg << 3) | ($reg & 7), $value&0xFFFF)
			: $reg? pack('CCCv', 0x66, $opcode16, 0xC0 | ($opcode_reg << 3) | ($reg & 7), $value&0xFFFF)
			: pack('CCv', 0x66, $opcodeAX16, $value)
		)
		: croak "$value is wider than 16-bit";
}

#=item C<_append_mathop8_const($opcodeAX8, $opcode8, $opcode_reg, $reg, $immed)>
#
#On the upside, this one only has one bit width, so the length of the instruction is known even if
#the immediate value isn't.
#
#However, we also have to handle the case where "dil", "sil", etc need a REX prefix but AH, BH, etc
#can't have one.
#
#=back
#
#=cut

sub _append_mathop8_const {
	my ($self, $opcodeAX8, $opcode8, $opcode_reg, $reg, $immed)= @_;
	use integer;
	$reg= $regnum8{$reg};
	my $value= ref $immed? 0x00 : $immed;
	(($value >> 8) == ($value >> 9)) or croak "$value is wider than 8 bits";
	if (!defined $reg) {
		$reg= $regnum8_high{$_[1]} // croak("$reg is not a 8-bit register");
		$self->{_buf} .= pack('CCC', $opcode8, 0xC0 | ($opcode_reg<<3) | ($reg & 7), $value&0xFF);
	} elsif (!$reg) {
		$self->{_buf} .= pack('CC', $opcodeAX8, $value&0xFF);
	} elsif ($reg > 3) {
		$self->{_buf} .= pack('CCCC', 0x40|(($reg & 8)>>3), $opcode8, 0xC0 | ($opcode_reg << 3) | ($reg & 7), $value&0xFF);
	} else {
		$self->{_buf} .= pack('CCC', $opcode8, 0xC0 | ($opcode_reg << 3) | ($reg & 7), $value&0xFF);
	}
	$self->_mark_unresolved(-1, encode => '_repack', bits => 8, value => $immed)
		if ref $immed;
	$self;
}

sub _append_mathop64_const_to_mem {
	my ($self, $opcode8, $opcode32, $opcode_reg, $value, $mem)= @_;
	my ($base_reg, $disp, $index_reg, $scale)= @$mem;
	$base_reg= ($regnum64{$base_reg} // croak "$base_reg is not a 64-bit register")
		if defined $base_reg;
	$index_reg= ($regnum64{$index_reg} // croak "$index_reg is not a 64-bit register")
		if defined $index_reg;
	$self->_append_possible_unknown('_encode_mathop64_mem_immed', [ $opcode8, $opcode32, $opcode_reg, $value, $base_reg, $disp, $index_reg, $scale ], 3, defined $disp? 9:12);
}
sub _encode_mathop64_mem_immed {
	my ($self, $opcode8, $opcode32, $opcode_reg, $value, $base_reg, $disp, $index_reg, $scale)= @_;
	use integer;
	defined $opcode8 && (($value >> 7) == ($value >> 8))?
		$self->_encode_op_reg_mem(8, $opcode8, $opcode_reg, $base_reg, $disp, $index_reg, $scale, 'C', $value&0xFF)
	: (($value >> 31) == ($value >> 32))?
		$self->_encode_op_reg_mem(8, $opcode32, $opcode_reg, $base_reg, $disp, $index_reg, $scale, 'V', $value&0xFFFFFFFF)
	: croak "$value is wider than 31-bit";
}

sub _append_mathop32_const_to_mem {
	my ($self, $opcode8, $opcode32, $opcode_reg, $value, $mem)= @_;
	my ($base_reg, $disp, $index_reg, $scale)= @$mem;
	$base_reg= ($regnum64{$base_reg} // croak "$base_reg is not a 64-bit register")
		if defined $base_reg;
	$index_reg= ($regnum64{$index_reg} // croak "$index_reg is not a 64-bit register")
		if defined $index_reg;
	$self->_append_possible_unknown('_encode_mathop32_mem_immed', [ $opcode8, $opcode32, $opcode_reg, $value, $base_reg, $disp, $index_reg, $scale ], 3, defined $disp? 12:8);
}
sub _encode_mathop32_mem_immed {
	my ($self, $opcode8, $opcode32, $opcode_reg, $value, $base_reg, $disp, $index_reg, $scale)= @_;
	use integer;
	defined $opcode8 && (($value >> 7) == ($value >> 8) or ($value >> 8 == 0xFFFFFF))?
		$self->_encode_op_reg_mem(0, $opcode8, $opcode_reg, $base_reg, $disp, $index_reg, $scale).pack('C',$value&0xFF)
	: (($value >> 32) == ($value >> 33))?
		$self->_encode_op_reg_mem(0, $opcode32, $opcode_reg, $base_reg, $disp, $index_reg, $scale).pack('V', $value&0xFFFFFFFF)
	: croak "$value is wider than 32-bit";
}

sub _append_mathop16_const_to_mem {
	my ($self, $opcode8, $opcode16, $opcode_reg, $value, $mem)= @_;
	my ($base_reg, $disp, $index_reg, $scale)= @$mem;
	$base_reg= ($regnum64{$base_reg} // croak "$base_reg is not a 64-bit register")
		if defined $base_reg;
	$index_reg= ($regnum64{$index_reg} // croak "$index_reg is not a 64-bit register")
		if defined $index_reg;
	$self->{_buf} .= "\x66";
	$self->_append_possible_unknown('_encode_mathop16_mem_immed', [ $opcode8, $opcode16, $opcode_reg, $value, $base_reg, $disp, $index_reg, $scale ], 3, defined $disp? 10:6);
}
sub _encode_mathop16_mem_immed {
	my ($self, $opcode8, $opcode16, $opcode_reg, $value, $base_reg, $disp, $index_reg, $scale)= @_;
	use integer;
	defined $opcode8 && (($value >> 7) == ($value >> 8) or ($value >> 8 == 0xFF))?
		$self->_encode_op_reg_mem(0, $opcode8, $opcode_reg, $base_reg, $disp, $index_reg, $scale).pack('C',$value&0xFF)
	: (($value >> 16) == ($value >> 17))?
		$self->_encode_op_reg_mem(0, $opcode16, $opcode_reg, $base_reg, $disp, $index_reg, $scale).pack('v', $value&0xFFFF)
	: croak "$value is wider than 16-bit";
}

sub _append_mathop8_const_to_mem {
	my ($self, $opcode8, $opcode_reg, $value, $mem)= @_;
	my ($base_reg, $disp, $index_reg, $scale)= @$mem;
	$base_reg= ($regnum64{$base_reg} // croak "$base_reg is not a 64-bit register")
		if defined $base_reg;
	$index_reg= ($regnum64{$index_reg} // croak "$index_reg is not a 64-bit register")
		if defined $index_reg;
	$self->_append_possible_unknown('_encode_mathop8_mem_immed', [ $opcode8, $opcode_reg, $value, $base_reg, $disp, $index_reg, $scale ], 2, defined $disp? 10:6);
}
sub _encode_mathop8_mem_immed {
	my ($self, $opcode8, $opcode_reg, $value, $base_reg, $disp, $index_reg, $scale)= @_;
	use integer;
	(($value >> 8) == ($value >> 9)) or croak "$value is wider than 8 bit";
	$self->_encode_op_reg_mem(0, $opcode8, $opcode_reg, $base_reg, $disp, $index_reg, $scale).pack('C',$value&0xFF);
}

#=head2 C<_append_shiftop_reg_imm( $bitwidth, $opcode_1, $opcode_imm, $opreg, $reg, $immed )>
#
#Shift instructions often have a special case for shifting by 1.  This utility method
#selects that opcode if the immediate value is 1.
#
#It also allows the immediate to be an expression, though I doubt that will ever happen...
#Immediate values are always a single byte, and the processor masks them to 0..63
#so the upper bits are irrelevant.
#
#=cut

sub _append_shiftop_reg_imm {
	my ($self, $bits, $opcode_sh1, $opcode_imm, $opreg, $reg, $immed)= @_;
	
	# Select appropriate opcode
	my $op= $immed eq 1? $opcode_sh1 : $opcode_imm;
	
	$bits == 64?   $self->_append_op64_reg_reg($op, $opreg, $reg)
	: $bits == 32? $self->_append_op32_reg_reg($op, $opreg, $reg)
	: $bits == 16? $self->_append_op16_reg_reg($op, $opreg, $reg)
	:              $self->_append_op8_opreg_reg($op, $opreg, $reg);
	
	# If not using the shift-one opcode, append an immediate byte.
	unless ($immed eq 1) {
		$self->{_buf} .= pack('C', ref $immed? 0 : $immed);
		$self->_mark_unresolved(-1, encode => '_repack', bits => 8, value => $immed)
			if ref $immed;
	}
	
	$self;
}

#=head2 _append_shiftop_mem_imm
#
#Same as above, for memory locations
#
#=cut

sub _append_shiftop_mem_imm {
	my ($self, $bits, $opcode_sh1, $opcode_imm, $opreg, $mem, $immed)= @_;

	# Select appropriate opcode
	my $op= $immed eq 1? $opcode_sh1 : $opcode_imm;
	
	$bits == 64?   $self->_append_op64_reg_mem(8, $op, $opreg, $mem)
	: $bits == 32? $self->_append_op32_reg_mem(0, $op, $opreg, $mem)
	: $bits == 16? $self->_append_op16_reg_mem(0, $op, $opreg, $mem)
	:              $self->_append_op8_opreg_mem(0, $op, $opreg, $mem);
	
	# If not using the shift-one opcode, append an immediate byte.
	unless ($immed eq 1) {
		$self->{_buf} .= pack('C', ref $immed? 0 : $immed);
		$self->_mark_unresolved(-1, encode => '_repack', bits => 8, value => $immed)
			if ref $immed;
	}
	
	$self;
}

#=head2 C<_append_jmp_cond($cond_code, $label)>
#
#Appends a conditional jump instruction, which is either the short 2-byte form for 8-bit offsets,
#or 6 bytes for jumps of 32-bit offsets.  The implementation optimistically assumes the 2-byte
#length until L<resolve> is called, when the actual length will be determined.
#
#Returns $self, for chaining.
#
#=cut

sub _append_jmp_cond {
	$_[2]= $_[0]->get_label unless defined $_[2];
	
	my ($self, $cond, $label)= @_;
	use integer;
	$label= $self->get_label($label)
		unless ref $label;
	$self->_mark_unresolved(
		2, # estimated length
		encode => sub {
			my ($self, $params)= @_;
			defined $label->{offset} or croak "Label $label is not marked";
			my $ofs= $label->{offset} - ($params->{offset}+$params->{len});
			my $short= (($ofs>>7) == ($ofs>>8));
			return $short?
				pack('Cc', 0x70 + $cond, $ofs)
				: pack('CCV', 0x0F, 0x80 + $cond, $ofs);
		}
	);
	$self;
}

#=head2 C<_append_jmp_cx($opcode, $label)>
#
#Appends one of the special CX-related jumps (like L</loop>).  These can only have an 8-bit offset
#and are fixed-length.
#
#=cut

sub _append_jmp_cx {
	my ($self, $op, $label)= @_;
	use integer;
	$label= $self->get_label($label)
		unless ref $label;
	$self->_mark_unresolved(
		2, # estimated length
		encode => sub {
			my ($self, $params)= @_;
			defined $label->{offset} or croak "Label $label is not marked";
			my $ofs= $label->{offset} - ($params->{offset}+$params->{len});
			(($ofs>>7) == ($ofs>>8)) or croak "Label too far, can only short-jump";
			return pack('Cc', $op, $ofs);
		}
	);
	return $self;
}

sub _append_possible_unknown {
	my ($self, $encoder, $encoder_args, $unknown_pos, $estimated_length)= @_;
	my $u= $encoder_args->[$unknown_pos];
	if (ref $u && ref $u ne 'SCALAR') {
		ref($u)->can('value')
			or croak "Expected object with '->value' method";
		$self->_mark_unresolved(
			$estimated_length,
			encode => sub {
				my $self= shift;
				my @args= @$encoder_args;
				$args[$unknown_pos]= $u->value
					// croak "Value '$u->{name}' is still unresolved";
				$self->$encoder(@args);
			},
		);
	}
	else {
		$self->{_buf} .= $self->$encoder(@$encoder_args);
	}
	$self;
}

#=head2 C<_mark_unresolved($location, encode => sub {...}, %other)>
#
#Creates a new unresolved marker in the instruction stream, indicating things which can't be known
#until the entire instruction stream is written. (such as jump instructions).
#
#The parameters 'offset' and 'len' will be filled in automatically based on the $location parameter.
#If C<$location> is negative, it indicates offset is that many bytes backward from the end of the
#buffer.  If C<$location> is positive, it means the unresolved symbol hasn't been written yet and
#the 'offset' will be the current end of the buffer and 'len' is the value of $location.
#
#The other usual (but not required) parameter is 'encode'.  This references a method callback which
#will return the encoded instruction (or die, if there is still not enough information to do so).
#
#All C<%other> parameters are passed to the callback as a HASHREF.
#
#=cut

sub _mark_unresolved {
	my ($self, $location)= (shift, shift);
	my $offset= length($self->{_buf});
	
	# If location is negative, move the 'offset' back that many bytes.
	# The length is the abs of location.
	if ($location < 0) {
		$location= -$location;
		$offset -= $location;
	}
	# If the location is positive, offset is the end of the string.
	# Add padding bytes for the length of the instruction.
	else {
		$self->{_buf} .= "\0" x $location;
	}
	
	if ($self->{debug}) {
		my ($i, @caller);
		# Walk up stack until the entry-point method
		while (@caller= caller(++$i)) {
			last if $caller[0] ne __PACKAGE__;
		}
		push @_, caller => \@caller;
	}
	#print "Unresolved at $offset ($location)\n";
	push @{ $self->_unresolved }, { offset => $offset, len => $location, @_ };
}

sub _repack {
	my ($self, $params)= @_;
	use integer;
	my $v= $params->{value}->value;
	defined $v or croak "Placeholder $params->{value} has not been assigned";
	my $bits= $params->{bits};
	my $pack= $bits <= 8? 'C' : $bits <= 16? 'v' : $bits <= 32? 'V' : $bits <= 64? 'Q<' : die "Unhandled bits $bits\n";
	$bits == 64 || (($v >> $bits) == ($v >> ($bits+1))) or croak "$v is wider than $bits bits";
	return pack($pack, $v & ~(~0 << $bits));
}

#=head2 C<_resovle>
#
#This is the algorithm that resolves the unresolved instructions.  It takes an iterative approach
#that is relatively efficient as long as the predicted lengths of the unresolved instructions are
#correct.  If many instructions guess the wrong length then this could get slow for very long
#instruction strings.
#
#=cut

sub _resolve {
	my $self= shift;
	
	# We repeat the process any time something changed length
	my $changed_len= 1;
	while ($changed_len) {
		$changed_len= 0;
		
		# Track the amount we have shifted the current instruction in $ofs
		my $ofs= 0;
		for my $p (@{ $self->_unresolved }) {
			#print "Shifting $p by $ofs\n" if $ofs;
			$p->{offset} += $ofs if $ofs;
			
			# Ignore things without an 'encode' callback (like labels)
			my $fn= $p->{encode}
				or next;
			
			# Get new encoding, then replace those bytes in the instruction string
			eval {
				my $enc= $self->$fn($p);
				substr($self->{_buf}, $p->{offset}, $p->{len})= $enc;
				
				# If the length changed, update $ofs and current ->len
				if (length($enc) != $p->{len}) {
					#print "New size is ".length($enc)."\n";
					$changed_len= 1;
					$ofs += (length($enc) - $p->{len});
					$p->{len}= length($enc);
				}
			};
			if ($@) {
				if ($p->{caller}) {
					croak "Failed to encode instruction $p->{caller}[3] from $p->{caller}[1] line $p->{caller}[2]:\n   $@";
				} else {
					croak "Failed to encode instruction (enable diagnostics with ->debug(1) ): $@";
				}
			}
		}
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPU::x86_64::InstructionWriter - Assemble x86-64 instructions using a pure-perl API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # POSIX::exit(42);
  my $machine_code= CPU::x86_64::InstructionWriter->new
    ->mov( 'RAX', 60 )
    ->mov( 'RDI', 42 )
    ->syscall()
    ->bytes;

  # if (x == 1) { ++x } else { ++y }
  my $machine_code= CPU::x86_64::InstructionWriter->new
    ->cmp( 'RAX', 1 )
    ->jne('else')        # jump to not-yet-defined label named 'else'
    ->inc( 'RAX' )
    ->jmp('end')         # jump to another not-yet-defined label
    ->label('else')      # resolve previous jump to this address
    ->inc( 'RCX' )
    ->label('end')       # resolve second jump to this address
    ->bytes;

=head1 DESCRIPTION

B<This module is an early stage of development and the API is not finalized>.

The purpose of this module is to relatively efficiently assemble instructions for the x86-64
without generating and re-parsing assembly language, or shelling out to an external tool.
All instructions are assumed to be for the 64-bit mode of the processor.  Functionality for
real mode or segmented 16-bit mode could be added by a yet-to-be-written ::x86 module.

This module consists of a bunch of chainable methods which build a string of machine code as
you call them.  It supports lazy-resolved jump labels, and lazy-bound constants which can be
assigned a value after the instructions have been assembled.

B<Note:> This module currently requires a perl with 64-bit integers and C<pack('Q')> support.

=head1 NOTATIONS

The method names of this class loosely match the NASM notation, but with the addition of the
number of data bits following the opcode name, and list of arguments.

    MOV EAX, [EBX]
    
    $w->mov32_reg_mem('eax', ['ebx']);
    
    # or, short form
	use CPU::X86_64::InstructionWriter ':registers';
    $w->mov(eax,[ebx]);

Using a specific method like 'mov32_reg_mem' runs faster than the generic method 'mov', and
removes ambiguity since your code generator probably already knows what operation it wants.
Also it removes the need for the "qword" attributes that NASM sometimes needs.  However, if you
want you can use the generic method for an op.

There are often entirely new names given to an opcode (for the somewhat obscure ones) but the
official Intel/AMD name is provided as an alias.

   CMP EAX EBX
   JNO label           ; quick, what does JNO mean?

   $w->cmp32_reg_reg('eax','ebx')->jmp_unless_overflow($label);
   # or:
   $w->cmp(eax,ebx)->jno("mylabel");

=head1 MEMORY LOCATIONS

Most instructions in the x86 set allow for one argument to be a memory location, composed of

=over

=item A B<base> register

=item plus a constant B<displacement> (usually limited to 32-bit)

=item plus an B<index> register times a B<scale> of 1, 2, 4, or 8

=back

    [ $base, $displacement, $index, $scale ]

Leave a slot in the array C<undef> to skip it.  (but obviously one of them must be set)
You may also allocate a smaller array to imply the remeaining items are undef.

Examples:

    ['rdx']                       # address RDX
    ['rbx', -20000]               # address RBX-20000
    [undef, 0x7FFFFFFF]           # address 0x7FFFFFFF
    [undef, undef, 'ecx', 8]      # address ECX*8

NASM supports scales like [EAX*5] by silently converting that to [EAX+EAX*4], but this module
does not support that via the B<scale> field.  (it would just slow things down for a feature
nobody uses)

=head1 ATTRIBUTES

=head2 start_address

You might or might not need to set this.  Some instructions care about what address they live
at for things like RIP-relative addressing.  The default value is an object of class "unknown".
Things that depend on it will also be represented by "unknown" until the start_address has been
given a value.  If you try to resolve them numerically before start_address is set, you get an
exception.

=head2 labels

This is a set of all labels currently relevant to this writer, indexed by name (so names must
be unique).   You probably don't need to access this.  See L</get_label> and L</mark>.

=head1 METHODS

=head2 get_label

  my $label= $writer->get_label($name); # label-by-name, created on demand
  my $label= $writer->get_label();      # new anonymous label

Return a label object for the given name, or if no name is given, return an anonymous label.

The label objects returned can be assigned a location within the instruction stream using L</mark>
and used as the target for C<JMP> and C<JMP>-like instructions.  A label can also be used as a
constant once all variable-length instructions have been L</resolve>d and once L</start_address>
is defined.

=head2 label

  ->label($label_ref)     # bind label object to current position
  ->label(my $new_label)  # like above, but create anonymous label object and assign to $new_label
  ->label($label_name)    # like above, but create/lookup label object by name

Bind a named label to the current position in the instruction buffer.  You can also pass a label
reference from L</get_label>, or an undef variable which will be assigned a label.

If the current position follows instructions of unknown length, the label will be processed as an
unknown, and shift automatically as the instructions are resolved.

=head2 bytes

Return the assembled instructions as a string of bytes.  This will fail if any of the labels were
left un-marked or if any expressions can't be evaluated.

=head1 DATA DECLARATION

This class assembles instructions, but sometimes you want to mix in data, and label the data.
These methods append data, optionally aligned.

=head2 data

Append a string of literal bytes to the instruction stream.

=head2 data_i8, data_i16, data_i32, data_i64

Pack an integer into some number of bits and append it.

=head2 data_f32, data_f64

Pack a floating point number into the given bit-length (float or double) and append it.

=head2 align, align16, align32, align64, align128

Append zero or more bytes so that the next instruction is aligned in memory.
By default, the fill-byte will be a NO-OP (0x90).  You can override it with your choice.

=head1 INSTRUCTIONS

The following methods append an instruction to the buffer, and return C<$self> so you can continue
calling instructions in a chain.

=head2 NOP, PAUSE

Insert one or more no-op instructions.

=over

=item nop(), C<nop( $n )>

If called without an argument, insert one no-op.  Else insert C<$n> no-ops.

=item pause(), C<pause( $n )>

Like NOP, but hints to the processor that the program is in a spin-loop so it
has the opportunity to reduce power consumption.  This is a 2-byte instruction.

=back

=head2 CALL

=over

=item C<call_label( $label )>

Call to subroutine at named label, relative to current RIP.
This method takes a label and calculates a C<call_rel( $ofs )> for you.

=item C<call_rel( $offset )>

Call to subroutine at signed 32-bit offset from current RIP.

=item C<call_abs_reg( $reg )>

Call to subroutine at absolute address stored in 64-bit register.

=item C<call_abs_mem( \@mem )>

Call to subroutine at absolute address stored at L</memory location>

=back

=head2 RET

  ->ret
  ->ret($pop_bytes) # 16-bit number of bytes to discard from stack

=head2 JMP

All jump instructions are relative, and take either a numeric offset (from the start of the next
instruction) or a label, except the C<jmp_abs_reg> instruction which takes a register containing the
target address, and the C<jmp_abs_mem> which reads a memory address for the address to jump to.

If you pass an undefined variable as a label it will be auto-populated with a label object.
Otherwise the label should be a string (label name) or label object obtained from L</get_label>.

=over

=item C<jmp($label)>

Unconditional jump to label (or 32-bit offset constant).

=item C<jmp_abs_reg($reg)>

Jump to the absolute address contained in a register.

=item C<jmp_abs_mem(\@mem)>

Jump to the absolute address read from a L</memory location>

=item C<jmp_if_eq>, C<je>, C<jz>

=item C<jmp_if_ne>, C<jne>, C<jnz>

Jump to label if zero flag is/isn't set after CMP instruction

=item C<jmp_if_unsigned_lt>, C<jb>, C<jmp_if_carry>, C<jc>

=item C<jmp_if_unsigned_gt>, C<ja>

=item C<jmp_if_unsigned_le>, C<jbe>

=item C<jmp_if_unsigned_ge>, C<jae>, C<jmp_unless_carry>, C<jnc>

Jump to label if unsigned less-than / greater-than / less-or-equal / greater-or-equal

=item C<jmp_if_signed_lt>, C<jl>

=item C<jmp_if_signed_gt>, C<jg>

=item C<jmp_if_signed_le>, C<jle>

=item C<jmp_if_signed_ge>, C<jge>

Jump to label if signed less-than / greater-than / less-or-equal / greater-or-equal

=item C<jmp_if_sign>, C<js>

=item C<jmp_unless_sign>, C<jns>

Jump to label if 'sign' flag is/isn't set after CMP instruction

=item C<jmp_if_overflow>, C<jo>

=item C<jmp_unless_overflow>, C<jno>

Jump to label if overflow flag is/isn't set after CMP instruction

=item C<jmp_if_parity_even>, C<jpe>, C<jp>

=item C<jmp_if_parity_odd>, C<jpo>, C<jnp>

Jump to label if 'parity' flag is/isn't set after CMP instruction

=item C<jmp_cx_zero>, C<jrcxz>

Short-jump to label if RCX register is zero

=item C<loop>

Decrement RCX and short-jump to label if RCX register is nonzero
(decrement of RCX does not change rFLAGS)

=item C<loopz>, C<loope>

Decrement RCX and short-jump to label if RCX register is nonzero and zero flag (ZF) is set.
(decrement of RCX does not change rFLAGS)

=item C<loopnz>, C<loopne>

Decrement RCX and short-jump to label if RCX register is nonzero and zero flag (ZF) is not set
(decrement of RCX does not change rFLAGS)

=back

=head2 MOV

=over

=item C<mov($dest, $src, $bits)>

Generic top-level instruction method that dispatches to more specific versions of mov based on
the arguments you gave it.  The third argument is optional if one of the other arguments is a
register.

=item C<mov64_reg_reg($dest_reg, $src_reg)>

Copy second register to first register.  Copies full 64-bit value.

=item C<mov##_mem_reg($mem, $reg)>

Store ##-bit value in register to a L</memory location>.  If the memory location
consists of a single displacement greater than 32 bits, the register must be the
appropriate size accumulator (RAX, EAX, AX, or AL)

=item C<mov##_reg_mem($reg, $mem)>

Load ##-bit value at L</memory location> into register.  The Displacement portion
of the memory location must normally be 32-bit, but as a special case you can load
a full 64-bit displacement (with no register offset) into the Accumulator register
of that size (RAX, EAX, AX, or AL).

   $asm->mov8_reg_mem ( 'al', [ undef, 0xFF00FF00FF00FF00FF00 ]);
   $asm->mov64_reg_mem('rax', [ undef, 0xFF00FF00FF00FF00FF00 ]);

=item C<mov64_reg_imm($dest_reg, $constant)>

Load a constant value into a 64-bit register.  Constant is sign-extended to 64-bits.
Constant may be an expression.

=item C<mov##_mem_imm($mem, $constant)>

Store a constant value into a ##-bit memory location.
For mov64, constant is 32-bit sign-extended to 64-bits.
Constant may be an expression.

=back

=head2 CMOV

TODO...

=head2 LEA

=over

=item C<lea($reg, $src, $bits)>

Dispatch to a variant of LEA based on argument types.

=item C<lea16_reg_mem($reg16, \@mem)>
=item C<lea32_reg_mem($reg32, \@mem)>
=item C<lea64_reg_mem($reg64, \@mem)>
=item C<lea16_reg_reg($reg16, $reg64)>
=item C<lea32_reg_reg($reg32, $reg64)>
=item C<lea64_reg_reg($reg64, $reg64)>

=back

Load the address of the 64-bit value stored at L<memory location>.
It is essentially a shorthand for two memory load operations where the first
is loading a pointer and the second is loading the value it points to.

=head2 ADD, ADC

The add## variants are the plain ADD instruction, for each bit width.
The addcarry## variants are the ADC instruction that also adds the carry flag, useful for
multi-word addition.

=over

=item C<add($dst, $src, $bits)>

=item C<add##_reg_reg($dest, $src)>

=item C<add##_reg_mem($reg, \@mem)>

=item C<add##_mem_reg(\@mem, $reg)>

=item C<add##_reg_imm($reg, $const)>

=item C<add##_mem_imm(\@mem, $const)>

Returns $self, for chaining.

=item C<addcarry($dst, $src, $bits), adc($dst, $src, $bits)>

=item C<addcarry##_reg(reg64, reg64)>

=item C<addcarry##_mem(reg64, base_reg64, displacement, index_reg64, scale)>

=item C<addcarry##_to_mem(reg64, base_reg64, displacement, index_reg64, scale)>

=item C<addcarry##_const(reg64, const)>

=item C<addcarry##_const_to_mem(const, base_reg64, displacement, index_reg64, scale)>

=back

Returns $self, for chaining.

=head2 sub

=over

=item C<add##_reg_imm($reg, $const)>

=back

=head2 AND

=over

=item C<and($dst, $src, $bits)>

=item C<and##_reg_reg($dest, $src)>

=item C<and##_reg_mem($reg, \@mem)>

=item C<and##_mem_reg(\@mem, $reg)>

=item C<and##_reg_imm($reg, $const)>

=item C<and##_mem_imm(\@mem, $const)>

=back

=head2 OR

=over

=item C<or($dst, $src, $bits)>

=item C<or##_reg(reg64, reg64)>

=item C<or##_mem(reg64, base_reg64, displacement, index_reg64, scale)>

=item C<or##_to_mem(reg64, base_reg64, displacement, index_reg64, scale)>

=item C<or##_const(reg64, const)>

=item C<or##_const_to_mem(const, base_reg64, displacement, index_reg64, scale)>

=back

=head2 XOR

=over

=item C<xor($dst, $src, $bits)>

=item C<xor##_reg(reg64, reg64)>

=item C<xor##_mem(reg64, base_reg64, displacement, index_reg64, scale)>

=item C<xor##_to_mem(reg64, base_reg64, displacement, index_reg64, scale)>

=item C<xor##_const(reg64, const)>

=item C<xor##_const_to_mem(const, base_reg64, displacement, index_reg64, scale)>

=back

=head2 SHL

Shift left by a constant or the CL register.  The shift is at most 63 bits for
64-bit register, or 31 bits otherwise.

=over

=item C<shl($dst, $src, $bits)>

=item C<shl##_reg_imm( $reg, $const )>

=item C<shl##_mem_imm( \@mem, $const )>

=item C<shl##_reg_cl( $reg )>

=item C<shl##_mem_cl( \@mem )>

=back

=head2 SHR

Shift right by a constant or the CL register.  The shift is at most 63 bits for
64-bit register, or 31 bits otherwise.

=over

=item C<shr($dst, $src, $bits)>

=item C<shr##_reg_imm( $reg, $const )>

=item C<shr##_mem_imm( \@mem, $const )>

=item C<shr##_reg_cl( $reg, 'cl' // undef )>

=item C<shr##_mem_cl( \@mem, 'cl' // undef )>

=back

=head2 SAR

Shift "arithmetic" right by a constant or the CL register, and sign-extend
the left-most bits.
The shift is at most 63 bits for 64-bit register, or 31 bits otherwise.

=over

=item C<sar($dst, $src, $bits)>

=item C<sar##_reg_imm( $reg, $const )>

=item C<sar##_mem_imm( \@mem, $const )>

=item C<sar##_reg_cl( $reg, 'cl' // undef )>

=item C<sar##_mem_cl( \@mem, 'cl' // undef )>

=back

=head2 BSWAP

Swap byte order on 32 or 64 bits.

=over

=item bswap64

=item bswap32

=item bswap16

(This is actually the XCHG instruction)

=back

=head2 CMP

Like SUB, but don't modify any arguments, just update RFLAGS.

=over

=item C<cmp($dst, $src, $bits)>

=item C<cmp##_reg_reg($dest, $src)>

=item C<cmp##_reg_mem($reg, \@mem)>

Subtract mem (second args) from reg (first arg)

=item cmp##_mem_reg(\@mem, $reg);

Subtract reg (first arg) from mem (second args)

=item cmp##_reg_imm($reg, $const)

Subtract const from reg

=item cmp##_mem_imm(\@mem, $const)

Subtract const from contents of mem address

=back

=head2 TEST

Like AND, but don't modify any arguments, just update flags.
Note that order of arguments does not matter, and there is no "to_mem" variant.

=over

=item C<test($dst, $src, $bits)>

=item C<test##_reg_reg($dest, $src)>

=item C<test##_reg_mem($reg, \@mem)>

=item C<test##_reg_imm($reg, $const)>

=item C<test##_mem_imm(\@mem, $const)>

=back

=head2 DEC

=over

=item C<dec($operand, $bits)>

=item C<dec##_reg($reg)>

=item C<dec##_mem(\@mem)>

=back

=head2 INC

=over

=item C<inc($operand, $bits)>

=item C<inc##_reg($reg)>

=item C<inc##_mem(\@mem)>

=back

=head2 NOT

Flip all bits in a target register or memory location.

=over

=item C<notNN_reg($reg)>

=item C<notNN_mem(\@mem)>

=back

=head2 NEG

Replace target register or memory location with signed negation (2's complement).

=over

=item C<neg##_reg($reg)>

=item C<neg##_mem(\@mem)>

=back

=head2 DIV, IDIV

=over

=item C<div##_reg($reg)>

Unsigned divide of _DX:_AX by a NN-bit register.  (divides AX into AL,AH for 8-bit) 

=item C<div##_mem(\@mem)>

Unsigned divide of _DX:_AX by a NN-bit memory value referenced by 64-bit registers

=item C<div##_reg($reg)>

Signed divide of _DX:_AX by a NN-bit register.  (divides AX into AL,AH for 8-bit)

=item C<div##_mem(\@mem)>

Signed divide of _DX:_AX by a NN-bit memory value referenced by 64-bit registers

=back

=head2 MUL

=over

=item mul64_dxax_reg

=item mul32_dxax_reg

=item mul16_dxax_reg

=item mul8_ax_reg

=back

=head2 sign extend

Various special-purpose sign extension instructions, mostly used to set up for DIV

=over

=item sign_extend_al_ax, cbw

=item sign_extend_ax_eax, cwde

=item sign_extend_eax_rax, cdqe

=item sign_extend_ax_dx, cwd

=item sign_extend_eax_edx, cdq

=item sign_extend_rax_rdx, cqo

=back

=head2 flag modifiers

Each flag modifier takes an argument of 0 (clear), 1 (set), or -1 (invert).

=over

=item flag_carry($state), clc, cmc, stc

=back

=head2 PUSH

This only implements the 64-bit push instruction.

=over

=item C<push($operand, $bits)>

=item C<push64_reg>

=item C<push64_imm>

=item C<push64_mem>

=back

=head2 POP

=over

=item C<pop($operand, $bits)>

=item C<pop_reg>

=item C<pop_mem>

=back

=head2 ENTER

  ->enter( $bytes_for_vars, $nesting_level )

bytes_for_vars is an unsigned 16-bit, and nesting_level is a value 0..31
(byte masked to 5 bits)

Both constants may be expressions.

=head2 LEAVE

Un-do an ENTER instruction.

=head2 syscall

Syscall instruction, takes no arguments.  (params are stored in pre-defined registers)

=head1 STRING INSTRUCTIONS

  ->xor('RAX','RAX')      # Compare to 0
  ->mov('RCX', 42)        # Count
  ->mov('RDI', \@memaddr) # String
  ->std                   # Iterate to increasing address
  ->repne->scas8;         # Iterate until [RDI] == "\0" or 42 bytes

=head2 rep

Repeat RCX times (used with L</ins>, L</lods>, L</movs>, L</outs>, L</stos>)

=head2 repe, repz

Repeat RCX times or until zero-flag becomes zero.  (used with L</cmps>, L</scas>)

=head2 repne, repnz

Repeat RCX times or until zero-flag becomes one. (used with L</cmps>, L</scas>)

=head2 flag_direction($bool_set)

Set (1) or clear (0) the direction flag.

=head2 std

Set the direction flag (iterate to higher address)

=head2 cld

Clear the direction flag (iterate to lower address)

=head2 movsNN

=over

=item movs64, movsq

=item movs32, movsd

=item movs16, movsw

=item movs8, movsb

=back

=head2 cmpsNN

=over

=item cmps64, cmpsq

=item cmps32, cmpsd

=item cmps16, cmpsw

=item cmps8, cmpsb

=back

=head2 scasNN

=over

=item scas64, scasq

=item scas32, scasd

=item scas16, scasw

=item scas8, scasb

=back

=head1 SYNCHRONIZATION INSTRUCTIONS

These special-purpose instructions relate to strict ordering of memory operations, cache flushing,
or atomic operations useful for implementing semaphores.

=head2 compare_exchangeNN, cmpxchg

=over

=item compare_exchange64

=item compare_exchange32

=item compare_exchange16

=item compare_exchange8

=back

TODO

=head2 mfence, lfence, sfence

Parameterless instructions for memory access serialization.
Forces memory operations before the fence to compete before memory operations after the fence.
Lfence affects load operations, sfence affects store operations, and mfence affects both.

=head1 ENCODING x86_64 INSTRUCTIONS

The AMD64 Architecture Programmer's Manual is a somewhat tedious read, so here are my notes:

Typical 2-arg 64-bit instruction:
	REX ( AddrSize ) Opcode ModRM ( ScaleIndexBase ( Disp ) ) ( Immed )

	REX: use extended registers and/or 64-bit operand sizes.
		Not used for simple push/pop or handful of others
	REX = 0x40 + (W:1bit R:1bit X:1bit B:1bit)
		REX.W = "wide" (64-bit operand size when set)
		REX.R is 4th bit of ModRM.Reg
		REX.X is 4th bit of SIB.Index
		REX.B is 4th bit of ModRM.R/M or of SIB.Base or of ModRM.Reg depending on goofy rules
  
	ModRM: mode/registers flags
	ModRM = (Mod:2bit Reg:3bit R/M:3bit)
		ModRM.Mod indicates operands:
			11b means ( Reg, R/M-reg-value )
			00b means ( Reg, R/M-reg-addr ) unless second reg is SP/BP/R12/R13
			01b means ( Reg, R/M-reg-addr + 8-bit disp ) unless second reg is SP/R12
			10b means ( Reg, R/M-reg-addr + 32-bit disp ) unless second reg is SP/R12
			
			When accessing mem, R/M=100b means include the SIB byte for exotic addressing options
			In the 00b case, R/M=101b means use instruction pointer + 32-bit immed

	SIB: optional byte for wild and crazy memory addressing; activate with ModRM.R/M = 0100b
	SIB = (Scale:2bit Index:3bit Base:3bit)
		address is (index_register << scale) + base_register (+immed per the ModRM.Mod bits)
		* unless index_register = 0100b then no register is used.
			(i.e. RSP cannot be used as an index register )
		* unless base_register = _101b and ModRM.mod = 00 then no register is used.
			(i.e. [R{BP,13} + R?? * 2] must be written as [R{BP,13} + R?? * 2 + 0]

The methods that perform the encoding are not public, but are documented in the source for
anyone who wants to extend this module to handle additional instructions.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
