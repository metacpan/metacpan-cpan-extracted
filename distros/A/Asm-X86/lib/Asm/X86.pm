#!perl
# Asm::X86 - List of instructions and registers of x86-compatible processors,
#   validating and converting instructions and memory references.
#
#	Copyright (C) 2008-2024 Bogdan 'bogdro' Drozdowski,
#	  bogdro (at) users . sourceforge . net
#	  bogdro /at\ cpan . org
#
# This file is part of Project Asmosis, a set of tools related to assembly
#  language programming.
# Project Asmosis homepage: https://asmosis.sourceforge.io/
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#

package Asm::X86;

use warnings;
require Exporter;

@ISA = (Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(
	@regs8_intel @regs16_intel @segregs_intel @regs32_intel @regs64_intel @regs_mm_intel
	@regs_intel @regs_fpu_intel @regs_opmask_intel @regs_bound_intel
	@regs8_att @regs16_att @segregs_att @regs32_att @regs64_att @regs_mm_att
	@regs_att @regs_fpu_att @regs_opmask_att @regs_bound_att

	@instr_intel @instr_att @instr

	is_reg_intel is_reg8_intel is_reg16_intel is_reg32_intel
		is_reg64_intel is_reg_mm_intel is_segreg_intel is_reg_fpu_intel
		is_reg_opmask_intel is_reg_bound_intel
	is_reg_att is_reg8_att is_reg16_att is_reg32_att
		is_reg64_att is_reg_mm_att is_segreg_att is_reg_fpu_att
		is_reg_opmask_att is_reg_bound_att
	is_reg is_reg8 is_reg16 is_reg32 is_reg64 is_reg_mm is_segreg is_reg_fpu
		is_reg_opmask is_reg_bound

	is_instr_intel is_instr_att is_instr

	is_valid_16bit_addr_intel is_valid_32bit_addr_intel is_valid_64bit_addr_intel is_valid_addr_intel
	is_valid_16bit_addr_att is_valid_32bit_addr_att is_valid_64bit_addr_att is_valid_addr_att
	is_valid_16bit_addr is_valid_32bit_addr is_valid_64bit_addr is_valid_addr

	conv_att_addr_to_intel conv_intel_addr_to_att
	conv_att_instr_to_intel conv_intel_instr_to_att

	is_addressable32_intel is_addressable32_att is_addressable32
	is_r32_in64_intel is_r32_in64_att is_r32_in64
	is_att_suffixed_instr is_att_suffixed_instr_fpu add_att_suffix_instr
	);

use strict;

=head1 NAME

Asm::X86 - List of instructions and registers of x86-compatible processors, validating and converting instructions and memory references.

=head1 VERSION

Version 0.70

=cut

our $VERSION = '0.70';

=head1 DESCRIPTION

This module provides the user with the ability to check whether a given
string represents an x86 processor register or instruction. It also provides
lists of registers and instructions and allows to check if a given
expression is a valid addressing mode. Other subroutines include converting
between AT&T and Intel syntaxes.

=head1 SYNOPSIS

    use Asm::X86 qw(@instr is_instr);

    print "YES" if is_instr ("MOV");

=head1 EXPORT

 Nothing is exported by default.

 The following functions are exported on request:
	is_reg_intel
	is_reg8_intel
	is_reg16_intel
	is_reg32_intel
	is_reg64_intel
	is_reg_mm_intel
	is_segreg_intel
	is_reg_fpu_intel
	is_reg_opmask_intel
	is_reg_bound_intel
	is_addressable32_intel
	is_r32_in64_intel

	is_reg_att
	is_reg8_att
	is_reg16_att
	is_reg32_att
	is_reg64_att
	is_reg_mm_att
	is_segreg_att
	is_reg_fpu_att
	is_reg_opmask_att
	is_reg_bound_att
	is_addressable32_att
	is_r32_in64_att

	is_reg
	is_reg8
	is_reg16
	is_reg32
	is_reg64
	is_reg_mm
	is_segreg
	is_reg_fpu
	is_reg_opmask
	is_reg_bound
	is_addressable32
	is_r32_in64

	is_instr_intel
	is_instr_att
	is_instr

	is_valid_16bit_addr_intel
	is_valid_32bit_addr_intel
	is_valid_64bit_addr_intel
	is_valid_addr_intel

	is_valid_16bit_addr_att
	is_valid_32bit_addr_att
	is_valid_64bit_addr_att
	is_valid_addr_att

	is_valid_16bit_addr
	is_valid_32bit_addr
	is_valid_64bit_addr
	is_valid_addr

	conv_att_addr_to_intel
	conv_att_instr_to_intel
	conv_intel_addr_to_att
	conv_intel_instr_to_att

	is_att_suffixed_instr
	is_att_suffixed_instr_fpu
	add_att_suffix_instr

 These check if the given string parameter belongs to the specified
 class of registers or instructions or is a valid addressing mode.
 The "convert*" functions can be used to convert the given instruction
  (including the operands)/addressing mode between AT&T and Intel syntaxes.
 The "_intel" and "_att" suffixes mean the Intel and AT&T syntaxes,
  respectively.
 No suffix means either Intel or AT&T.
 All subroutines work best given input after any pre-processing, i.e. after
  all macros, constants, etc. have been replaced by the real values.

 The following arrays are exported on request:
	@regs8_intel
	@regs16_intel
	@segregs_intel
	@regs32_intel
	@regs64_intel
	@regs_mm_intel
	@regs_fpu_intel
	@regs_opmask_intel
	@regs_intel

	@regs8_att
	@regs16_att
	@segregs_att
	@regs32_att
	@regs64_att
	@regs_mm_att
	@regs_fpu_att
	@regs_opmask_att
	@regs_att

	@instr_intel
	@instr_att
	@instr

 These contain all register and instruction mnemonic names as lower-case strings.
 The "_intel" and "_att" suffixes mean the Intel and AT&T syntaxes, respectively.
 No suffix means either Intel or AT&T.

=head1 DATA

=cut

# =head2 _add_percent
#
#  PRIVATE SUBROUTINE.
#  Add a percent character ('%') in front of each element in the array given as a parameter.
#  Returns the new array.
#
# =cut

sub _add_percent(@) {

	my @result = ();
	foreach (@_) {
		push @result, "%$_";
	}
	return @result;
}

# =head2 _remove_duplicates
#
#  PRIVATE SUBROUTINE.
#  Returns an array of the provided arguments with duplicate entries removed.
#
# =cut
#
sub _remove_duplicates(@) {

	# Use a hash to remove the duplicates:
	my %new_hash;
	foreach (@_) {
		$new_hash{$_} = 1;
	}
	return keys %new_hash;
}

# =head2 _nopluses
#
#  PRIVATE SUBROUTINE.
#  Removes unnecessary '+' characters from the beginning of the given string.
#  Returns the resulting string (or '+' if it was empty).
#
# =cut
#
sub _nopluses($) {

	my $elem = shift;
	$elem =~ s/^\s*\++//o;
	$elem = '+' if $elem eq '';
	return $elem;
}

# =head2 _is_in_array
#
#  PRIVATE SUBROUTINE.
#  Checks if the given element (1st parameter) is a simple word and is present
#	in the array (passed by reference as the 2nd parameter),
#	case-insensitive.
#  Returns 1 if yes.
#
# =cut
#
sub _is_in_array($@) {

	my $elem = shift;
	my $arr = shift;
	return 0 unless $elem =~ /^\w+$/o;
	foreach (@$arr) {
		return 1 if /^$elem$/i;
	}
	return 0;
}

# =head2 _is_in_array_att
#
#  PRIVATE SUBROUTINE.
#  Checks if the given element (1st parameter) is a simple word beginning
#	with '%' and is present in the array (passed by reference as the 2nd
#	parameter), case-insensitive.
#  Returns 1 if yes.
#
# =cut
#
sub _is_in_array_att($@) {

	my $elem = shift;
	my $arr = shift;
	return 0 unless $elem =~ /^\%\w+$/o;
	foreach (@$arr) {
		return 1 if /^$elem$/i;
	}
	return 0;
}


sub add_att_suffix_instr(@);

=head2 @regs8_intel

 A list of 8-bit registers (as strings) in Intel syntax.

=cut

our @regs8_intel = (
		'al', 'bl', 'cl', 'dl', 'r8b', 'r9b', 'r10b', 'r11b',
		'r12b', 'r13b', 'r14b', 'r15b', 'sil', 'dil', 'spl', 'bpl',
		'ah', 'bh', 'ch', 'dh'
		);

=head2 @regs8_att

 A list of 8-bit registers (as strings) in AT&T syntax.

=cut

our @regs8_att = _add_percent @regs8_intel;

=head2 @segregs_intel

 A list of segment registers (as strings) in Intel syntax.

=cut

our @segregs_intel = ( 'cs', 'ds', 'es', 'fs', 'gs', 'ss' );

=head2 @segregs_att

 A list of segment registers (as strings) in AT&T syntax.

=cut

our @segregs_att = _add_percent @segregs_intel;

=head2 @regs16_intel

 A list of 16-bit registers (as strings), including the segment registers,  in Intel syntax.

=cut

our @regs16_intel = (
		'ax', 'bx', 'cx', 'dx', 'r8w', 'r9w', 'r10w', 'r11w',
		'r12w', 'r13w', 'r14w', 'r15w', 'si', 'di', 'sp', 'bp',
		@segregs_intel
		);

=head2 @regs16_att

 A list of 16-bit registers (as strings), including the segment registers, in AT&T syntax.

=cut

our @regs16_att = _add_percent @regs16_intel;

my @addressable32 = ('eax', 'ebx', 'ecx', 'edx', 'esi', 'edi', 'esp', 'ebp');

my @addressable32_att = _add_percent @addressable32;

my @r32_in64 = (
		'r8d', 'r8l', 'r9d', 'r9l', 'r10d', 'r10l', 'r11d', 'r11l',
		'r12d', 'r12l', 'r13d', 'r13l', 'r14d', 'r14l', 'r15d', 'r15l',
		);

my @r32_in64_att = _add_percent @r32_in64;

=head2 @regs32_intel

 A list of 32-bit registers (as strings) in Intel syntax.

=cut

our @regs32_intel = (
		@addressable32,
		'cr0', 'cr2', 'cr3', 'cr4', 'cr8',
		'dr0', 'dr1', 'dr2', 'dr3', 'dr6', 'dr7',
		@r32_in64
		);

=head2 @regs32_att

 A list of 32-bit registers (as strings) in AT&T syntax.

=cut

our @regs32_att = _add_percent @regs32_intel;

=head2 @regs_fpu_intel

 A list of FPU registers (as strings) in Intel syntax.

=cut

our @regs_fpu_intel = ('st0', 'st1', 'st2', 'st3', 'st4', 'st5', 'st6', 'st7');

=head2 @regs_fpu_att

 A list of FPU registers (as strings) in AT&T syntax.

=cut

our @regs_fpu_att = _add_percent @regs_fpu_intel;

=head2 @regs64_intel

 A list of 64-bit registers (as strings) in Intel syntax.

=cut

our @regs64_intel = (
		'rax', 'rbx', 'rcx', 'rdx', 'r8', 'r9', 'r10', 'r11',
		'r12', 'r13', 'r14', 'r15', 'rsi', 'rdi', 'rsp', 'rbp', 'rip'
		);

=head2 @regs64_att

 A list of 64-bit registers (as strings) in AT&T syntax.

=cut

our @regs64_att = _add_percent @regs64_intel;

=head2 @regs_mm_intel

 A list of multimedia (MMX/3DNow!/SSEn) registers (as strings) in Intel syntax.

=cut

our @regs_mm_intel = (
		'mm0', 'mm1', 'mm2', 'mm3', 'mm4', 'mm5', 'mm6', 'mm7',
		'xmm0', 'xmm1', 'xmm2', 'xmm3', 'xmm4', 'xmm5', 'xmm6', 'xmm7',
		'xmm8', 'xmm9', 'xmm10', 'xmm11', 'xmm12', 'xmm13', 'xmm14', 'xmm15',
		'xmm16', 'xmm17', 'xmm18', 'xmm19', 'xmm20', 'xmm21', 'xmm22', 'xmm23',
		'xmm24', 'xmm25', 'xmm26', 'xmm27', 'xmm28', 'xmm29', 'xmm30', 'xmm31',
		'ymm0', 'ymm1', 'ymm2', 'ymm3', 'ymm4', 'ymm5', 'ymm6', 'ymm7',
		'ymm8', 'ymm9', 'ymm10', 'ymm11', 'ymm12', 'ymm13', 'ymm14', 'ymm15',
		'ymm16', 'ymm17', 'ymm18', 'ymm19', 'ymm20', 'ymm21', 'ymm22', 'ymm23',
		'ymm24', 'ymm25', 'ymm26', 'ymm27', 'ymm28', 'ymm29', 'ymm30', 'ymm31',
		'zmm0', 'zmm1', 'zmm2', 'zmm3', 'zmm4', 'zmm5', 'zmm6', 'zmm7',
		'zmm8', 'zmm9', 'zmm10', 'zmm11', 'zmm12', 'zmm13', 'zmm14', 'zmm15',
		'zmm16', 'zmm17', 'zmm18', 'zmm19', 'zmm20', 'zmm21', 'zmm22', 'zmm23',
		'zmm24', 'zmm25', 'zmm26', 'zmm27', 'zmm28', 'zmm29', 'zmm30', 'zmm31'
		);


=head2 @regs_mm_att

 A list of multimedia (MMX/3DNow!/SSEn) registers (as strings) in AT&T syntax.

=cut

our @regs_mm_att = _add_percent @regs_mm_intel;

=head2 @regs_opmask_intel

 A list of opmask registers (as strings) in Intel syntax.

=cut

our @regs_opmask_intel = ('k0', 'k1', 'k2', 'k3', 'k4', 'k5', 'k6', 'k7');


=head2 @regs_opmask_att

 A list of opmask registers (as strings) in AT&T syntax.

=cut

our @regs_opmask_att = _add_percent @regs_opmask_intel;

=head2 @regs_bound_intel

 A list of bound registers (as strings) in Intel syntax.

=cut

our @regs_bound_intel = ('bnd0', 'bnd1', 'bnd2', 'bnd3');


=head2 @regs_bound_att

 A list of bound registers (as strings) in AT&T syntax.

=cut

our @regs_bound_att = _add_percent @regs_bound_intel;

=head2 @regs_intel

 A list of all x86 registers (as strings) in Intel syntax.

=cut

our @regs_intel = ( @regs8_intel, @regs16_intel, @regs32_intel,
			@regs64_intel, @regs_mm_intel, @regs_fpu_intel,
			@regs_opmask_intel, @regs_bound_intel );

=head2 @regs_att

 A list of all x86 registers (as strings) in AT&T syntax.

=cut

our @regs_att = ( @regs8_att, @regs16_att, @regs32_att,
			@regs64_att, @regs_mm_att, @regs_fpu_att,
			@regs_opmask_att, @regs_bound_att );


=head2 @instr_intel

 A list of all x86 instructions (as strings) in Intel syntax.

=cut

our @instr_intel = (
	'aaa', 'aad', 'aadd', 'aam', 'aand', 'aas', 'adc', 'adcx', 'add', 'addpd', 'addps', 'addsd', 'addss', 'addsubpd',
	'addsubps', 'adox', 'aesdec', 'aesdeclast', 'aesenc', 'aesenclast', 'aesimc', 'aeskeygenassist',
	'and', 'andn', 'andnpd', 'andnps', 'andpd', 'andps', 'arpl', 'axor', 'bb0_reset',
	'bb1_reset', 'bextr', 'blcfill', 'blci', 'blcic', 'blcmsk', 'blcs',
	'blendpd', 'blendps', 'blendvpd', 'blendvps', 'blsfill', 'blsi', 'blsic', 'blsmsk', 'blsr',
	'bnd', 'bndcl', 'bndcn', 'bndcu', 'bndldx', 'bndmk', 'bndmov', 'bndstx',
	'bound', 'bsf', 'bsr', 'bswap', 'bt', 'btc', 'btr', 'bts', 'bzhi', 'call', 'cbw',
	'cdq', 'cdqe', 'clac', 'clc', 'cld', 'cldemote', 'clflush', 'clflushopt',
	'clgi', 'cli', 'clrssbsy','clts', 'clui', 'clwb', 'clzero',
	'cmc', 'cmova', 'cmovae', 'cmovb', 'cmovbe', 'cmovc', 'cmove', 'cmovg', 'cmovge',
	'cmovl', 'cmovle', 'cmovna', 'cmovnae', 'cmovnb', 'cmovnbe', 'cmovnc',
	'cmovne', 'cmovng', 'cmovnge', 'cmovnl', 'cmovnle', 'cmovno', 'cmovnp',
	'cmovns', 'cmovnz', 'cmovo', 'cmovp', 'cmovpe', 'cmovpo', 'cmovs', 'cmovz',
	'cmp', 'cmpaexadd', 'cmpaxadd', 'cmpbexadd', 'cmpbxadd', 'cmpcxadd',
	'cmpeqpd', 'cmpeqps', 'cmpeqsd', 'cmpeqss', 'cmpexadd', 'cmpgexadd', 'cmpgxadd',
	'cmplepd', 'cmpleps', 'cmplesd', 'cmpless', 'cmplexadd',
	'cmpltpd', 'cmpltps', 'cmpltsd', 'cmpltss', 'cmplxadd', 'cmpnaexadd', 'cmpnaxadd',
	'cmpnbexadd', 'cmpnbxadd', 'cmpncxadd', 'cmpneqpd', 'cmpneqps', 'cmpneqsd', 'cmpneqss',
	'cmpnexadd', 'cmpngexadd', 'cmpngxadd','cmpnlepd', 'cmpnleps', 'cmpnlesd', 'cmpnless',
	'cmpnlexadd', 'cmpnltpd', 'cmpnltps', 'cmpnltsd', 'cmpnltss', 
	'cmpnlxadd', 'cmpnoxadd', 'cmpnpxadd', 'cmpnsxadd', 'cmpnzxadd',
	'cmpordpd', 'cmpordps', 'cmpordsd', 'cmpordss', 'cmpoxadd',
	'cmppd', 'cmppexadd', 'cmppoxadd', 'cmpps', 'cmppxadd', 'cmpsb',
	'cmpsd', 'cmpsq', 'cmpss', 'cmpsw', 'cmpsxadd', 'cmpunordpd', 'cmpunordps', 'cmpunordsd', 'cmpunordss',
	'cmpxchg', 'cmpxchg16b', 'cmpxchg486', 'cmpxchg8b', 'cmpzxadd', 'comeqpd', 'comeqps', 'comeqsd',
	'comeqss', 'comfalsepd', 'comfalseps', 'comfalsesd', 'comfalsess', 'comisd', 'comiss',
	'comlepd', 'comleps', 'comlesd', 'comless', 'comltpd', 'comltps', 'comltsd', 'comltss',
	'comneqpd', 'comneqps', 'comneqsd', 'comneqss', 'comnlepd', 'comnleps', 'comnlesd', 'comnless',
	'comnltpd', 'comnltps', 'comnltsd', 'comnltss', 'comordpd', 'comordps', 'comordsd',
	'comordss', 'compd', 'comps', 'comsd', 'comss', 'comtruepd', 'comtrueps', 'comtruesd',
	'comtruess', 'comueqpd', 'comueqps', 'comueqsd', 'comueqss', 'comulepd', 'comuleps', 'comulesd',
	'comuless', 'comultpd', 'comultps', 'comultsd', 'comultss', 'comuneqpd', 'comuneqps', 'comuneqsd',
	'comuneqss', 'comunlepd', 'comunleps', 'comunlesd', 'comunless', 'comunltpd', 'comunltps',
	'comunltsd', 'comunltss', 'comunordpd', 'comunordps', 'comunordsd', 'comunordss', 'cpuid',
	'cpu_read', 'cpu_write', 'cqo', 'crc32', 'cvtdq2pd', 'cvtdq2ps', 'cvtpd2dq', 'cvtpd2pi',
	'cvtpd2ps', 'cvtph2ps', 'cvtpi2pd', 'cvtpi2ps', 'cvtps2dq', 'cvtps2pd', 'cvtps2ph',
	'cvtps2pi', 'cvtsd2si', 'cvtsd2ss', 'cvtsi2sd', 'cvtsi2ss', 'cvtss2sd', 'cvtss2si', 'cvttpd2dq',
	'cvttpd2pi', 'cvttps2dq', 'cvttps2pi', 'cvttsd2si', 'cvttss2si', 'cwd', 'cwde', 'daa', 'das',
	'dec', 'div', 'divpd', 'divps', 'divsd', 'divss', 'dmint', 'dppd',
	'dpps', 'emms', 'endbr32', 'endbr64', 'encls', 'enclu', 'enclv', 'enqcmd', 'enqcmds', 'enter',
	'erets', 'eretu', 'extractps', 'extrq', 'f2xm1', 'fabs', 'fadd', 'faddp', 'fbld', 'fbstp', 'fchs', 'fclex',
	'fcmovb', 'fcmovbe', 'fcmove', 'fcmovnb', 'fcmovnbe', 'fcmovne', 'fcmovnu', 'fcmovu', 'fcom',
	'fcomi', 'fcomip', 'fcomp', 'fcompp', 'fcos', 'fdecstp', 'fdisi', 'fdiv', 'fdivp', 'fdivr',
	'fdivrp', 'femms', 'feni', 'ffree', 'ffreep', 'fiadd', 'ficom', 'ficomp', 'fidiv', 'fidivr',
	'fild', 'fimul', 'fincstp', 'finit', 'fist', 'fistp', 'fisttp', 'fisub', 'fisubr', 'fld',
	'fld1', 'fldcw', 'fldenv', 'fldenvd', 'fldenvw', 'fldl2e', 'fldl2t', 'fldlg2', 'fldln2', 'fldpi', 'fldz', 'fmaddpd',
	'fmaddps', 'fmaddsd', 'fmaddss', 'fmsubpd', 'fmsubps', 'fmsubsd', 'fmsubss', 'fmul', 'fmulp',
	'fnclex', 'fndisi','fneni', 'fninit', 'fnmaddpd', 'fnmaddps', 'fnmaddsd', 'fnmaddss', 'fnmsubpd',
	'fnmsubps', 'fnmsubsd', 'fnmsubss', 'fnop', 'fnsave', 'fnsaved', 'fnsavew', 'fnstcw',
	'fnstenv', 'fnstenvd', 'fnstenvw', 'fnstsw', 'fpatan',
	'fprem', 'fprem1', 'fptan', 'frczpd', 'frczps', 'frczsd', 'frczss', 'frndint',
	'frstor', 'frstord', 'frstorw', 'frstpm', 'fsave', 'fsaved', 'fsavew',
	'fscale', 'fsetpm', 'fsin', 'fsincos', 'fsqrt', 'fst', 'fstcw', 'fstenv', 'fstenvd', 'fstenvw', 'fstp', 'fstsw',
	'fsub', 'fsubp', 'fsubr', 'fsubrp', 'ftst', 'fucom', 'fucomi', 'fucomip', 'fucomp', 'fucompp',
	'fwait', 'fxam', 'fxch', 'fxrstor', 'fxrstor64', 'fxsave', 'fxsave64',
	'fxtract', 'fyl2x', 'fyl2xp1', 'getsec', 'gf2p8affineinvqb', 'gf2p8affineqb', 'gf2p8mulb', 'haddpd',
	'haddps', 'hint_nop0', 'hint_nop1', 'hint_nop10', 'hint_nop11', 'hint_nop12', 'hint_nop13',
	'hint_nop14','hint_nop15', 'hint_nop16', 'hint_nop17', 'hint_nop18', 'hint_nop19', 'hint_nop2',
	'hint_nop20', 'hint_nop21', 'hint_nop22', 'hint_nop23', 'hint_nop24', 'hint_nop25', 'hint_nop26',
	'hint_nop27', 'hint_nop28', 'hint_nop29', 'hint_nop3', 'hint_nop30', 'hint_nop31', 'hint_nop32',
	'hint_nop33', 'hint_nop34', 'hint_nop35', 'hint_nop36', 'hint_nop37', 'hint_nop38', 'hint_nop39',
	'hint_nop4', 'hint_nop40', 'hint_nop41', 'hint_nop42', 'hint_nop43', 'hint_nop44', 'hint_nop45',
	'hint_nop46', 'hint_nop47', 'hint_nop48', 'hint_nop49', 'hint_nop5', 'hint_nop50', 'hint_nop51',
	'hint_nop52', 'hint_nop53', 'hint_nop54', 'hint_nop55', 'hint_nop56', 'hint_nop57', 'hint_nop58',
	'hint_nop59', 'hint_nop6', 'hint_nop60', 'hint_nop61', 'hint_nop62', 'hint_nop63', 'hint_nop7',
	'hint_nop8', 'hint_nop9', 'hlt', 'hreset', 'hsubpd', 'hsubps', 'ibts', 'icebp', 'idiv', 'imul', 'in',
	'inc', 'incsspd', 'incsspq', 'incbin', 'insb', 'insd', 'insertps', 'insertq', 'insw', 'int', 'int01', 'int03',
	'int1', 'int3', 'into', 'invd', 'invept', 'invlpg', 'invlpga', 'invlpgb', 'invpcid', 'invvpid', 'iret', 'iretd',
	'iretq', 'iretw', 'ja', 'jae', 'jb', 'jbe', 'jc', 'jcxz', 'je', 'jecxz', 'jg', 'jge', 'jl',
	'jle', 'jmp', 'jmpe', 'jna', 'jnae', 'jnb', 'jnbe', 'jnc', 'jne', 'jng', 'jnge', 'jnl',
	'jnle', 'jno', 'jnp', 'jns', 'jnz', 'jo', 'jp', 'jpe', 'jpo', 'jrcxz', 'js', 'jz',
	'kadd', 'kaddb', 'kaddd', 'kaddq', 'kaddw', 'kand', 'kandb', 'kandd', 'kandn', 'kandnb', 'kandnd', 'kandnq',
	'kandnw', 'kandq', 'kandw', 'kmov', 'kmovb', 'kmovd', 'kmovq','kmovw', 'knot', 'knotb', 'knotd',
	'knotq', 'knotw', 'kor', 'korb', 'kord', 'korq', 'kortest', 'kortestb', 'kortestd', 'kortestq','kortestw',
	'korw', 'kshiftl', 'kshiftlb', 'kshiftld', 'kshiftlq','kshiftlw', 'kshiftr', 'kshiftrb', 'kshiftrd',
	'kshiftrq', 'kshiftrw', 'ktest', 'ktestb', 'ktestd', 'ktestq', 'ktestw',
	'kunpck', 'kunpckbw', 'kunpckdq', 'kunpckwd', 'kxnor', 'kxnorb', 'kxnord', 'kxnorq', 'kxnorw',
	'kxor', 'kxorb', 'kxord', 'kxorq', 'kxorw',
	'lahf', 'lar', 'lddqu', 'ldmxcsr', 'lds', 'ldtilecfg', 'lea', 'leave', 'les', 'lfence', 'lfs', 'lgdt',
	'lgs', 'lidt', 'lkgs', 'lldt', 'llwpcb', 'lmsw', 'loadall', 'loadall286', 'loadall386', 'lock', 'lodsb', 'lodsd',
	'lodsq', 'lodsw', 'loop', 'loopd', 'loope', 'looped', 'loopeq', 'loopew', 'loopne', 'loopned',
	'loopneq', 'loopnew', 'loopnz', 'loopnzd', 'loopnzq', 'loopnzw', 'loopq', 'loopw', 'loopz',
	'loopzd', 'loopzq', 'loopzw', 'lsl', 'lss', 'ltr', 'lwpins', 'lwpval', 'lzcnt', 'maskmovdqu',
	'maskmovq', 'maxpd', 'maxps', 'maxsd', 'maxss', 'mcommit', 'mfence', 'minpd', 'minps', 'minsd',
	'minss', 'monitor', 'monitorx', 'montmul', 'mov', 'movapd',
	'movaps', 'movbe', 'movd', 'movddup', 'movdir64b', 'movdiri', 'movdq2q',
	'movdqa', 'movdqu', 'movhlps', 'movhpd', 'movhps', 'movlhps', 'movlpd', 'movlps', 'movmskpd',
	'movmskps', 'movntdq', 'movntdqa', 'movnti', 'movntpd', 'movntps', 'movntq', 'movntsd',
	'movntss', 'movq', 'movq2dq', 'movsb', 'movsd', 'movshdup', 'movsldup', 'movsq', 'movss',
	'movsw', 'movsx', 'movsxd', 'movupd', 'movups', 'movzx', 'mpsadbw', 'mul', 'mulpd', 'mulps',
	'mulsd', 'mulss', 'mulx', 'mwait', 'mwaitx', 'neg',
	'nop', 'not', 'or', 'orpd', 'orps', 'out', 'outsb', 'outsd',
	'outsw', 'pabsb', 'pabsd', 'pabsw', 'packssdw', 'packsswb', 'packusdw', 'packuswb', 'paddb',
	'paddd', 'paddq', 'paddsb', 'paddsiw', 'paddsw', 'paddusb', 'paddusw', 'paddw', 'palignr',
	'pand', 'pandn', 'pause', 'paveb', 'pavgb', 'pavgusb', 'pavgw', 'pblendvb', 'pblendw',
	'pclmulhqhqdq', 'pclmulhqhdq', 'pclmulhqlqdq', 'pclmullqhqdq', 'pclmullqhdq', 'pclmullqlqdq', 'pclmulqdq', 'pcmov',
	'pcmpeqb', 'pcmpeqd', 'pcmpeqq', 'pcmpeqw', 'pcmpestri', 'pcmpestrm', 'pcmpgtb', 'pcmpgtd',
	'pcmpgtq', 'pcmpgtw', 'pcmpistri', 'pcmpistrm', 'pcomb', 'pcomd', 'pcomeqb', 'pcomeqd',
	'pcomeqq', 'pcomequb', 'pcomequd', 'pcomequq', 'pcomequw', 'pcomeqw', 'pcomfalseb',
	'pcomfalsed', 'pcomfalseq', 'pcomfalseub', 'pcomfalseud', 'pcomfalseuq', 'pcomfalseuw',
	'pcomfalsew', 'pcomgeb', 'pcomged', 'pcomgeq', 'pcomgeub', 'pcomgeud', 'pcomgeuq', 'pcomgeuw',
	'pcomgew', 'pcomgtb', 'pcomgtd', 'pcomgtq', 'pcomgtub', 'pcomgtud', 'pcomgtuq', 'pcomgtuw',
	'pcomgtw', 'pcomleb', 'pcomled', 'pcomleq', 'pcomleub', 'pcomleud', 'pcomleuq', 'pcomleuw',
	'pcomlew', 'pcomltb', 'pcomltd', 'pcomltq', 'pcomltub', 'pcomltud', 'pcomltuq', 'pcomltuw',
	'pcomltw', 'pcommit', 'pcomneqb', 'pcomneqd', 'pcomneqq', 'pcomnequb', 'pcomnequd', 'pcomnequq',
	'pcomnequw', 'pcomneqw', 'pcomq', 'pcomtrueb', 'pcomtrued', 'pcomtrueq', 'pcomtrueub',
	'pcomtrueud', 'pcomtrueuq', 'pcomtrueuw', 'pcomtruew', 'pcomub', 'pcomud', 'pcomuq', 'pcomuw',
	'pcomw', 'pconfig', 'pdep', 'pdistib', 'permpd', 'permps', 'pext', 'pextrb',
	'pextrd', 'pextrq', 'pextrw', 'pf2id',
	'pf2iw', 'pfacc', 'pfadd', 'pfcmpeq', 'pfcmpge', 'pfcmpgt', 'pfmax', 'pfmin', 'pfmul',
	'pfnacc', 'pfpnacc', 'pfrcp', 'pfrcpit1', 'pfrcpit2', 'pfrcpv', 'pfrsqit1', 'pfrsqrt',
	'pfrsqrtv', 'pfsub', 'pfsubr', 'phaddbd', 'phaddbq', 'phaddbw', 'phaddd', 'phadddq', 'phaddsw',
	'phaddubd', 'phaddubq', 'phaddubw', 'phaddudq', 'phadduwd', 'phadduwq', 'phaddw', 'phaddwd',
	'phaddwq', 'phminposuw', 'phsubbw', 'phsubd', 'phsubdq', 'phsubsw', 'phsubw', 'phsubwd',
	'pi2fd', 'pi2fw', 'pinsrb', 'pinsrd', 'pinsrq', 'pinsrw', 'pmachriw', 'pmacsdd', 'pmacsdqh',
	'pmacsdql', 'pmacssdd', 'pmacssdqh', 'pmacssdql', 'pmacsswd', 'pmacssww', 'pmacswd',
	'pmacsww', 'pmadcsswd', 'pmadcswd', 'pmaddubsw', 'pmaddwd', 'pmagw', 'pmaxsb', 'pmaxsd',
	'pmaxsw', 'pmaxub', 'pmaxud', 'pmaxuw', 'pminsb', 'pminsd', 'pminsw', 'pminub', 'pminud',
	'pminuw', 'pmovmskb', 'pmovsxbd', 'pmovsxbq', 'pmovsxbw', 'pmovsxdq', 'pmovsxwd', 'pmovsxwq',
	'pmovzxbd', 'pmovzxbq', 'pmovzxbw', 'pmovzxdq', 'pmovzxwd', 'pmovzxwq', 'pmuldq', 'pmulhriw',
	'pmulhrsw', 'pmulhrwa', 'pmulhrw', 'pmulhrwc', 'pmulhuw', 'pmulhw', 'pmulld', 'pmullw', 'pmuludq',
	'pmvgezb', 'pmvlzb', 'pmvnzb', 'pmvzb', 'pop', 'popd', 'popa', 'popad', 'popaw', 'popcnt', 'popf',
	'popfd', 'popfq', 'popfw', 'popq', 'popw', 'por', 'pperm',
	'prefetch', 'prefetchit0', 'prefetchit1', 'prefetchnta', 'prefetcht0', 'prefetcht1',
	'prefetcht2', 'prefetchw', 'prefetchwt1', 'protb', 'protd', 'protq', 'protw', 'psadbw',
	'pshab', 'pshad', 'pshaq', 'pshaw', 'pshlb', 'pshld', 'pshlq', 'pshlw', 'pshufb', 'pshufd',
	'pshufhw', 'pshuflw', 'pshufw', 'psignb', 'psignd', 'psignw', 'pslld', 'pslldq', 'psllq',
	'psllw', 'psmash', 'psrad', 'psraw', 'psrld', 'psrldq', 'psrlq', 'psrlw', 'psubb', 'psubd', 'psubq',
	'psubsb', 'psubsiw', 'psubsw', 'psubusb', 'psubusw', 'psubw', 'pswapd', 'ptest', 'ptwrite', 'punpckhbw',
	'punpckhdq', 'punpckhqdq', 'punpckhwd', 'punpcklbw', 'punpckldq', 'punpcklqdq', 'punpcklwd',
	'push', 'pusha', 'pushad', 'pushaw', 'pushd', 'pushf', 'pushfd', 'pushfq', 'pushfw', 'pushq',
	'pushw', 'pvalidate', 'pxor', 'rcl', 'rcpps', 'rcpss', 'rcr', 'rdfsbase', 'rdgsbase', 'rdm', 'rdmsr',
	'rdmsrlist', 'rdmsrq', 'rdpid', 'rdpkru', 'rdpmc', 'rdpru', 'rdrand',
	'rdseed', 'rdsspd', 'rdsspq', 'rdshr', 'rdtsc', 'rdtscp', 'rep', 'repe', 'repne', 'repnz',
	'repz', 'ret', 'retd', 'retf', 'retfd', 'retfq', 'retfw', 'retn', 'retnd', 'retnq', 'retnw', 'retq', 'retw',
	'rmpadjust', 'rmpupdate', 'rol', 'ror', 'rorx', 'roundpd', 'roundps', 'roundsd', 'roundss', 'rsdc', 'rsldt', 'rsm',
	'rsqrtps', 'rsqrtss', 'rstorssp', 'rsts', 'sahf', 'sal', 'salc', 'sar',
	'sarx', 'saveprevssp', 'sbb', 'scasb', 'scasd', 'scasq',
	'scasw', 'senduipi', 'serialize', 'seta', 'setae', 'setalc', 'setb',
	'setbe', 'setc', 'sete', 'setg', 'setge', 'setl',
	'setle', 'setna', 'setnae', 'setnb', 'setnbe', 'setnc', 'setne', 'setng', 'setnge',
	'setnl', 'setnle', 'setno', 'setnp', 'setns', 'setnz', 'seto', 'setp', 'setpe', 'setpo',
	'sets', 'setssbsy', 'setz', 'sfence', 'sgdt', 'sha1msg1',
	'sha1msg2', 'sha1nexte', 'sha1rnds4', 'sha256msg1', 'sha256msg2', 'sha256rnds2',
	'shl', 'shld', 'shlx', 'shr', 'shrd', 'shrx', 'shufpd', 'shufps', 'sidt',
	'skinit', 'sldt', 'slwpcb', 'smi', 'smint', 'smintold', 'smsw', 'sqrtpd', 'sqrtps', 'sqrtsd',
	'sqrtss', 'stac', 'stc', 'std', 'stgi', 'sti', 'stmxcsr', 'stosb', 'stosd', 'stosq', 'stosw',
	'str', 'sttilecfg', 'stui', 'sub',
	'subpd', 'subps', 'subsd', 'subss', 'svdc', 'svldt', 'svts', 'swapgs', 'syscall', 'sysenter',
	'sysexit', 'sysexitq', 'sysret', 'sysretq', 't1mskc', 'tdpbf16ps', 'tdpbssd', 'tdpbsud', 'tdpbusd', 'tdpbuud',
	'test', 'testui', 'tileloadd', 'tileloaddt1', 'tilerelease', 'tilestored',
	'tilezero', 'tlbsync', 'tpause', 'tzcnt', 'tzmsk',
	'ucomisd', 'ucomiss', 'ud0', 'ud1', 'ud2', 'ud2a', 'ud2b', 'uiret', 'umonitor', 'umov',
	'umwait', 'unpckhpd', 'unpckhps', 'unpcklpd', 'unpcklps', 'useavx256', 'useavx512',
	'v4dpwssd', 'v4dpwssds', 'v4fmaddps', 'v4fmaddss', 'v4fnmaddps', 'v4fnmaddss',
	'vaddpd', 'vaddph', 'vaddps', 'vaddsd', 'vaddsh', 'vaddss', 'vaddsubpd', 'vaddsubps', 'vaesdec',
	'vaesdeclast', 'vaesenc', 'vaesenclast', 'vaesimc', 'vaeskeygenassist', 'valignd',
	'valignq', 'vandnpd', 'vandnps', 'vandpd', 'vandps', 'vbcstnebf16ps',
	'vbcstnesh2ps', 'vblendmpd', 'vblendmps', 'vblendpd', 'vblendps',
	'vblendvpd', 'vblendvps', 'vbroadcastf128', 'vbroadcastf32x2', 'vbroadcastf32x4',
	'vbroadcastf32x8', 'vbroadcastf64x2', 'vbroadcastf64x4', 'vbroadcasti128', 'vbroadcasti32x2',
	'vbroadcasti32x4', 'vbroadcasti32x8', 'vbroadcasti64x2',
	'vbroadcasti64x4', 'vbroadcastsd', 'vbroadcastss', 'vcmpeqpd',
	'vcmpeqps', 'vcmpeqsd', 'vcmpeqss', 'vcmpeq_oqpd', 'vcmpeq_oqps', 'vcmpeq_oqsd', 'vcmpeq_oqss',
	'vcmpeq_ospd', 'vcmpeq_osps', 'vcmpeq_ossd',
	'vcmpeq_osss', 'vcmpeq_uqpd', 'vcmpeq_uqps',
	'vcmpeq_uqsd', 'vcmpeq_uqss', 'vcmpeq_uspd',
	'vcmpeq_usps', 'vcmpeq_ussd', 'vcmpeq_usss', 'vcmpfalsepd', 'vcmpfalseps', 'vcmpfalsesd',
	'vcmpfalsess', 'vcmpfalse_oqpd', 'vcmpfalse_oqps', 'vcmpfalse_oqsd', 'vcmpfalse_oqss',
	'vcmpfalse_ospd', 'vcmpfalse_osps', 'vcmpfalse_ossd', 'vcmpfalse_osss',
	'vcmpgepd', 'vcmpgeps', 'vcmpgesd', 'vcmpgess', 'vcmpge_oqpd', 'vcmpge_oqps', 'vcmpge_oqsd',
	'vcmpge_oqss', 'vcmpge_ospd', 'vcmpge_osps', 'vcmpge_ossd',
	'vcmpge_osss', 'vcmpgtpd', 'vcmpgtps', 'vcmpgtsd', 'vcmpgtss', 'vcmpgt_oqpd', 'vcmpgt_oqps',
	'vcmpgt_oqsd', 'vcmpgt_oqss', 'vcmpgt_ospd', 'vcmpgt_osps',
	'vcmpgt_ossd', 'vcmpgt_osss', 'vpcmpleb', 'vcmplepd', 'vcmpleps', 'vcmplesd', 'vcmpless',
	'vpcmpleub', 'vpcmpleuw', 'vpcmplew', 'vcmple_oqpd',
	'vcmple_oqps', 'vcmple_oqsd', 'vcmple_oqss', 'vcmple_ospd',
	'vcmple_osps', 'vcmple_ossd', 'vcmple_osss', 'vpcmpltb', 'vcmpltpd', 'vcmpltps', 'vcmpltsd',
	'vcmpltss', 'vpcmpltub', 'vpcmpltuw', 'vpcmpltw',
	'vcmplt_oqpd', 'vcmplt_oqps', 'vcmplt_oqsd', 'vcmplt_oqss',
	'vcmplt_ospd', 'vcmplt_osps', 'vcmplt_ossd', 'vcmplt_osss', 'vpcmpneqb', 'vcmpneqpd', 'vcmpneqps',
	'vcmpneqsd', 'vcmpneqss', 'vpcmpnequb', 'vpcmpnequw', 'vpcmpneqw', 'vcmpneq_oqpd',
	'vcmpneq_oqps', 'vcmpneq_oqsd', 'vcmpneq_oqss',
	'vcmpneq_ospd', 'vcmpneq_osps', 'vcmpneq_ossd', 'vcmpneq_osss',
	'vcmpneq_uqpd', 'vcmpneq_uqps', 'vcmpneq_uqsd', 'vcmpneq_uqss', 'vcmpneq_uspd', 'vcmpneq_usps',
	'vcmpneq_ussd', 'vcmpneq_usss', 'vcmpngepd', 'vcmpngeps', 'vcmpngesd', 'vcmpngess', 'vcmpnge_uqpd',
	'vcmpnge_uqps', 'vcmpnge_uqsd', 'vcmpnge_uqss',
	'vcmpnge_uspd', 'vcmpnge_usps', 'vcmpnge_ussd', 'vcmpnge_usss',
	'vcmpngtpd', 'vcmpngtps', 'vcmpngtsd', 'vcmpngtss',
	'vcmpngt_uqpd', 'vcmpngt_uqps', 'vcmpngt_uqsd', 'vcmpngt_uqss',
	'vcmpngt_uspd', 'vcmpngt_usps', 'vcmpngt_ussd', 'vcmpngt_usss', 'vpcmpnleb', 'vcmpnlepd', 'vcmpnleps',
	'vcmpnlesd', 'vcmpnless', 'vpcmpnleub', 'vpcmpnleuw', 'vpcmpnlew',
	'vcmpnle_uqpd', 'vcmpnle_uqps', 'vcmpnle_uqsd', 'vcmpnle_uqss',
	'vcmpnle_uspd', 'vcmpnle_usps', 'vcmpnle_ussd', 'vcmpnle_usss',
	'vpcmpnltb', 'vcmpnltpd', 'vcmpnltps', 'vcmpnltsd', 'vcmpnltss', 'vpcmpnltub',
	'vpcmpnltuw', 'vpcmpnltw', 'vcmpnlt_uqpd', 'vcmpnlt_uqps', 'vcmpnlt_uqsd',
	'vcmpnlt_uqss', 'vcmpnlt_uspd', 'vcmpnlt_usps', 'vcmpnlt_ussd', 'vcmpnlt_usss',
	'vcmpordpd', 'vcmpordps', 'vcmpordsd', 'vcmpordss', 'vcmpord_qpd', 'vcmpord_qps',
	'vcmpord_qsd', 'vcmpord_qss', 'vcmpord_spd', 'vcmpord_sps',
	'vcmpord_ssd', 'vcmpord_sss', 'vcmppd', 'vcmpph', 'vcmpps',
	'vcmpsd', 'vcmpsh', 'vcmpss', 'vcmptruepd', 'vcmptrueps',
	'vcmptruesd', 'vcmptruess', 'vcmptrue_uqpd', 'vcmptrue_uqps', 'vcmptrue_uqsd', 'vcmptrue_uqss',
	'vcmptrue_uspd', 'vcmptrue_usps', 'vcmptrue_ussd', 'vcmptrue_usss',
	'vcmpunordpd', 'vcmpunordps', 'vcmpunordsd', 'vcmpunordss', 'vcmpunord_qpd', 'vcmpunord_qps',
	'vcmpunord_qsd', 'vcmpunord_qss', 'vcmpunord_spd', 'vcmpunord_sps', 'vcmpunord_ssd',
	'vcmpunord_sss', 'vcomisd', 'vcomish', 'vcomiss', 'vcompresspd',
	'vcompressps', 'vcvtdq2pd', 'vcvtdq2ph', 'vcvtdq2ps', 'vcvtne2ps2bf16',
	'vcvtneebf162ps', 'vcvtneeph2ps', 'vcvtneobf162ps', 'vcvtneoph2ps', 'vcvtneps2bf16',
	'vcvtpd2dq', 'vcvtpd2ph', 'vcvtpd2ps', 'vcvtpd2qq', 'vcvtpd2udq', 'vcvtpd2uqq',
	'vcvtph2dq', 'vcvtph2pd', 'vcvtph2ps', 'vcvtph2psx', 'vcvtph2qq',
	'vcvtph2udq', 'vcvtph2uqq', 'vcvtph2uw', 'vcvtph2w', 'vcvtps2dq', 'vcvtps2pd', 'vcvtps2ph',
	'vcvtps2qq', 'vcvtps2udq', 'vcvtps2uqq', 'vcvtqq2pd', 'vcvtqq2ph', 'vcvtqq2ps',
	'vcvtsd2sh', 'vcvtsd2si', 'vcvtsd2ss', 'vcvtsd2usi', 'vcvtsh2sd', 'vcvtsh2si',
	'vcvtsh2ss', 'vcvtsh2usi', 'vcvtsi2sd', 'vcvtsi2sh', 'vcvtsi2ss', 'vcvtss2sd',
	'vcvtss2sh', 'vcvtss2si', 'vcvtss2usi', 'vcvttpd2dq',
	'vcvttpd2qq', 'vcvttpd2udq', 'vcvttpd2uqq', 'vcvttph2dq',
	'vcvttph2qq', 'vcvttph2udq', 'vcvttph2uqq', 'vcvttph2uw', 'vcvttph2w', 'vcvttps2dq', 'vcvttps2qq',
	'vcvttps2uqq', 'vcvttps2udq', 'vcvttsd2si', 'vcvttsd2usi',
	'vcvttsh2si', 'vcvttsh2usi', 'vcvttss2si', 'vcvttss2usi',
	'vcvtudq2pd', 'vcvtudq2ph', 'vcvtudq2ps', 'vcvtuqq2pd', 'vcvtuqq2ph',
	'vcvtuqq2ps', 'vcvtusi2sd', 'vcvtusi2sh', 'vcvtusi2ss', 'vcvtuw2ph', 'vcvtw2ph', 'vdbpsadbw',
	'vdivpd', 'vdivph', 'vdivps', 'vdivsd', 'vdivsh','vdivss', 'vdpbf16ps',
	'vdppd', 'vdpps', 'vendscaleph', 'vendscalesh', 'verr', 'verw',
	'vexp2pd', 'vexp2ps', 'vexpandpd', 'vexpandps',
	'vextractf128', 'vextractf32x4', 'vextractf32x8', 'vextractf64x2',
	'vextractf64x4', 'vextracti128', 'vextracti32x4', 'vextracti32x8', 'vextracti64x2',
	'vextracti64x4', 'vextractps', 'vfcmaddcph', 'vfcmaddcsh', 'vfcmulcpch', 'vfcmulcsh',
	'vfixupimmpd', 'vfixupimmps', 'vfixupimmsd', 'vfixupimmss',
	'vfmadd123pd', 'vfmadd123ps', 'vfmadd123sd', 'vfmadd123ss',
	'vfmadd132pd', 'vfmadd132ph', 'vfmadd132ps', 'vfmadd132sd', 'vfmadd132ss', 'vfmadd213pd', 'vfmadd213ph', 'vfmadd213ps',
	'vfmadd213sd', 'vfmadd213ss', 'vfmadd231pd', 'vfmadd231ph', 'vfmadd231ps', 'vfmadd231sd', 'vfmadd231ss',
	'vfmadd312pd', 'vfmadd312ps', 'vfmadd312sd', 'vfmadd312ss', 'vfmadd321pd', 'vfmadd321ps',
	'vfmadd321sd', 'vfmadd321ss', 'vfmaddcph', 'vfmaddcsh', 'vfmaddpd', 'vfmaddps', 'vfmaddsd', 'vfmaddss', 'vfmaddsub123pd',
	'vfmaddsub123ps', 'vfmaddsub132pd', 'vfmaddsub132ph', 'vfmaddsub132ps',
	'vfmaddsub213pd', 'vfmaddsub213ph', 'vfmaddsub213ps',
	'vfmaddsub231pd', 'vfmaddsub231ph','vfmaddsub231ps', 'vfmaddsub312pd', 'vfmaddsub312ps', 'vfmaddsub321pd',
	'vfmaddsub321ps', 'vfmaddsubpd', 'vfmaddsubps', 'vfmsub123pd', 'vfmsub123ps',
	'vfmsub123sd', 'vfmsub123ss', 'vfmsub132pd', 'vfmsub132ph', 'vfmsub132ps', 'vfmsub132sd',
	'vfmsub132ss', 'vfmsub213pd', 'vfmsub213ph', 'vfmsub213ps', 'vfmsub213sd', 'vfmsub213ss',
	'vfmsub231pd', 'vfmsub231ph', 'vfmsub231ps', 'vfmsub231sd', 'vfmsub231ss', 'vfmsub312pd',
	'vfmsub312ps', 'vfmsub312sd', 'vfmsub312ss', 'vfmsub321pd', 'vfmsub321ps',
	'vfmsub321sd', 'vfmsub321ss', 'vfmsubadd123pd', 'vfmsubadd123ps', 'vfmsubadd132pd', 'vfmsubadd132ph',
	'vfmsubadd132ps', 'vfmsubadd213pd', 'vfmsubadd213ph', 'vfmsubadd213ps', 'vfmsubadd231pd', 'vfmsubadd231ph', 'vfmsubadd231ps',
	'vfmsubadd312pd', 'vfmsubadd312ps', 'vfmsubadd321pd', 'vfmsubadd321ps', 'vfmsubaddpd',
	'vfmsubaddps', 'vfmsubpd', 'vfmsubps', 'vfmsubsd', 'vfmsubss', 'vfmulcpch', 'vfmulcsh', 'vfnmadd123pd', 'vfnmadd123ps',
	'vfnmadd123sd', 'vfnmadd123ss', 'vfnmadd132pd', 'vfnmadd132ps', 'vfnmadd132sd', 'vfnmadd132ss',
	'vfnmadd213pd', 'vfnmadd213ps', 'vfnmadd213sd', 'vfnmadd213ss', 'vfnmadd231pd',
	'vfnmadd231ps', 'vfnmadd231sd', 'vfnmadd231ss', 'vfnmadd312pd', 'vfnmadd312ps',
	'vfnmadd312sd', 'vfnmadd312ss', 'vfnmadd321pd', 'vfnmadd321ps', 'vfnmadd321sd',
	'vfnmadd321ss', 'vfnmaddpd', 'vfnmaddps', 'vfnmaddsd', 'vfnmaddss', 'vfnmsub123pd',
	'vfnmsub123ps', 'vfnmsub123sd', 'vfnmsub123ss', 'vfnmsub132pd', 'vfnmsub132ps',
	'vfnmsub132sd', 'vfnmsub132ss', 'vfnmsub213pd', 'vfnmsub213ps', 'vfnmsub213sd',
	'vfnmsub213ss', 'vfnmsub231pd', 'vfnmsub231ps', 'vfnmsub231sd', 'vfnmsub231ss',
	'vfnmsub312pd', 'vfnmsub312ps', 'vfnmsub312sd', 'vfnmsub312ss', 'vfnmsub321pd',
	'vfnmsub321ps', 'vfnmsub321sd', 'vfnmsub321ss', 'vfnmsubpd', 'vfnmsubps', 'vfnmsubsd',
	'vfnmsubss', 'vfpclasspd', 'vfpclassph', 'vfpclassps', 'vfpclasssd', 'vfpclasssh', 'vfpclassss', 'vfrczpd',
	'vfrczps', 'vfrczsd', 'vfrczss', 'vgatherdpd', 'vgatherdps',
	'vgatherpf0dpd', 'vgatherpf0dps', 'vgatherpf0qpd', 'vgatherpf0qps',
	'vgatherpf1dpd', 'vgatherpf1dps', 'vgatherpf1qpd', 'vgatherpf1qps',
	'vgatherqpd', 'vgatherqps', 'vgetexppd', 'vgetexpph', 'vgetexpps', 'vgetexpsd', 'vgetexpsh', 'vgetexpss',
	'vgetmantpd', 'vgetmantph', 'vgetmantps', 'vgetmantsd', 'vgetmantsh', 'vgetmantss',
	'vgetmaxph', 'vgetmaxsh', 'vgetminph', 'vgetminsh', 'vgf2p8affineinvqb',
	'vgf2p8affineqb', 'vgf2p8mulb', 'vhaddpd', 'vhaddps', 'vhsubpd',
	'vhsubps', 'vinsertf128', 'vinsertf32x4', 'vinsertf32x8',
	'vinsertf64x2', 'vinsertf64x4', 'vinserti128', 'vinserti32x4', 'vinserti32x8', 'vinserti64x2',
	'vinserti64x4', 'vinsertps', 'vlddqu', 'vldmxcsr', 'vldqqu', 'vmaskmovdqu',
	'vmaskmovpd', 'vmaskmovps', 'vmaxpd', 'vmaxps', 'vmaxsd', 'vmaxss', 'vmcall', 'vmclear', 'vmfunc',
	'vmgexit', 'vminpd', 'vminps', 'vminsd', 'vminss', 'vmlaunch', 'vmload', 'vmmcall', 'vmovapd', 'vmovaps',
	'vmovd', 'vmovddup', 'vmovdqa', 'vmovdqa32',
	'vmovdqa64', 'vmovdqu', 'vmovdqu16', 'vmovdqu32',
	'vmovdqu64', 'vmovdqu8', 'vmovhlps', 'vmovhpd', 'vmovhps', 'vmovlhps',
	'vmovlpd', 'vmovlps', 'vmovmskpd', 'vmovmskps', 'vmovntdq', 'vmovntdqa', 'vmovntpd',
	'vmovntps', 'vmovntqq', 'vmovq', 'vmovqqa', 'vmovqqu', 'vmovsd', 'vmovsh', 'vmovshdup', 'vmovsldup',
	'vmovss', 'vmovupd', 'vmovups', 'vmovw', 'vmpsadbw', 'vmptrld', 'vmptrst', 'vmread', 'vmresume',
	'vmrun', 'vmsave', 'vmulpd', 'vmulph', 'vmulps', 'vmulsd', 'vmulsh', 'vmulss', 'vmwrite', 'vmxoff', 'vmxon',
	'vorpd', 'vorps', 'vp2intersectd', 'vp4dpwssd', 'vp4dpwssds', 'vpabsb', 'vpabsd',
	'vpabsq', 'vpabsw', 'vpackssdw', 'vpacksswb', 'vpackusdw',
	'vpackuswb', 'vpaddb', 'vpaddd', 'vpaddq', 'vpaddsb', 'vpaddsw', 'vpaddusb',
	'vpaddusw', 'vpaddw', 'vpalignr', 'vpand', 'vpandd', 'vpandn', 'vpandnd',
	'vpandnq', 'vpandq', 'vpavgb', 'vpavgw', 'vpblendd', 'vpblendmb', 'vpblendmd', 'vpblendmq',
	'vpblendmw', 'vpblendvb', 'vpblendw', 'vpbroadcastb', 'vpbroadcastd', 'vpbroadcastmb2q',
	'vpbroadcastmw2d', 'vpbroadcastq', 'vpbroadcastw',
	'vpclmulhqhqdq', 'vpclmulhqhdq', 'vpclmulhqlqdq', 'vpclmullqhqdq', 'vpclmullqhdq', 'vpclmullqlqdq',
	'vpclmulqdq', 'vpcmov', 'vpcmpb', 'vpcmpd', 'vpcmpeqb', 'vpcmpeqd', 'vpcmpeqq', 'vpcmpequb', 'vpcmpequd',
	'vpcmpequq', 'vpcmpequw', 'vpcmpeqw', 'vpcmpestri',
	'vpcmpestrm', 'vpcmpgeb', 'vpcmpged', 'vpcmpgeq', 'vpcmpgeub', 'vpcmpgeud', 'vpcmpgeuq', 'vpcmpgeuw', 'vpcmpgew',
	'vpcmpgtb', 'vpcmpgtd', 'vpcmpgtq', 'vpcmpgtub', 'vpcmpgtud', 'vpcmpgtuq', 'vpcmpgtuw',
	'vpcmpgtw', 'vpcmpistri', 'vpcmpistrm',
	'vpcmpled', 'vpcmpleq', 'vpcmpleud', 'vpcmpleuq', 'vpcmpltd', 'vpcmpltq',
	'vpcmpltud', 'vpcmpltuq', 'vpcmpneqd', 'vpcmpneqq', 'vpcmpnequd', 'vpcmpnequq',
	'vpcmpngtb', 'vpcmpngtd', 'vpcmpngtq', 'vpcmpngtub', 'vpcmpngtud', 'vpcmpngtuq',
	'vpcmpngtuw', 'vpcmpngtw',
	'vpcmpnled', 'vpcmpnleq', 'vpcmpnleud', 'vpcmpnleuq', 'vpcmpnltd', 'vpcmpnltq',
	'vpcmpnltud', 'vpcmpnltuq', 'vpcmpq', 'vpcmpub', 'vpcmpud',
	'vpcmpuq', 'vpcmpuw', 'vpcmpw', 'vpcomb', 'vpcomd',
	'vpcomeqb', 'vpcomeqd', 'vpcomeqq', 'vpcomequb', 'vpcomequd', 'vpcomequq',
	'vpcomequw', 'vpcomeqw', 'vpcomfalseb', 'vpcomfalsed', 'vpcomfalseq', 'vpcomfalseub',
	'vpcomfalseud', 'vpcomfalseuq', 'vpcomfalseuw', 'vpcomfalsew', 'vpcomgeb', 'vpcomged',
	'vpcomgeq', 'vpcomgeub', 'vpcomgeud', 'vpcomgeuq', 'vpcomgeuw', 'vpcomgew', 'vpcomgtb',
	'vpcomgtd', 'vpcomgtq', 'vpcomgtub', 'vpcomgtud', 'vpcomgtuq', 'vpcomgtuw', 'vpcomgtw',
	'vpcomleb', 'vpcomled', 'vpcomleq', 'vpcomleub', 'vpcomleud', 'vpcomleuq', 'vpcomleuw',
	'vpcomlew', 'vpcomltb', 'vpcomltd', 'vpcomltq', 'vpcomltub', 'vpcomltud', 'vpcomltuq',
	'vpcomltuw', 'vpcomltw', 'vpcomneqb', 'vpcomneqd', 'vpcomneqq', 'vpcomnequb', 'vpcomnequd',
	'vpcomnequq', 'vpcomnequw', 'vpcomneqw', 'vpcompressb', 'vpcompressd', 'vpcompressq',
	'vpcompressw', 'vpcomq', 'vpcomtrueb', 'vpcomtrued', 'vpcomtrueq',
	'vpcomtrueub', 'vpcomtrueud', 'vpcomtrueuq', 'vpcomtrueuw', 'vpcomtruew',
	'vpcomub', 'vpcomud', 'vpcomuq', 'vpcomuw', 'vpcomw', 'vpconflictd', 'vpconflictq',
	'vpdpbssd', 'vpdpbssds', 'vpdpbsud', 'vpdpbsuds', 'vpdpbusd', 'vpdpbusds',
	'vpdpbuud', 'vpdpbuuds', 'vpdpwssd', 'vpdpwssds', 'vperm2f128', 'vperm2i128',
	'vpermb', 'vpermd', 'vpermi2b', 'vpermi2d', 'vpermi2pd', 'vpermi2w', 'vpermi2ps',
	'vpermi2q', 'vpermil2pd', 'vpermil2ps', 'vpermilmo2pd',
	'vpermilmo2ps', 'vpermilmz2pd', 'vpermilmz2ps', 'vpermilpd', 'vpermilps', 'vpermpd',
	'vpermps', 'vpermq', 'vpermt2b', 'vpermt2d', 'vpermt2pd', 'vpermt2ps', 'vpermt2q', 'vpermt2w',
	'vpermw', 'vpexpandb', 'vpexpandd', 'vpexpandq', 'vpexpandw', 'vpermiltd2pd', 'vpermiltd2ps', 'vpextrb',
	'vpextrd', 'vpextrq', 'vpextrw', 'vpgatherdd', 'vpgatherdq', 'vpgatherqd', 'vpgatherqq',
	'vphaddbd', 'vphaddbq', 'vphaddbw', 'vphaddd',
	'vphadddq', 'vphaddsw', 'vphaddubd', 'vphaddubq', 'vphaddubw', 'vphaddubwd', 'vphaddudq',
	'vphadduwd', 'vphadduwq', 'vphaddw', 'vphaddwd', 'vphaddwq', 'vphminposuw',
	'vphsubbw', 'vphsubd', 'vphsubdq', 'vphsubsw', 'vphsubw', 'vphsubwd', 'vpinsrb',
	'vpinsrd', 'vpinsrq', 'vpinsrw', 'vplzcntd',
	'vplzcntq', 'vpmacsdd', 'vpmacsdqh', 'vpmacsdql', 'vpmacssdd',
	'vpmacssdqh', 'vpmacssdql', 'vpmacsswd', 'vpmacssww', 'vpmacswd', 'vpmacsww',
	'vpmadcsswd', 'vpmadcswd', 'vpmadd132ph', 'vpmadd132sh', 'vpmadd213ph',
	'vpmadd213sh', 'vpmadd231ph', 'vpmadd231sh', 'vpmadd52huq',
	'vpmadd52luq', 'vpmaddubsw', 'vpmaddwd', 'vpmaskmovd', 'vpmaskmovq',
	'vpmaxsb', 'vpmaxsd', 'vpmaxsq', 'vpmaxsw',
	'vpmaxub', 'vpmaxud', 'vpmaxuq', 'vpmaxuw', 'vpminsb', 'vpminsd',
	'vpminsq', 'vpminsw', 'vpminub', 'vpminud', 'vpminuq',
	'vpminuw', 'vpmovb2m', 'vpmovd2m', 'vpmovdb', 'vpmovdw', 'vpmovm2b',
	'vpmovm2d', 'vpmovm2q', 'vpmovm2w', 'vpmovmskb', 'vpmovq2m', 'vpmovqb',
	'vpmovqd', 'vpmovqw', 'vpmovsdb', 'vpmovsdw', 'vpmovsqb', 'vpmovsqd',
	'vpmovsqw', 'vpmovswb', 'vpmovsxbd', 'vpmovsxbq', 'vpmovsxbw', 'vpmovsxdq',
	'vpmovsxwd', 'vpmovsxwq', 'vpmovusdb', 'vpmovusdw', 'vpmovusqb', 'vpmovusqd',
	'vpmovusqw', 'vpmovuswb', 'vpmovw2m', 'vpmovwb', 'vpmovzxbd', 'vpmovzxbq', 'vpmovzxbw', 'vpmovzxdq',
	'vpmovzxwd', 'vpmovzxwq', 'vpmsub132ph', 'vpmsub132sh', 'vpmsub213ph',
	'vpmsub213sh', 'vpmsub231ph', 'vpmsub231sh', 'vpmuldq', 'vpmulhrsw', 'vpmulhuw', 'vpmulhw', 'vpmulld', 'vpmullq',
	'vpmullw', 'vpmultishiftqb', 'vpmuludq', 'vpnmadd132sh', 'vpnmadd213sh',
	'vpnmadd231sh', 'vpnmsub132sh', 'vpnmsub213sh', 'vpnmsub231sh', 'vpopcntb', 'vpopcntd', 'vpopcntq', 'vpopcntw',
	'vpor', 'vpord', 'vporq', 'vpperm', 'vprold',
	'vprolq', 'vprolvd', 'vprolvq', 'vprord', 'vprorq', 'vprorvd',
	'vprorvq','vprotb', 'vprotd', 'vprotq', 'vprotw',
	'vpsadbw', 'vpscatterdd', 'vpscatterdq', 'vpscatterqd',
	'vpscatterqq', 'vpshab', 'vpshad', 'vpshaq', 'vpshaw', 'vpshlb', 'vpshld',
	'vpshldd', 'vpshldq', 'vpshldvd', 'vpshldvq', 'vpshldvw', 'vpshldw', 'vpshlq',
	'vpshlw', 'vpshrdd', 'vpshrdq', 'vpshrdvd', 'vpshrdvq', 'vpshrdvw', 'vpshrdw',
	'vpshufb', 'vpshufbitqmb', 'vpshufd', 'vpshufhw', 'vpshuflw', 'vpsignb', 'vpsignd', 'vpsignw',
	'vpslld', 'vpslldq', 'vpsllq', 'vpsllvd', 'vpsllvq', 'vpsllvw', 'vpsllw', 'vpsrad', 'vpsraq', 'vpsravd',
	'vpsravq', 'vpsravw', 'vpsraw', 'vpsrld', 'vpsrldq', 'vpsrlq', 'vpsrlvd', 'vpsrlvq', 'vpsrlvw', 'vpsrlw',
	'vpsubb', 'vpsubd', 'vpsubq', 'vpsubsb', 'vpsubsw', 'vpsubusb',
	'vpsubusw', 'vpsubw', 'vpternlogd',
	'vpternlogq', 'vptest', 'vptestmb', 'vptestmd', 'vptestmq', 'vptestmw', 'vptestnmb', 'vptestnmd',
	'vptestnmq', 'vptestnmw', 'vpunpckhbw', 'vpunpckhdq', 'vpunpckhqdq', 'vpunpckhwd',
	'vpunpcklbw', 'vpunpckldq', 'vpunpcklqdq', 'vpunpcklwd', 'vpxor', 'vpxord',
	'vpxorq', 'vrangepd', 'vrangeps', 'vrangesd', 'vrangess',
	'vrcp14pd', 'vrcp14ps', 'vrcp14sd', 'vrcp14ss', 'vrcp28pd',
	'vrcp28ps', 'vrcp28sd', 'vrcp28ss', 'vrcpph', 'vrcpps', 'vrcpsh', 'vrcpss', 'vreducepd',
	'vreduceph', 'vreduceps', 'vreducesd', 'vreducesh', 'vreducess',
	'vrndscalepd', 'vrndscaleps', 'vrndscalesd', 'vrndscaless',
	'vroundpd', 'vroundps', 'vroundsd', 'vroundss', 'vrsqrt14pd',
	'vrsqrt14ps', 'vrsqrt14sd', 'vrsqrt14ss', 'vrsqrt28pd', 'vrsqrt28ps',
	'vrsqrt28sd', 'vrsqrt28ss', 'vrsqrtph', 'vrsqrtps', 'vrsqrtsh', 'vrsqrtss',
	'vscalefpd', 'vscalefph', 'vscalefps', 'vscalefsd', 'vscalefsh', 'vscalefss',
	'vscatterdpd', 'vscatterdps', 'vscatterpf0dpd',
	'vscatterpf0dps', 'vscatterpf0qpd', 'vscatterpf0qps', 'vscatterpf1dpd',
	'vscatterpf1dps', 'vscatterpf1qpd', 'vscatterpf1qps', 'vscatterqpd',
	'vscatterqps', 'vsha512msg1', 'vsha512msg2', 'vsha512rnds2',
	'vshuff32x4', 'vshuff64x2', 'vshufi32x4', 'vshufi64x2','vshufpd',
	'vshufps', 'vsm3msg1', 'vsm3msg2', 'vsm3rnds2', 'vsm4key4', 'vsm4rnds4',
	'vsqrtpd', 'vsqrtph', 'vsqrtps', 'vsqrtsd', 'vsqrtsh', 'vsqrtss', 'vstmxcsr', 'vsubpd',
	'vsubph', 'vsubps', 'vsubsd', 'vsubsh', 'vsubss',
	'vtestpd', 'vtestps', 'vucomisd', 'vucomish', 'vucomiss', 'vunpckhpd',
	'vunpckhps', 'vunpcklpd', 'vunpcklps', 'vxorpd', 'vxorps', 'vzeroall', 'vzeroupper',
	'wait', 'wbinvd', 'wbnoinvd', 'wrfsbase', 'wrgsbase', 'wrmsr', 'wrmsrlist', 'wrmsrns', 'wrmsrq', 'wrpkru',
	'wrssd', 'wrssq', 'wrussd', 'wrussq', 'wrshr', 'xabort',
	'xacquire', 'xadd', 'xbegin', 'xbts', 'xchg', 'xcryptcbc', 'xcryptcfb',
	'xcryptctr', 'xcryptecb', 'xcryptofb', 'xend', 'xgetbv', 'xlat', 'xlatb', 'xor', 'xorpd',
	'xorps', 'xrelease', 'xresldtrk', 'xrstor', 'xrstor64', 'xrstors', 'xrstors64', 'xsave', 'xsave64',
	'xsavec', 'xsavec64', 'xsaveopt', 'xsaveopt64', 'xsaves', 'xsaves64',
	'xsetbv', 'xsha1', 'xsha256', 'xstore', 'xsusldtrk', 'xtest'
 		);

# non-FPU instructions with suffixes in AT&T syntax
my @att_suff_instr = (
	'mov' , 'and' , 'or'  , 'not', 'xor', 'neg', 'cmp', 'add' ,
	'sub' , 'push', 'test', 'lea', 'pop', 'inc', 'dec', 'idiv',
	'imul', 'sbb' , 'sal' , 'shl', 'sar', 'shr'
		);

# NOTE: no fi* instructions here
my @att_suff_instr_fpu = (
	'fadd', 'faddp', 'fbld', 'fbstp',
	'fcom', 'fcomp', 'fcompp',
	'fcomi', 'fcomip', 'fdiv', 'fdivr', 'fdivp', 'fdivrp',
	'fld', 'fmul', 'fmulp', 'fndisi',
	'fst', 'fstp', 'fsub', 'fsubr', 'fsubp', 'fsubrp',
	'fucom', 'fucomp', 'fucompp', 'fucomi', 'fucomip'
		);

=head2 @instr_att

 A list of all x86 instructions (as strings) in AT&T syntax.

=cut

our @instr_att = add_att_suffix_instr @instr_intel;

=head2 @instr

 A list of all x86 instructions (as strings) in Intel and AT&T syntax.

=cut

# concatenating the lists can create unnecessary duplicate entries, so remove them
our @instr = _remove_duplicates (@instr_intel, @instr_att);

=head1 FUNCTIONS

=head2 is_reg_intel

 Checks if the given string parameter is a valid x86 register (any size) in Intel syntax.
 Returns 1 if yes.

=cut

sub is_reg_intel($) {
	return _is_in_array (shift, \@regs_intel);
}

=head2 is_reg_att

 Checks if the given string parameter is a valid x86 register (any size) in AT&T syntax.
 Returns 1 if yes.

=cut

sub is_reg_att($) {
	return _is_in_array_att (shift, \@regs_att);
}

=head2 is_reg

 Checks if the given string parameter is a valid x86 register (any size).
 Returns 1 if yes.

=cut

sub is_reg($) {
	my $elem = shift;
	return is_reg_intel ($elem) | is_reg_att ($elem);
}

=head2 is_reg8_intel

 Checks if the given string parameter is a valid x86 8-bit register in Intel syntax.
 Returns 1 if yes.

=cut

sub is_reg8_intel($) {
	return _is_in_array (shift, \@regs8_intel);
}

=head2 is_reg8_att

 Checks if the given string parameter is a valid x86 8-bit register in AT&T syntax.
 Returns 1 if yes.

=cut

sub is_reg8_att($) {
	return _is_in_array_att (shift, \@regs8_att);
}

=head2 is_reg8

 Checks if the given string parameter is a valid x86 8-bit register.
 Returns 1 if yes.

=cut

sub is_reg8($) {
	my $elem = shift;
	return is_reg8_intel ($elem) | is_reg8_att ($elem);
}

=head2 is_reg16_intel

 Checks if the given string parameter is a valid x86 16-bit register in Intel syntax.
 Returns 1 if yes.

=cut

sub is_reg16_intel($) {
	return _is_in_array (shift, \@regs16_intel);
}

=head2 is_reg16_att

 Checks if the given string parameter is a valid x86 16-bit register in AT&T syntax.
 Returns 1 if yes.

=cut

sub is_reg16_att($) {
	return _is_in_array_att (shift, \@regs16_att);
}

=head2 is_reg16

 Checks if the given string parameter is a valid x86 16-bit register.
 Returns 1 if yes.

=cut

sub is_reg16($) {
	my $elem = shift;
	return is_reg16_intel ($elem) | is_reg16_att ($elem);
}

=head2 is_segreg_intel

 Checks if the given string parameter is a valid x86 segment register in Intel syntax.
 Returns 1 if yes.

=cut

sub is_segreg_intel($) {
	return _is_in_array (shift, \@segregs_intel);
}

=head2 is_segreg_att

 Checks if the given string parameter is a valid x86 segment register in AT&T syntax.
 Returns 1 if yes.

=cut

sub is_segreg_att($) {
	return _is_in_array_att (shift, \@segregs_att);
}

=head2 is_segreg

 Checks if the given string parameter is a valid x86 segment register.
 Returns 1 if yes.

=cut

sub is_segreg($) {
	my $elem = shift;
	return is_segreg_intel ($elem) | is_segreg_att ($elem);
}

=head2 is_reg32_intel

 Checks if the given string parameter is a valid x86 32-bit register in Intel syntax.
 Returns 1 if yes.

=cut

sub is_reg32_intel($) {
	return _is_in_array (shift, \@regs32_intel);
}

=head2 is_reg32_att

 Checks if the given string parameter is a valid x86 32-bit register in AT&T syntax.
 Returns 1 if yes.

=cut

sub is_reg32_att($) {
	return _is_in_array_att (shift, \@regs32_att);
}

=head2 is_reg32

 Checks if the given string parameter is a valid x86 32-bit register.
 Returns 1 if yes.

=cut

sub is_reg32($) {
	my $elem = shift;
	return is_reg32_intel ($elem) | is_reg32_att ($elem);
}

=head2 is_addressable32_intel

 Checks if the given string parameter is a valid x86 32-bit register which can be used
 	for addressing in Intel syntax.
 Returns 1 if yes.

=cut

sub is_addressable32_intel($) {
	return _is_in_array (shift, \@addressable32);
}

=head2 is_addressable32_att

 Checks if the given string parameter is a valid x86 32-bit register which can be used
 	for addressing in AT&T syntax.
 Returns 1 if yes.

=cut

sub is_addressable32_att($) {
	return _is_in_array_att (shift, \@addressable32_att);
}

=head2 is_addressable32

 Checks if the given string parameter is a valid x86 32-bit register which can be used
 	for addressing.
 Returns 1 if yes.

=cut

sub is_addressable32($) {
	my $elem = shift;
	return is_addressable32_intel ($elem) | is_addressable32_att ($elem);
}

=head2 is_r32_in64_intel

 Checks if the given string parameter is a valid x86 32-bit register which can only be used
 	in 64-bit mode (that is, checks if the given string parameter is a 32-bit
 	subregister of a 64-bit register).
 Returns 1 if yes.

=cut

sub is_r32_in64_intel($) {
	return _is_in_array (shift, \@r32_in64);
}

=head2 is_r32_in64_att

 Checks if the given string parameter is a valid x86 32-bit register in Intel syntax
 	which can only be used in 64-bit mode (that is, checks if the given string
 	parameter is a 32-bit subregister of a 64-bit register).
 Returns 1 if yes.

=cut

sub is_r32_in64_att($) {
	return _is_in_array_att (shift, \@r32_in64_att);
}

=head2 is_r32_in64

 Checks if the given string parameter is a valid x86 32-bit register in AT&T syntax
 	which can only be used in 64-bit mode (that is, checks if the given string
 	parameter is a 32-bit subregister of a 64-bit register).
 Returns 1 if yes.

=cut

sub is_r32_in64($) {
	my $elem = shift;
	return is_r32_in64_intel ($elem) | is_r32_in64_att ($elem);
}

=head2 is_reg64_intel

 Checks if the given string parameter is a valid x86 64-bit register in Intel syntax.
 Returns 1 if yes.

=cut

sub is_reg64_intel($) {
	return _is_in_array (shift, \@regs64_intel);
}

=head2 is_reg64_att

 Checks if the given string parameter is a valid x86 64-bit register in AT&T syntax.
 Returns 1 if yes.

=cut

sub is_reg64_att($) {
	return _is_in_array_att (shift, \@regs64_att);
}

=head2 is_reg64

 Checks if the given string parameter is a valid x86 64-bit register.
 Returns 1 if yes.

=cut

sub is_reg64($) {
	my $elem = shift;
	return is_reg64_intel ($elem) | is_reg64_att ($elem);
}

=head2 is_reg_mm_intel

 Checks if the given string parameter is a valid x86 multimedia (MMX/3DNow!/SSEn)
 	register in Intel syntax.
 Returns 1 if yes.

=cut

sub is_reg_mm_intel($) {
	return _is_in_array (shift, \@regs_mm_intel);
}

=head2 is_reg_mm_att

 Checks if the given string parameter is a valid x86 multimedia (MMX/3DNow!/SSEn)
 	register in AT&T syntax.
 Returns 1 if yes.

=cut

sub is_reg_mm_att($) {
	return _is_in_array_att (shift, \@regs_mm_att);
}

=head2 is_reg_mm

 Checks if the given string parameter is a valid x86 multimedia (MMX/3DNow!/SSEn) register.
 Returns 1 if yes.

=cut

sub is_reg_mm($) {
	my $elem = shift;
	return is_reg_mm_intel ($elem) | is_reg_mm_att ($elem);
}

=head2 is_reg_fpu_intel

 Checks if the given string parameter is a valid x86 FPU register in Intel syntax.
 Returns 1 if yes.

=cut

sub is_reg_fpu_intel($) {
	return _is_in_array (shift, \@regs_fpu_intel);
}

=head2 is_reg_fpu_att

 Checks if the given string parameter is a valid x86 FPU register in AT&T syntax.
 Returns 1 if yes.

=cut

sub is_reg_fpu_att($) {
	return _is_in_array_att (shift, \@regs_fpu_att);
}

=head2 is_reg_fpu

 Checks if the given string parameter is a valid x86 FPU register.
 Returns 1 if yes.

=cut

sub is_reg_fpu($) {
	my $elem = shift;
	return is_reg_fpu_intel ($elem) | is_reg_fpu_att ($elem);
}

=head2 is_reg_opmask_intel

 Checks if the given string parameter is a valid x86 opmask register in Intel syntax.
 Returns 1 if yes.

=cut

sub is_reg_opmask_intel($) {
	return _is_in_array (shift, \@regs_opmask_intel);
}

=head2 is_reg_opmask_att

 Checks if the given string parameter is a valid x86 opmask register in AT&T syntax.
 Returns 1 if yes.

=cut

sub is_reg_opmask_att($) {
	return _is_in_array_att (shift, \@regs_opmask_att);
}

=head2 is_reg_opmask

 Checks if the given string parameter is a valid x86 opmask register.
 Returns 1 if yes.

=cut

sub is_reg_opmask($) {
	my $elem = shift;
	return is_reg_opmask_intel ($elem) | is_reg_opmask_att ($elem);
}

=head2 is_reg_bound_intel

 Checks if the given string parameter is a valid x86 bound register in Intel syntax.
 Returns 1 if yes.

=cut

sub is_reg_bound_intel($) {
	return _is_in_array (shift, \@regs_bound_intel);
}

=head2 is_reg_bound_att

 Checks if the given string parameter is a valid x86 bound register in AT&T syntax.
 Returns 1 if yes.

=cut

sub is_reg_bound_att($) {
	return _is_in_array_att (shift, \@regs_bound_att);
}

=head2 is_reg_bound

 Checks if the given string parameter is a valid x86 bound register.
 Returns 1 if yes.

=cut

sub is_reg_bound($) {
	my $elem = shift;
	return is_reg_bound_intel ($elem) | is_reg_bound_att ($elem);
}

=head2 is_instr_intel

 Checks if the given string parameter is a valid x86 instruction in Intel syntax.
 Returns 1 if yes.

=cut

sub is_instr_intel($) {
	return _is_in_array (shift, \@instr_intel);
}

=head2 is_instr_att

 Checks if the given string parameter is a valid x86 instruction in AT&T syntax.
 Returns 1 if yes.

=cut

sub is_instr_att($) {
	return _is_in_array (shift, \@instr_att);
}

=head2 is_instr

 Checks if the given string parameter is a valid x86 instruction in any syntax.
 Returns 1 if yes.

=cut

sub is_instr($) {
	my $elem = shift;
	return is_instr_intel ($elem) | is_instr_att ($elem);
}

##############################################################################

# =head2 _is_valid_16bit_addr_reg_intel
#
#  PRIVATE SUBROUTINE.
#  Checks if the given register can be used in x86 16-bit addressing
#   mode in Intel syntax.
#  Returns 1 if yes.
#
# =cut
#
sub _is_valid_16bit_addr_reg_intel($) {

	my $reg = shift;
	return 1 if $reg =~ /^bx$/io || $reg =~ /^bp$/io
		||  $reg =~ /^si$/io || $reg =~ /^di$/io;
	return 0;
}

# =head2 _is_same_type_16bit_addr_reg_intel
#
#  PRIVATE SUBROUTINE.
#  Checks if the 2 given registers cannot be used in x86 16-bit addressing
#   mode in Intel syntax at the same time because they're of the same type.
#  Returns 1 if yes.
#
# =cut
#
sub _is_same_type_16bit_addr_reg_intel($$) {

	my $reg1 = shift;
	my $reg2 = shift;
	return 1 if ($reg1 =~ /^b.$/io && $reg2 =~ /^b.$/io)
		||  ($reg1 =~ /^.i$/io && $reg2 =~ /^.i$/io);
	return 0;
}

# =head2 _validate_16bit_addr_parts_intel
#
#  PRIVATE SUBROUTINE.
#  Checks if the given address components give a valid x86 32-bit addressing
#   mode in Intel syntax.
#  Returns 1 if yes.
#
# =cut
#
sub _validate_16bit_addr_parts_intel($$$$$$$) {

	my $seg_reg = shift;
	my $reg1_sign = shift;
	my $reg1 = shift;
	my $reg2_sign = shift;
	my $reg2 = shift;
	my $disp_sign = shift;
	my $disp = shift;

	return 0 if defined $seg_reg && ! is_segreg_intel($seg_reg);
	return 0 if #defined $reg1 && # always defined
		is_reg_intel($reg1)
		&& (! _is_valid_16bit_addr_reg_intel ($reg1));
	return 0 if defined $reg2 && is_reg_intel($reg2)
		&& (! _is_valid_16bit_addr_reg_intel ($reg2));
	return 0 if defined $disp && is_reg_intel($disp)
		&& (! _is_valid_16bit_addr_reg_intel ($disp));

	return 0 if #defined $reg1 && defined $reg1_sign && # always defined
		is_reg_intel($reg1) && $reg1_sign =~ /-/o;
	return 0 if defined $reg2 #&& defined $reg2_sign # always defined if $reg2 is defined
		&& is_reg_intel($reg2) && $reg2_sign =~ /-/o;
	return 0 if defined $disp #&& defined $disp_sign # always defined if $disp is defined
		&& is_reg_intel($disp) && $disp_sign =~ /-/o;
	return 0 if # defined $reg1 && # always defined
		defined $reg2 && defined $disp
		&& is_reg_intel($reg1) && is_reg_intel($reg2) && is_reg_intel($disp);

	if ( #defined $reg1 && # always defined
		is_reg16_intel($reg1) ) {

		# taken care of above:
		#return 0 if #defined $reg1_sign && # always defined
		#	$reg1_sign =~ /-/o;
		# must be one of predefined registers
		# taken care of above:
		#if ( _is_valid_16bit_addr_reg_intel ($reg1) ) {

			if ( defined $reg2 && is_reg16_intel($reg2) ) {

				return 0 if _is_same_type_16bit_addr_reg_intel ($reg1, $reg2);
				# taken care of above:
				#return 0 if #defined $reg2_sign && # always defined if $reg2 is defined
				#	$reg2_sign =~ /-/o;
				# 3 registers - case already taken care of:
				#return 0 if defined $disp && is_reg_intel($disp);

				# must be one of predefined registers
				# taken care of above:
				#return 1 if _is_valid_16bit_addr_reg_intel ($reg2)
					#&& $reg2 !~ /\b$reg1\b/i	# already checked
				#	;
				return 1;

			} elsif ( defined $disp && is_reg16_intel($disp) ) {

				return 0 if _is_same_type_16bit_addr_reg_intel ($reg1, $disp);
				# taken care of above:
				#return 0 if #defined $disp_sign && # always defined if $disp is defined
				#	$disp_sign =~ /-/o;

				# must be one of predefined registers
				# taken care of above:
				#return 1 if _is_valid_16bit_addr_reg_intel ($disp)
					#&& $disp !~ /\b$reg1\b/i	# already checked
					#&& ! is_reg_intel($reg2)	# already checked
				#	;
				return 1;
			} else {
				# variable/number/constant is OK
				return 1;
			}
		#}
		#return 0;
	} else {
		if ( defined $reg2 && is_reg16_intel($reg2) ) {

			# taken care of above:
			#return 0 if #defined $reg2_sign && # always defined if $reg2 is defined
			#	$reg2_sign =~ /-/o;
			# must be one of predefined registers
			# taken care of above:
			#if ( _is_valid_16bit_addr_reg_intel ($reg2) ) {

				if ( defined $disp && is_reg16_intel($disp) ) {

					return 0 if _is_same_type_16bit_addr_reg_intel ($disp, $reg2);
					# taken care of above:
					#return 0 if #defined $disp_sign && # always defined if $disp is defined
					#	$disp_sign =~ /-/o;

					# must be one of predefined registers
					# taken care of above:
					#return 1 if _is_valid_16bit_addr_reg_intel ($disp)
						#&& $disp !~ /\b$reg2\b/i	# already checked
					#	;
					return 1;
				} else {
					# variable/number/constant is OK
					return 1;
				}
			#}
			#return 0;
		} else {
			# already checked above:
			#return 0 if defined $disp #&& defined $disp_sign # always defined if $disp is defined
			#	&& is_reg16_intel($disp) && $disp_sign =~ /-/o;
			# variable/number/constant is OK
			return 1;
		}
	}
}

=head2 is_valid_16bit_addr_intel

 Checks if the given string parameter (must contain the square braces)
  is a valid x86 16-bit addressing mode in Intel syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns 1 if yes.

=cut

sub is_valid_16bit_addr_intel($) {

	my $elem = shift;
	if ( $elem =~ /^(\w+):\s*\[\s*([\+\-]*)\s*(\w+)\s*\]$/o
		|| $elem =~ /^\[\s*(\w+)\s*:\s*([\+\-]*)\s*(\w+)\s*\]$/o ) {

		return _validate_16bit_addr_parts_intel ($1, $2, $3, undef, undef, undef, undef);
	}
	elsif ( $elem =~ /^(\w+):\s*\[\s*([\+\-]*)\s*(\w+)\s*([\+\-]+)\s*(\w+)\s*\]$/o
		|| $elem =~ /^\[\s*(\w+)\s*:\s*([\+\-]*)\s*(\w+)\s*([\+\-]+)\s*(\w+)\s*\]$/o ) {

		return _validate_16bit_addr_parts_intel ($1, $2, $3, $4, $5, undef, undef);
	}
	elsif ( $elem =~ /^(\w+):\s*\[\s*([\+\-]*)\s*(\w+)\s*([\+\-]+)\s*(\w+)\s*([\+\-]+)\s*(\w+)\s*\]$/o
		|| $elem =~ /^\[\s*(\w+)\s*:\s*([\+\-]*)\s*(\w+)\s*([\+\-]+)\s*(\w+)\s*([\+\-]+)\s*(\w+)\s*\]$/o ) {

		return _validate_16bit_addr_parts_intel ($1, $2, $3, $4, $5, $6, $7);
	}
	elsif ( $elem =~ /^\[\s*([\+\-]*)\s*(\w+)\s*\]$/o ) {

		return _validate_16bit_addr_parts_intel (undef, $1, $2, undef, undef, undef, undef);
	}
	elsif ( $elem =~ /^\[\s*([\+\-]*)\s*(\w+)\s*([\+\-]+)\s*(\w+)\s*\]$/o ) {

		return _validate_16bit_addr_parts_intel (undef, $1, $2, $3, $4, undef, undef);
	}
	elsif ( $elem =~ /^\[\s*([\+\-]*)\s*(\w+)\s*([\+\-]+)\s*(\w+)\s*([\+\-]+)\s*(\w+)\s*\]$/o ) {

		return _validate_16bit_addr_parts_intel (undef, $1, $2, $3, $4, $5, $6);
	}
	return 0;
}

# =head2 _is_valid_16bit_addr_reg_att
#
#  PRIVATE SUBROUTINE.
#  Checks if the given register can be used in x86 16-bit addressing
#   mode in AT&T syntax.
#  Returns 1 if yes.
#
# =cut
#
sub _is_valid_16bit_addr_reg_att($) {

	my $reg = shift;
	return 1 if $reg =~ /^%bx$/io || $reg =~ /^%bp$/io
		||  $reg =~ /^%si$/io || $reg =~ /^%di$/io;
	return 0;
}

# =head2 _is_same_type_16bit_addr_reg_att
#
#  PRIVATE SUBROUTINE.
#  Checks if the 2 given registers cannot be used in x86 16-bit addressing
#   mode in AT&T syntax at the same time because they're of the same type.
#  Returns 1 if yes.
#
# =cut
#
sub _is_same_type_16bit_addr_reg_att($$) {

	my $reg1 = shift;
	my $reg2 = shift;
	return 1 if ($reg1 =~ /^%b.$/io && $reg2 =~ /^%b.$/io)
		||  ($reg1 =~ /^%.i$/io && $reg2 =~ /^%.i$/io);
	return 0;
}

# =head2 _validate_16bit_addr_parts_att
#
#  PRIVATE SUBROUTINE.
#  Checks if the given address components give a valid x86 32-bit addressing
#   mode in AT&T syntax.
#  Returns 1 if yes.
#
# =cut
#
sub _validate_16bit_addr_parts_att($$$$$$) {

	my $seg_reg = shift;
	#my $base_reg_sign = shift; # not allowed in the syntax at all
	my $base_reg = shift;
	#my $index_reg_sign = shift; # not allowed in the syntax at all
	my $index_reg = shift;
	my $scale = shift;
	my $disp_sign = shift;
	my $disp = shift;

	return 0 if defined $seg_reg && ! is_segreg_att($seg_reg);
	if ( defined $base_reg ) {
		return 0 if $base_reg =~ /%/o && ! is_reg16_att($base_reg);
		return 0 if is_reg_att($base_reg) && ! _is_valid_16bit_addr_reg_att ($base_reg);
		return 0 if defined $disp && ! is_reg_att($base_reg); # disallow 'var(var)'
	}
	if ( defined $index_reg ) {
		return 0 if $index_reg =~ /%/o && ! is_reg16_att($index_reg);
		return 0 if is_reg_att($index_reg) && ! _is_valid_16bit_addr_reg_att ($index_reg);
		# '(, index, scale)' is not allowed in 16-bit addresses and eliminated by regexes,
		# so $scale should not be defined here
		if ( ! defined $base_reg #&& ! defined $scale
		) {
			# just one value inside - check for "(,1)"
			return 0 if $index_reg ne '1' || is_reg_att($disp);
		}
	}
	return 0 if defined $disp && is_reg_att($disp);
	return 0 if defined $scale && $scale ne '1';
	if ( defined $base_reg && defined $index_reg ) {

		return 0 if ! _is_valid_16bit_addr_reg_att($base_reg)
			|| ! _is_valid_16bit_addr_reg_att($index_reg);
		return 0 if _is_same_type_16bit_addr_reg_att ($base_reg, $index_reg);
	}
	#return 0 if defined $base_reg #&& defined $base_reg_sign
	#	&& is_reg_att($base_reg);# && $base_reg_sign =~ /-/o;
	#return 0 if defined $index_reg #&& defined $index_reg_sign
	#	&& is_reg_att($index_reg);# && $index_reg_sign =~ /-/o;

	return 1;
}

=head2 is_valid_16bit_addr_att

 Checks if the given string parameter (must contain the parentheses)
  is a valid x86 16-bit addressing mode in AT&T syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns 1 if yes.

=cut

sub is_valid_16bit_addr_att($) {

	my $elem = shift;
	if ( $elem =~ /^([%\w]+):\s*\(\s*([%\w]+)\s*\)$/o ) {

		return _validate_16bit_addr_parts_att ($1, $2, undef, undef, undef, undef);
	}
	elsif ( $elem =~ /^([%\w]+):\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*\)$/ ) {

		return _validate_16bit_addr_parts_att ($1, $2, $3, undef, undef, undef);
	}
	elsif ( $elem =~ /^([%\w]+):\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_16bit_addr_parts_att ($1, $2, $3, $4, undef, undef);
	}
	elsif ( $elem =~ /^([%\w]+):\s*\(\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		# '(, index, scale)' not in 16-bit addresses
		return 0;
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*\)$/o ) {

		return _validate_16bit_addr_parts_att ($1, $4, undef, undef, $2, $3);
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_16bit_addr_parts_att ($1, $4, $5, undef, $2, $3);
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_16bit_addr_parts_att ($1, $4, $5, $6, $2, $3);
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		# 'disp(, index, scale)' not in 16-bit addresses
		return 0;
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_16bit_addr_parts_att ($1, undef, $4, undef, $2, $3);
	}
	elsif ( $elem =~ /^\(\s*([%\w]+)\s*\)$/o ) {

		return _validate_16bit_addr_parts_att (undef, $1, undef, undef, undef, undef);
	}
	elsif ( $elem =~ /^\(\s*([%\w]+)\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_16bit_addr_parts_att (undef, $1, $2, undef, undef, undef);
	}
	elsif ( $elem =~ /^\(\s*([%\w]+)\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_16bit_addr_parts_att (undef, $1, $2, $3, undef, undef);
	}
	elsif ( $elem =~ /^\(\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		# '(, index, scale)' not in 16-bit addresses
		return 0;
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*\)$/o ) {

		return _validate_16bit_addr_parts_att (undef, $3, undef, undef, $1, $2);
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_16bit_addr_parts_att (undef, $3, $4, undef, $1, $2);
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_16bit_addr_parts_att (undef, $3, $4, $5, $1, $2);
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		# 'disp(, index, scale)' not in 16-bit addresses
		return 0;
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_16bit_addr_parts_att (undef, undef, $3, undef, $1, $2);
	}
	return 0;
}

=head2 is_valid_16bit_addr

 Checks if the given string parameter (must contain the parentheses)
  is a valid x86 16-bit addressing mode in AT&T or Intel syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns 1 if yes.

=cut

sub is_valid_16bit_addr($) {

	my $elem = shift;
	return    is_valid_16bit_addr_intel ($elem)
		| is_valid_16bit_addr_att ($elem);
}

# =head2 _validate_32bit_addr_parts_intel
#
#  PRIVATE SUBROUTINE.
#  Checks if the given address components give a valid x86 32-bit addressing
#   mode in Intel syntax.
#  Returns 1 if yes.
#
# =cut
sub _validate_32bit_addr_parts_intel($$$$$$$$) {

	my $seg_reg = shift;
	my $base_reg_sign = shift;
	my $base_reg = shift;
	my $index_reg_sign = shift;
	my $index_reg = shift;
	my $scale = shift;
	my $disp_sign = shift;
	my $disp = shift;

	return 0 if defined $seg_reg && ! is_segreg_intel($seg_reg);
	return 0 if defined $base_reg && is_reg_intel($base_reg) && ! is_addressable32_intel($base_reg);
	return 0 if defined $index_reg && is_reg_intel($index_reg) && ! is_addressable32_intel($index_reg);
	return 0 if defined $scale && is_reg_intel($scale) && ! is_addressable32_intel($scale);
	return 0 if defined $disp && is_reg_intel($disp) && ! is_addressable32_intel($disp);

	return 0 if defined $index_reg && defined $scale
		&& is_reg_intel($index_reg) && is_reg_intel($scale);
	return 0 if defined $base_reg #&& defined $base_reg_sign # always defined if $base_reg is defined
		&& is_reg_intel($base_reg) && $base_reg_sign =~ /-/o;
	return 0 if defined $index_reg #&& defined $index_reg_sign # always defined if $index_reg is defined
		&& is_reg_intel($index_reg) && $index_reg_sign =~ /-/o;
	return 0 if defined $scale #&& defined $index_reg_sign # always defined if we have enough parts to form a $scale
		&& is_reg_intel($scale) && $index_reg_sign =~ /-/o;
	return 0 if defined $disp #&& defined $disp_sign # always defined if $disp is defined
		&& is_reg_intel($disp) && $disp_sign =~ /-/o;

	if ( defined $index_reg && defined $scale ) {

		return 0 if $index_reg =~ /\besp\b/io && $scale =~ /\b\d+\b/o && $scale ne '1';
		return 0 if $scale =~ /\besp\b/io && $index_reg =~ /\b\d+\b/o && $index_reg ne '1';
		return 0 if is_reg_intel($index_reg) && $scale =~ /\b\d+\b/o && $scale ne '1'
			&& $scale ne '2' && $scale ne '4' && $scale ne '8';
		return 0 if is_reg_intel($scale) && $index_reg =~ /\b\d+\b/o && $index_reg ne '1'
			&& $index_reg ne '2' && $index_reg ne '4' && $index_reg ne '8';
	}
	return 0 if defined $base_reg && defined $index_reg && defined $disp
		&& is_reg_intel($base_reg) && is_reg_intel($index_reg) && is_reg_intel($disp);
	return 0 if defined $base_reg && defined $scale && defined $disp
		&& is_reg_intel($base_reg) && is_reg_intel($scale) && is_reg_intel($disp);

	return 1;
}

=head2 is_valid_32bit_addr_intel

 Checks if the given string parameter (must contain the square braces)
  is a valid x86 32-bit addressing mode in Intel syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns 1 if yes.

=cut

sub is_valid_32bit_addr_intel($) {

	my $elem = shift;
	# [seg:base+index*scale+disp]
	if (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_32bit_addr_parts_intel ($1, $2, $3, $4, $5, $6, $7, $8);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_32bit_addr_parts_intel ($1, $2, $3, $6, $7, $8, $4, $5);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_32bit_addr_parts_intel ($1, $5, $6, $2, $3, $4, $7, $8);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_32bit_addr_parts_intel ($1, undef, undef, $2, $3, $4, $5, $6);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_32bit_addr_parts_intel ($1, $2, $3, $4, $5, undef, $6, $7);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_32bit_addr_parts_intel ($1, $2, $3, $4, $5, $6, undef, undef);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*\]$/o) {

		return _validate_32bit_addr_parts_intel ($1, $2, $3, undef, undef, undef, undef, undef);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_32bit_addr_parts_intel ($1, undef, undef, $2, $3, $4, undef, undef);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]*)\s*(\w+)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]*)\s*(\w+)\s*\]$/o) {

		return _validate_32bit_addr_parts_intel ($1, $2, $3, undef, undef, undef, $4, $5);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_32bit_addr_parts_intel (undef, $1, $2, $3, $4, $5, $6, $7);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_32bit_addr_parts_intel (undef, $1, $2, $5, $6, $7, $3, $4);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_32bit_addr_parts_intel (undef, $4, $5, $1, $2, $3, $6, $7);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_32bit_addr_parts_intel (undef, undef, undef, $1, $2, $3, $4, $5);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_32bit_addr_parts_intel (undef, $1, $2, $3, $4, undef, $5, $6);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_32bit_addr_parts_intel (undef, $1, $2, $3, $4, $5, undef, undef);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*\]$/o ) {

		return _validate_32bit_addr_parts_intel (undef, $1, $2, undef, undef, undef, undef, undef);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_32bit_addr_parts_intel (undef, undef, undef, $1, $2, $3, undef, undef);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]*)\s*(\w+)\s*\]$/o ) {

		return _validate_32bit_addr_parts_intel (undef, $1, $2, undef, undef, undef, $3, $4);
	}
	return 0;
}

# =head2 _validate_32bit_addr_parts_att
#
#  PRIVATE SUBROUTINE.
#  Checks if the given address components give a valid x86 32-bit addressing
#   mode in AT&T syntax.
#  Returns 1 if yes.
#
# =cut
sub _validate_32bit_addr_parts_att($$$$$$) {

	my $seg_reg = shift;
	#my $base_reg_sign = shift; # not allowed in the syntax at all
	my $base_reg = shift;
	#my $index_reg_sign = shift; # not allowed in the syntax at all
	my $index_reg = shift;
	my $scale = shift;
	my $disp_sign = shift;
	my $disp = shift;

	return 0 if defined $seg_reg && ! is_segreg_att ($seg_reg);
	if ( defined $index_reg && ! defined $base_reg && ! defined $scale ) {
		# just one value inside - check for "(,1)"
		return 1 if $index_reg eq '1' && ! is_reg_att($disp);
	}
	return 0 if defined $index_reg && (! is_reg_att($index_reg)
		|| ! is_addressable32_att($index_reg) || $index_reg =~ /^%esp$/io);
	return 0 if defined $scale #&& ! is_reg_att($scale) # regexed out to be just digits in is_valid_32bit_addr_att()
		&& $scale ne '1' && $scale ne '2' && $scale ne '4' && $scale ne '8';
	return 0 if defined $disp && is_reg_att($disp);
	if ( defined $base_reg && ! defined $index_reg #&& ! defined $scale # no index reg - no scale in is_valid_32bit_addr_att()
	) {
		# just one value inside - allow '(var)' and 'var(%reg)', disallow 'var(var)'
		return 0 if ( (defined $disp || $base_reg =~ /%/o)
			&& ! is_addressable32_att($base_reg)
			&& $base_reg !~ /^%bx$/io && $base_reg !~ /^%bp$/io
			&& $base_reg !~ /^%si$/io && $base_reg !~ /^%di$/io);
			#|| (defined $base_reg_sign && $base_reg_sign =~ /-/o);
	} else {
		# more than one part - must be a 32-bit register
		return 0 if defined $base_reg && ! is_addressable32_att($base_reg);
	}
	return 1;
}

=head2 is_valid_32bit_addr_att

 Checks if the given string parameter (must contain the parentheses)
  is a valid x86 32-bit addressing mode in AT&T syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns 1 if yes.

=cut

sub is_valid_32bit_addr_att($) {

	my $elem = shift;
	if ( $elem =~ /^([%\w]+):\s*\(\s*([%\w]+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att ($1, $2, undef, undef, undef, undef);
	}
	elsif ( $elem =~ /^([%\w]+):\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att ($1, $2, $3, undef, undef, undef);
	}
	elsif ( $elem =~ /^([%\w]+):\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att ($1, $2, $3, $4, undef, undef);
	}
	elsif ( $elem =~ /^([%\w]+):\s*\(\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att ($1, undef, $2, $3, undef, undef);
	}
	elsif ( $elem =~ /^([%\w]+):\s*\(\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att ($1, undef, $2, undef, undef, undef);
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att ($1, $4, undef, undef, $2, $3);
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att ($1, $4, $5, undef, $2, $3);
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att ($1, $4, $5, $6, $2, $3);
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att ($1, undef, $4, $5, $2, $3);
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att ($1, undef, $4, undef, $2, $3);
	}
	elsif ( $elem =~ /^\(\s*([%\w]+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att (undef, $1, undef, undef, undef, undef);
	}
	elsif ( $elem =~ /^\(\s*([%\w]+)\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att (undef, $1, $2, undef, undef, undef);
	}
	elsif ( $elem =~ /^\(\s*([%\w]+)\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att (undef, $1, $2, $3, undef, undef);
	}
	elsif ( $elem =~ /^\(\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att (undef, undef, $1, $2, undef, undef);
	}
	elsif ( $elem =~ /^\(\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att (undef, undef, $1, undef, undef, undef);
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att (undef, $3, undef, undef, $1, $2);
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att (undef, $3, $4, undef, $1, $2);
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att (undef, $3, $4, $5, $1, $2);
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att (undef, undef, $3, $4, $1, $2);
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_32bit_addr_parts_att (undef, undef, $3, undef, $1, $2);
	}
	return 0;
}

=head2 is_valid_32bit_addr

 Checks if the given string parameter (must contain the parentheses)
  is a valid x86 32-bit addressing mode in AT&T or Intel syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns 1 if yes.

=cut

sub is_valid_32bit_addr($) {

	my $elem = shift;
	return    is_valid_32bit_addr_intel ($elem)
		| is_valid_32bit_addr_att ($elem);
}

# =head2 _is_valid_64bit_addr_reg_att
#
#  PRIVATE SUBROUTINE.
#  Checks if the given register can be used in x86 64-bit addressing
#   mode in Intel syntax.
#  Returns 1 if yes.
#
# =cut
#
sub _is_valid_64bit_addr_reg_intel($) {

	my $reg = shift;
	return 1 if is_reg64_intel($reg) || is_r32_in64_intel($reg) || is_addressable32_intel($reg);
	return 0;
}

# =head2 _validate_64bit_addr_parts_intel
#
#  PRIVATE SUBROUTINE.
#  Checks if the given address components give a valid x86 64-bit addressing
#   mode in Intel syntax.
#  Returns 1 if yes.
#
# =cut
sub _validate_64bit_addr_parts_intel($$$$$$$$) {

	my $seg_reg = shift;
	my $base_reg_sign = shift;
	my $base_reg = shift;
	my $index_reg_sign = shift;
	my $index_reg = shift;
	my $scale = shift;
	my $disp_sign = shift;
	my $disp = shift;
	my $was64 = 0;
	my $nregs = 0;

	return 0 if defined $seg_reg && ! is_segreg_intel($seg_reg);
	if ( defined $base_reg && is_reg_intel($base_reg) ) {

		return 0 if ! _is_valid_64bit_addr_reg_intel($base_reg);
		$nregs++;
		$was64++ if is_reg64_intel($base_reg);
	}
	if ( defined $index_reg && is_reg_intel($index_reg) ) {

		return 0 if ! _is_valid_64bit_addr_reg_intel($index_reg);
		$nregs++;
		$was64++ if is_reg64_intel($index_reg);
	}
	if ( defined $scale && is_reg_intel($scale) ) {

		return 0 if ! _is_valid_64bit_addr_reg_intel($scale);
		$nregs++;
		$was64++ if is_reg64_intel($scale);
	}
	if ( defined $disp && is_reg_intel($disp) ) {

		return 0 if ! _is_valid_64bit_addr_reg_intel($disp);
		$nregs++;
		$was64++ if is_reg64_intel($disp);
	}
	return 0 if $was64 != 0 && $was64 != $nregs;

	return 0 if defined $index_reg && defined $scale
		&& is_reg_intel($index_reg) && is_reg_intel($scale);
	return 0 if defined $base_reg #&& defined $base_reg_sign # always defined if $base_reg is defined
		&& is_reg_intel($base_reg) && $base_reg_sign =~ /-/o;
	return 0 if defined $index_reg #&& defined $index_reg_sign # always defined if $index_reg is defined
		&& is_reg_intel($index_reg) && $index_reg_sign =~ /-/o;
	return 0 if defined $scale #&& defined $index_reg_sign # always defined if we have enough parts to form a $scale
		&& is_reg_intel($scale) && $index_reg_sign =~ /-/o;
	return 0 if defined $disp #&& defined $disp_sign # always defined if $disp is defined
		&& is_reg_intel($disp) && $disp_sign =~ /-/o;
	if ( defined $index_reg && defined $scale ) {
		return 0 if ( $index_reg =~ /\brsp\b/io || $index_reg =~ /\brip\b/io )
			&& $scale =~ /\b\d+\b/o && $scale ne '1';
		return 0 if ( $scale     =~ /\brsp\b/io || $scale     =~ /\brip\b/io )
			&& $index_reg =~ /\b\d+\b/o && $index_reg ne '1';
		return 0 if is_reg_intel($index_reg) && $scale =~ /\b\d+\b/o && $scale ne '1'
			&& $scale ne '2' && $scale ne '4' && $scale ne '8';
		return 0 if is_reg_intel($scale) && $index_reg =~ /\b\d+\b/o && $index_reg ne '1'
			&& $index_reg ne '2' && $index_reg ne '4' && $index_reg ne '8';
	}
	return 0 if defined $base_reg && defined $index_reg && defined $disp
		&& is_reg_intel($base_reg) && is_reg_intel($index_reg) && is_reg_intel($disp);
	return 0 if defined $base_reg && defined $scale && defined $disp
		&& is_reg_intel($base_reg) && is_reg_intel($scale) && is_reg_intel($disp);

	return 1;
}

=head2 is_valid_64bit_addr_intel

 Checks if the given string parameter (must contain the square braces)
  is a valid x86 64-bit addressing mode in Intel syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns 1 if yes.

=cut

sub is_valid_64bit_addr_intel($) {

	my $elem = shift;
	# [seg:base+index*scale+disp]
	if (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_64bit_addr_parts_intel ($1, $2, $3, $4, $5, $6, $7, $8);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_64bit_addr_parts_intel ($1, $2, $3, $6, $7, $8, $4, $5);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_64bit_addr_parts_intel ($1, $5, $6, $2, $3, $4, $7, $8);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_64bit_addr_parts_intel ($1, undef, undef, $2, $3, $4, $5, $6);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_64bit_addr_parts_intel ($1, $2, $3, $4, $5, undef, $6, $7);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_64bit_addr_parts_intel ($1, $2, $3, $4, $5, $6, undef, undef);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*\]$/o) {

		return _validate_64bit_addr_parts_intel ($1, $2, $3, undef, undef, undef, undef, undef);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o) {

		return _validate_64bit_addr_parts_intel ($1, undef, undef, $2, $3, $4, undef, undef);
	}
	elsif (	$elem =~ /^\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]*)\s*(\w+)\s*\]$/o
		|| $elem =~ /^(\w+)\s*:\s*\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]*)\s*(\w+)\s*\]$/o) {

		return _validate_64bit_addr_parts_intel ($1, $2, $3, undef, undef, undef, $4, $5);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_64bit_addr_parts_intel (undef, $1, $2, $3, $4, $5, $6, $7);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_64bit_addr_parts_intel (undef, $1, $2, $5, $6, $7, $3, $4);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_64bit_addr_parts_intel (undef, $4, $5, $1, $2, $3, $6, $7);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_64bit_addr_parts_intel (undef, undef, undef, $1, $2, $3, $4, $5);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_64bit_addr_parts_intel (undef, $1, $2, $3, $4, undef, $5, $6);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_64bit_addr_parts_intel (undef, $1, $2, $3, $4, $5, undef, undef);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*\]/o ) {

		return _validate_64bit_addr_parts_intel (undef, $1, $2, undef, undef, undef, undef, undef);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]$/o ) {

		return _validate_64bit_addr_parts_intel (undef, undef, undef, $1, $2, $3, undef, undef);
	}
	elsif (	$elem =~ /^\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]*)\s*(\w+)\s*\]$/o ) {

		return _validate_64bit_addr_parts_intel (undef, $1, $2, undef, undef, undef, $3, $4);
	}
	return 0;
}

# =head2 _is_valid_64bit_addr_reg_att
#
#  PRIVATE SUBROUTINE.
#  Checks if the given register can be used in x86 64-bit addressing
#   mode in AT&T syntax.
#  Returns 1 if yes.
#
# =cut
#
sub _is_valid_64bit_addr_reg_att($) {

	my $reg = shift;
	return 1 if is_reg64_att($reg) || is_r32_in64_att($reg) || is_addressable32_att($reg);
	return 0;
}

# =head2 _validate_64bit_addr_parts_att
#
#  PRIVATE SUBROUTINE.
#  Checks if the given address components give a valid x86 64-bit addressing
#   mode in AT&T syntax.
#  Returns 1 if yes.
#
# =cut
sub _validate_64bit_addr_parts_att($$$$$$) {

	my $seg_reg = shift;
	#my $base_reg_sign = shift; # not allowed in the syntax at all
	my $base_reg = shift;
	#my $index_reg_sign = shift; # not allowed in the syntax at all
	my $index_reg = shift;
	my $scale = shift;
	my $disp_sign = shift;
	my $disp = shift;
	my $was64 = 0;
	my $nregs = 0;

	return 0 if defined $seg_reg && ! is_segreg_att($seg_reg);
	if ( defined $base_reg ) {

		if ( ! defined $index_reg #&& ! defined $scale # no index reg - no scale in is_valid_64bit_addr_att()
		) {
			# just one value inside - allow '(var)',
			# disallow 'var(var)', allow 'var(%reg)'
			return 0 if ( (defined $disp || $base_reg =~ /%/o)
				&& (! _is_valid_64bit_addr_reg_att($base_reg) || $base_reg =~ /^%rip$/io));
				#|| (defined $base_reg_sign && $base_reg_sign =~ /-/o);
		}
		return 0 if is_reg_att($base_reg)
			&& (! _is_valid_64bit_addr_reg_att($base_reg) || $base_reg =~ /^%rip$/io);
		$nregs++;
		$was64++ if is_reg64_att($base_reg);
	}
	if ( defined $index_reg ) {

		if ( ! defined $base_reg && ! defined $scale ) {
			# just one value inside - check for "(,1)
			return 1 if $index_reg eq '1' && ! is_reg_att($disp);
		}
		return 0 if ! _is_valid_64bit_addr_reg_att($index_reg);
		return 0 if $index_reg =~ /^%rsp$/io || $index_reg =~ /^%rip$/io;
		$nregs++;
		$was64++ if is_reg64_att($index_reg);
	}
	return 0 if defined $disp && is_reg_att($disp);
	return 0 if $was64 != 0 && $was64 != $nregs;

	# taken care of above and below:
	#return 0 if defined $index_reg && defined $scale
	#	&& is_reg_att($index_reg) && is_reg_att($scale);
	# useless after removing the conditions for the sign:
	#return 0 if defined $base_reg #&& defined $base_reg_sign
	#	&& is_reg_att($base_reg);# && $base_reg_sign =~ /-/o;
	#return 0 if defined $index_reg #&& defined $index_reg_sign
	#	&& is_reg_att($index_reg);# && $index_reg_sign =~ /-/o;
	# regexed out to be just digits in is_valid_64bit_addr_att():
	#return 0 if defined $scale #&& defined $index_reg_sign
	#	&& is_reg_att($scale);# && $index_reg_sign =~ /-/o;
	# taken care of above:
	#return 0 if defined $disp #&& defined $disp_sign # always defined if $disp is defined
	#	&& is_reg_att($disp) && $disp_sign =~ /-/o;
	return 0 if defined $scale && ($scale ne '1' && $scale ne '2' && $scale ne '4' && $scale ne '8');
	# taken care of above:
	#return 0 if defined $base_reg && defined $index_reg && defined $disp
	#	&& is_reg_att($base_reg) && is_reg_att($index_reg) && is_reg_att($disp);
	#return 0 if defined $base_reg && defined $scale && defined $disp
	#	&& is_reg_att($base_reg) && is_reg_att($scale) && is_reg_att($disp);

	return 1;
}

=head2 is_valid_64bit_addr_att

 Checks if the given string parameter (must contain the parentheses)
  is a valid x86 64-bit addressing mode in AT&T syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns 1 if yes.

=cut

sub is_valid_64bit_addr_att($) {

	my $elem = shift;
	if ( $elem =~ /^([%\w]+):\s*\(\s*([%\w]+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att ($1, $2, undef, undef, undef, undef);
	}
	elsif ( $elem =~ /^([%\w]+):\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att ($1, $2, $3, undef, undef, undef);
	}
	elsif ( $elem =~ /^([%\w]+):\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att ($1, $2, $3, $4, undef, undef);
	}
	elsif ( $elem =~ /^([%\w]+):\s*\(\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att ($1, undef, $2, $3, undef, undef);
	}
	elsif ( $elem =~ /^([%\w]+):\s*\(\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att ($1, undef, $2, undef, undef, undef);
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att ($1, $4, undef, undef, $2, $3);
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att ($1, $4, $5, undef, $2, $3);
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att ($1, $4, $5, $6, $2, $3);
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att ($1, undef, $4, $5, $2, $3);
	}
	elsif ( $elem =~ /^([%\w]+):\s*([+-]*)\s*([%\w]+)\s*\(\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att ($1, undef, $4, undef, $2, $3);
	}
	elsif ( $elem =~ /^\(\s*([%\w]+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att (undef, $1, undef, undef, undef, undef);
	}
	elsif ( $elem =~ /^\(\s*([%\w]+)\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att (undef, $1, $2, undef, undef, undef);
	}
	elsif ( $elem =~ /^\(\s*([%\w]+)\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att (undef, $1, $2, $3, undef, undef);
	}
	elsif ( $elem =~ /^\(\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att (undef, undef, $1, $2, undef, undef);
	}
	elsif ( $elem =~ /^\(\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att (undef, undef, $1, undef, undef, undef);
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att (undef, $3, undef, undef, $1, $2);
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att (undef, $3, $4, undef, $1, $2);
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*([%\w]+)\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att (undef, $3, $4, $5, $1, $2);
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*,\s*([%\w]+)\s*,\s*(\d+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att (undef, undef, $3, $4, $1, $2);
	}
	elsif ( $elem =~ /^([+-]*)\s*([%\w]+)\s*\(\s*,\s*([%\w]+)\s*\)$/o ) {

		return _validate_64bit_addr_parts_att (undef, undef, $3, undef, $1, $2);
	}
	return 0;
}

=head2 is_valid_64bit_addr

 Checks if the given string parameter (must contain the parentheses)
  is a valid x86 64-bit addressing mode in AT&T or Intel syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns 1 if yes.

=cut

sub is_valid_64bit_addr($) {

	my $elem = shift;
	return    is_valid_64bit_addr_intel ($elem)
		| is_valid_64bit_addr_att ($elem);
}

=head2 is_valid_addr_intel

 Checks if the given string parameter (must contain the square braces)
  is a valid x86 addressing mode in Intel syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns 1 if yes.

=cut

sub is_valid_addr_intel($) {

	my $elem = shift;
	return    is_valid_16bit_addr_intel ($elem)
		| is_valid_32bit_addr_intel ($elem)
		| is_valid_64bit_addr_intel ($elem);
}

=head2 is_valid_addr_att

 Checks if the given string parameter (must contain the braces)
  is a valid x86 addressing mode in AT&T syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns 1 if yes.

=cut

sub is_valid_addr_att($) {

	my $elem = shift;
	return    is_valid_16bit_addr_att($elem)
		| is_valid_32bit_addr_att($elem)
		| is_valid_64bit_addr_att($elem);
}

=head2 is_valid_addr

 Checks if the given string parameter (must contain the square braces)
  is a valid x86 addressing mode (Intel or AT&T syntax).
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns 1 if yes.

=cut

sub is_valid_addr($) {

	my $elem = shift;
	return    is_valid_addr_intel($elem)
		| is_valid_addr_att($elem);
}

=head2 is_att_suffixed_instr

 Tells if the given instruction is suffixed in AT&T syntax.
 Returns 1 if yes.

=cut

sub is_att_suffixed_instr($) {

	return _is_in_array (shift, \@att_suff_instr);
}

=head2 is_att_suffixed_instr_fpu

 Tells if the given FPU non-integer instruction is suffixed in AT&T syntax.
 Returns 1 if yes

=cut

sub is_att_suffixed_instr_fpu($) {

	return _is_in_array (shift, \@att_suff_instr_fpu);
}

=head2 add_att_suffix_instr

 Creates the AT&T syntax instruction array from the Intel-syntax array.
 Returns the new array.

=cut

sub add_att_suffix_instr(@) {

	my @result = ();
	foreach (@_) {
		if ( is_att_suffixed_instr ($_) ) {

			push @result, $_.'b';
			push @result, $_.'w';
			push @result, $_.'l';
			push @result, $_.'q';
		}
		else {
			# FPU instructions
			if ( /^fi(\w+)/io ) {

				push @result, $_.'s';
				push @result, $_.'l';
				push @result, $_.'q';
			}
			elsif ( is_att_suffixed_instr_fpu ($_) ) {

				push @result, $_.'s';
				push @result, $_.'l';
				push @result, $_.'t';
			}
			elsif ( /^\s*(mov[sz])x\s+([^,]+)\s*,\s*([^,]+)(.*)/io ) {

				# add suffixes to MOVSX/MOVZX instructions
				my ($inst, $arg1, $arg2, $rest, $z1, $z2);
				$inst = $1;
				$z1 = $2;
				$z2 = $3;
				$rest = $4;
				($arg1 = $z1) =~ s/\s*$//o;
				($arg2 = $z2) =~ s/\s*$//o;
				if ( is_reg8($arg2) && is_reg32($arg1) ) {
					push @result, "${inst}bl";
				} elsif ( is_reg8($arg2) && is_reg16($arg1) ) {
					push @result, "${inst}bw";
				} elsif ( is_reg8($arg2) && is_reg64($arg1) ) {
					push @result, "${inst}bq";
				} elsif ( is_reg16($arg2) && is_reg32($arg1)  ) {
					push @result, "${inst}wl";
				} elsif ( is_reg16($arg2) && is_reg64($arg1)  ) {
					push @result, "${inst}wq";
				}
				push @result, "$_";
			}
			elsif ( /^\s*(mov[sz])x/io ) {

				# add suffixes to MOVSX/MOVZX instructions
				push @result, "$1bl";
				push @result, "$1bw";
				push @result, "$1bq";
				push @result, "$1wl";
				push @result, "$1wq";
				push @result, "$_";
			}
			elsif ( /^\s*cbw\b/io ) {

				push @result, 'cbtw';
			}
			elsif ( /^\s*cwde\b/io ) {

				push @result, 'cwtl';
			}
			elsif ( /^\s*cwd\b/io ) {

				push @result, 'cwtd';
			}
			elsif ( /^\s*cdq\b/io ) {

				push @result, 'cltd';
			}
			else {
				push @result, "$_";
			}
		}
	}
	# adding AT&T suffixes can create duplicate entries. Remove them here:
	return _remove_duplicates (@result);
}

=head2 conv_att_addr_to_intel

 Converts the given string representing a valid AT&T addressing mode to Intel syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns the resulting string.

=cut

sub conv_att_addr_to_intel($) {

	my $par = shift;
	$par =~ s/%([a-zA-Z]+)/$1/go;
	# seg: disp(base, index, scale)
	$par =~ s/(\w+\s*:\s*)([\w\+\-\(\)]+)\s*\(\s*(\w+)\s*,\s*(\w+)\s*,\s*(\d)\s*\)/[$1$3+$5*$4+$2]/o;
	$par =~ s/(\w+\s*:\s*)([\w\+\-\(\)]+)\s*\(\s*(\w+)\s*,\s*(\w+)\s*,?\s*\)/[$1$3+$4+$2]/o;
	$par =~ s/(\w+\s*:\s*)\(\s*(\w+)\s*,\s*(\w+)\s*,\s*(\d)\s*\)/[$1$2+$3*$4]/o;
	$par =~ s/(\w+\s*:\s*)\(\s*(\w+)\s*,\s*(\w+)\s*,?\s*\)/[$1$2+$3]/o;
	$par =~ s/(\w+\s*:\s*)([\w\+\-\(\)]+)\s*\(\s*,\s*1\s*\)/[$1$2]/o;
	$par =~ s/(\w+\s*:\s*)([\w\+\-\(\)]+)\s*\(\s*,\s*(\w+)\s*,\s*(\d)\s*\)/[$1$3*$4+$2]/o;
	$par =~ s/(\w+\s*:\s*)([\w\+\-\(\)]+)\s*\(\s*(\w+)\s*\)/[$1$3+$2]/o;
	$par =~ s/(\w+\s*:\s*)\s*\(\s*,\s*(\w+)\s*,\s*(\d)\s*\)/[$1$2*$3]/o;
	$par =~ s/(\w+\s*:\s*)\(\s*(\w+)\s*\)/[$1$2]/o;

	# disp(base, index, scale)
	$par =~ s/([\w\+\-\(\)]+)\(\s*(\w+)\s*,\s*(\w+)\s*,\s*(\d)\s*\)/[$2+$3*$4+$1]/o;
	$par =~ s/([\w\+\-\(\)]+)\(\s*(\w+)\s*,\s*(\w+)\s*,?\s*\)/[$2+$3+$1]/o;
	$par =~ s/\(\s*(\w+)\s*,\s*(\w+)\s*,\s*(\d)\s*\)/\t[$1+$2*$3]/o;
	$par =~ s/\(\s*(\w+)\s*,\s*(\w+)\s*,?\s*\)/\t[$1+$2]/o;
	$par =~ s/([\w\+\-\(\)]+)\(\s*,\s*(\w+)\s*,\s*(\d)\s*\)/[$2*$3+$1]/o;
	$par =~ s/\(\s*,\s*(\w+)\s*,\s*(\d)\s*\)/[$1*$2]/o;

	# disp(, index)
	$par =~ s/([\w\-\+\(\)]+)\(\s*,\s*1\s*\)/[$1]/o;
	$par =~ s/([\w\-\+\(\)]+)\(\s*,\s*(\w+)\s*\)/[$2+$1]/o;

	# (base, index)
	$par =~ s/\(\s*,\s*1\s*\)/[$1]/o;
	$par =~ s/\(\s*,\s*(\w+)\s*\)/[$1]/o;

	# disp(base)
	$par =~ s/([\w\-\+\(\)]+)\(\s*(\w+)\s*\)/[$2+$1]/o unless $par =~ /st\(\d\)/io;
	$par =~ s/\(\s*(\w+)\s*\)/[$1]/o unless $par =~ /st\(\d\)/io;

	return $par;
}

=head2 conv_intel_addr_to_att

 Converts the given string representing a valid Intel addressing mode to AT&T syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns the resulting string.

=cut

sub conv_intel_addr_to_att($) {

	my $par = shift;
	my ($z1, $z2, $z3);
	# seg: disp(base, index, scale)
	# [seg:base+index*scale+disp]
	my $a_seg_base_index_scale_disp = qr/\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]/o;
	my $a_seg_base_disp_index_scale = qr/\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]/o;
	my $a_seg_index_scale_base_disp = qr/\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]/o;
	my $a_seg_base_index_disp = qr/\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]/o;
	my $a_seg_base_index_scale = qr/\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]/o;
	my $a_seg_base_index = qr/\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]/o;
	my $a_seg_base = qr/\[\s*(\w+)\s*:\s*(\w+)\s*\]/o;
	my $a_seg_index_scale_base = qr/\[\s*(\w+)\s*:\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]/o;

	my $a_base_index_scale_disp = qr/\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]/o;
	my $a_index_scale_base_disp = qr/\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]/o;
	my $a_base_disp_index_scale = qr/\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]/o;
	my $a_base_index_disp = qr/\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]/o;
	my $a_base_index_scale = qr/\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*\*\s*(\w+)\s*(\)*)\s*\]/o;
	my $a_base_index = qr/\[\s*([\+\-\(\)]*)\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]/o;
	my $a_base = qr/\[\s*(\w+)\s*\]/o;
	my $a_index_scale_base = qr/\[\s*([\+\-\(\)]*)\s*(\w+)\s*\*\s*(\w+)\s*([\+\-\(\)]+)\s*(\w+)\s*(\)*)\s*\]/o;

	if ( $par =~ /$a_seg_base_index_scale_disp/ ) {

		$z1 = _nopluses($2);
		$z2 = _nopluses($4);
		$z3 = _nopluses($7);
		if ( is_reg($3) && is_reg($5) ) {
			$par =~ s/$a_seg_base_index_scale_disp/$1:($z3$8)$9($3,$5,$6)/;
		} elsif ( is_reg($3) && is_reg($6) ) {
			$par =~ s/$a_seg_base_index_scale_disp/$1:($z3$8)$9($3,$6,$5)/;
		} elsif ( is_reg($5) && is_reg($8) ) {
			$par =~ s/$a_seg_base_index_scale_disp/$1:($z1$3)$9($8,$5,$6)/;
		} elsif ( is_reg($6) && is_reg($8) ) {
			$par =~ s/$a_seg_base_index_scale_disp/$1:($z1$3)$9($8,$6,$5)/;
		} elsif ( is_reg($3) && is_reg($8) ) {
			$par =~ s/$a_seg_base_index_scale_disp/$1:($z2$5*$6)$9($3,$8)/;
		} elsif ( is_reg($3) ) {
			$par =~ s/$a_seg_base_index_scale_disp/$1:($z3$8$z2$5*$6)$9($3)/;
		} elsif ( is_reg($5) ) {
			$par =~ s/$a_seg_base_index_scale_disp/$1:($z3$8$z1$3)$9(,$5,$6)/;
		} elsif ( is_reg($6) ) {
			$par =~ s/$a_seg_base_index_scale_disp/$1:($z3$8$z1$3)$9(,$6,$5)/;
		} elsif ( is_reg($8) ) {
			$par =~ s/$a_seg_base_index_scale_disp/$1:($z1$3$z2$5*$6)$9($8)/;
		} else {
			$par =~ s/$a_seg_base_index_scale_disp/$1:($z1$3$z2$5*$6$z3$8)$9(,1)/;
		}
	}
	elsif ( $par =~ /$a_seg_base_disp_index_scale/ ) {

		$z1 = _nopluses($2);
		$z2 = _nopluses($4);
		$z3 = _nopluses($6);
		if ( is_reg($3) && is_reg($5) ) {
			$par =~ s/$a_seg_base_disp_index_scale/$1:($z3$7*$8)$9($3,$5)/;
		} elsif ( is_reg($5) && is_reg($7) ) {
			$par =~ s/$a_seg_base_disp_index_scale/$1:($z1$3)$9($5,$7,$8)/;
		} elsif ( is_reg($5) && is_reg($8) ) {
			$par =~ s/$a_seg_base_disp_index_scale/$1:($z1$3)$9($5,$8,$7)/;
		} elsif ( is_reg($3) && is_reg($7) ) {
			$par =~ s/$a_seg_base_disp_index_scale/$1:($z2$5)$9($3,$7,$8)/;
		} elsif ( is_reg($3) && is_reg($8) ) {
			$par =~ s/$a_seg_base_disp_index_scale/$1:($z2$5)$9($3,$8,$7)/;
		} elsif ( is_reg($3) ) {
			$par =~ s/$a_seg_base_disp_index_scale/$1:($z2$5$z3$7*$8)$9($3)/;
		} elsif ( is_reg($5) ) {
			$par =~ s/$a_seg_base_disp_index_scale/$1:($z1$3$z3$7*$8)$9($5)/;
		} elsif ( is_reg($7) ) {
			$par =~ s/$a_seg_base_disp_index_scale/$1:($z1$3$z2$5)$9(,$7,$8)/;
		} elsif ( is_reg($8) ) {
			$par =~ s/$a_seg_base_disp_index_scale/$1:($z1$3$z2$5)$9(,$8,$7)/;
		} else {
			$par =~ s/$a_seg_base_disp_index_scale/$1:($z1$3$z2$5$z3$7*$8)$9(,1)/;
		}
	}
	elsif ( $par =~ /$a_seg_index_scale_base_disp/ ) {

		$z1 = _nopluses($2);
		$z2 = _nopluses($5);
		$z3 = _nopluses($7);
		if ( is_reg($3) && is_reg($6) ) {
			$par =~ s/$a_seg_index_scale_base_disp/$1:($z3$8)$9($6,$3,$4)/;
		} elsif ( is_reg($4) && is_reg($6) ) {
			$par =~ s/$a_seg_index_scale_base_disp/$1:($z3$8)$9($6,$4,$3)/;
		} elsif ( is_reg($6) && is_reg($8) ) {
			$par =~ s/$a_seg_index_scale_base_disp/$1:($z1$3*$4)$9($6,$8)/;
		} elsif ( is_reg($3) && is_reg($8) ) {
			$par =~ s/$a_seg_index_scale_base_disp/$1:($z2$6)$9($8,$3,$4)/;
		} elsif ( is_reg($4) && is_reg($8) ) {
			$par =~ s/$a_seg_index_scale_base_disp/$1:($z2$6)$9($8,$4,$3)/;
		} elsif ( is_reg($3) ) {
			$par =~ s/$a_seg_index_scale_base_disp/$1:($z2$6$z3$8)$9(,$3,$4)/;
		} elsif ( is_reg($4) ) {
			$par =~ s/$a_seg_index_scale_base_disp/$1:($z2$6$z3$8)$9(,$4,$3)/;
		} elsif ( is_reg($6) ) {
			$par =~ s/$a_seg_index_scale_base_disp/$1:($z1$3*$4$z3$8)$9($6)/;
		} elsif ( is_reg($8) ) {
			$par =~ s/$a_seg_index_scale_base_disp/$1:($z1$3*$4$z2$6)$9($8)/;
		} else {
			$par =~ s/$a_seg_index_scale_base_disp/$1:($z1$3*$4$z2$6$z3$8)$9(,1)/;
		}
	}
	elsif ( $par =~ /$a_seg_base_index_disp/ ) {

		$z1 = _nopluses($2);
		$z2 = _nopluses($4);
		$z3 = _nopluses($6);
		if ( is_reg($3) && is_reg($5) ) {
			$par =~ s/$a_seg_base_index_disp/$1:($z3$7)$8($3,$5,)/;
		} elsif ( is_reg($3) && is_reg($7) ) {
			$par =~ s/$a_seg_base_index_disp/$1:($z2$5)$8($3,$7,)/;
		} elsif ( is_reg($5) && is_reg($7) ) {
			$par =~ s/$a_seg_base_index_disp/$1:($z1$3)$8($7,$5,)/;
		} elsif ( is_reg($3) ) {
			$par =~ s/$a_seg_base_index_disp/$1:($z1$5$z3$7)$8($3)/;
		} elsif ( is_reg($5) ) {
			$par =~ s/$a_seg_base_index_disp/$1:($z1$3$z3$7)$8($5)/;
		} elsif ( is_reg($7) ) {
			$par =~ s/$a_seg_base_index_disp/$1:($z1$3$z2$5)$8($7)/;
		} else {
			$par =~ s/$a_seg_base_index_disp/$1:($z1$3$z2$5$z3$7)$8(,1)/;
		}
	}
	elsif ( $par =~ /$a_seg_base_index_scale/ ) {

		$z1 = _nopluses($2);
		$z2 = _nopluses($4);
		if ( is_reg($3) && is_reg($5) ) {
			$par =~ s/$a_seg_base_index_scale/$1:($3,$5,$6)/;
		} elsif ( is_reg($3) && is_reg($6) ) {
			$par =~ s/$a_seg_base_index_scale/$1:($3,$6,$5)/;
		} elsif ( is_reg($3) ) {
			$par =~ s/$a_seg_base_index_scale/$1:($z2$5*$6)$7($3)/;
		} elsif ( is_reg($5) ) {
			$par =~ s/$a_seg_base_index_scale/$1:($z1$3)$7(,$5,$6)/;
		} elsif ( is_reg($6) ) {
			$par =~ s/$a_seg_base_index_scale/$1:($z1$3)$7(,$6,$5)/;
		} else {
			$par =~ s/$a_seg_base_index_scale/$1:($z1$3$z2$5*$6)$7(,1)/;
		}
	}
	elsif ( $par =~ /$a_seg_base_index/ ) {

		$z1 = _nopluses($2);
		$z2 = _nopluses($4);
		if ( is_reg($3) && is_reg($5) ) {
			$par =~ s/$a_seg_base_index/$1:($3,$5,)/;
		} elsif ( is_reg($3) ) {
			$par =~ s/$a_seg_base_index/$1:($z2$5)$6($3)/;
		} elsif ( is_reg($5) ) {
			$par =~ s/$a_seg_base_index/$1:($z1$3)$6($5)/;
		} else {
			$par =~ s/$a_seg_base_index/$1:($z1$3$z2$5)$6(,1)/;
		}
	}
	elsif ( $par =~ /$a_seg_base/ ) {

		if ( is_reg($2) ) {
			$par =~ s/$a_seg_base/$1:($2)/;
		} else {
			$par =~ s/$a_seg_base/$1:$2(,1)/;
		}
	}
	elsif ( $par =~ /$a_seg_index_scale_base/ ) {

		$z1 = _nopluses($2);
		$z2 = _nopluses($5);
		if ( is_reg($3) && is_reg($6) ) {
			$par =~ s/$a_seg_index_scale_base/$1:($6,$3,$4)/;
		} elsif ( is_reg($4) && is_reg($6) ) {
			$par =~ s/$a_seg_index_scale_base/$1:($6,$4,$3)/;
		} elsif ( is_reg($3) ) {
			$par =~ s/$a_seg_index_scale_base/$1:($z2$6)$7(,$3,$4)/;
		} elsif ( is_reg($4) ) {
			$par =~ s/$a_seg_index_scale_base/$1:($z2$6)$7(,$4,$3)/;
		} elsif ( is_reg($6) ) {
			$par =~ s/$a_seg_index_scale_base/$1:($z1$3*$4)$7($6)/;
		} else {
			$par =~ s/$a_seg_index_scale_base/$1:($z1$3*$4$z2$6)$7(,1)/;
		}
	}
	# disp(base, index, scale)
	elsif ( $par =~ /$a_base_index_scale_disp/ ) {

		$z1 = _nopluses($1);
		$z2 = _nopluses($3);
		$z3 = _nopluses($6);
		if ( is_reg($2) && is_reg($4) ) {
			$par =~ s/$a_base_index_scale_disp/($z3$7)$8($2,$4,$5)/;
		} elsif ( is_reg($2) && is_reg($5) ) {
			$par =~ s/$a_base_index_scale_disp/($z3$7)$8($2,$5,$4)/;
		} elsif ( is_reg($2) && is_reg($7) ) {
			$par =~ s/$a_base_index_scale_disp/($z2$4*$5)$8($2,$7)/;
		} elsif ( is_reg($4) && is_reg($7) ) {
			$par =~ s/$a_base_index_scale_disp/($z1$2)$8($7,$4,$5)/;
		} elsif ( is_reg($5) && is_reg($7) ) {
			$par =~ s/$a_base_index_scale_disp/($z1$2)$8($7,$5,$4)/;
		} elsif ( is_reg($2) ) {
			$par =~ s/$a_base_index_scale_disp/($z3$7$z2$4*$5)$8($2)/;
		} elsif ( is_reg($4) ) {
			$par =~ s/$a_base_index_scale_disp/($z3$7+$z1$2)$8(,$4,$5)/;
		} elsif ( is_reg($5) ) {
			$par =~ s/$a_base_index_scale_disp/($z3$7+$z1$2)$8(,$5,$4)/;
		} elsif ( is_reg($7) ) {
			$par =~ s/$a_base_index_scale_disp/($z1$2$z2$4*$5)$8($7)/;
		} else {
			$par =~ s/$a_base_index_scale_disp/($z1$2$z2$4*$5$z3$7)$8(,1)/;
		}
	}
	elsif ( $par =~ /$a_index_scale_base_disp/ ) {

		$z1 = _nopluses($1);
		$z2 = _nopluses($4);
		$z3 = _nopluses($6);
		if ( is_reg($2) && is_reg($5) ) {
			$par =~ s/$a_index_scale_base_disp/($z3$7)$8($5,$2,$3)/;
		} elsif ( is_reg($3) && is_reg($5) ) {
			$par =~ s/$a_index_scale_base_disp/($z3$7)$8($5,$3,$2)/;
		} elsif ( is_reg($2) && is_reg($7) ) {
			$par =~ s/$a_index_scale_base_disp/($z2$5)$8($7,$2,$3)/;
		} elsif ( is_reg($3) && is_reg($7) ) {
			$par =~ s/$a_index_scale_base_disp/($z2$5)$8($7,$3,$2)/;
		} elsif ( is_reg($5) && is_reg($7) ) {
			$par =~ s/$a_index_scale_base_disp/($z1$2*$3)$8($5,$7)/;
		} elsif ( is_reg($2) ) {
			$par =~ s/$a_index_scale_base_disp/($z2$5$z3$7)$8(,$2,$3)/;
		} elsif ( is_reg($3) ) {
			$par =~ s/$a_index_scale_base_disp/($z2$5$z3$7)$8(,$3,$2)/;
		} elsif ( is_reg($5) ) {
			$par =~ s/$a_index_scale_base_disp/($z1$2*$3$z3$7)$8($5)/;
		} elsif ( is_reg($7) ) {
			$par =~ s/$a_index_scale_base_disp/($z1$2*$3$z2$5)$8($7)/;
		} else {
			$par =~ s/$a_index_scale_base_disp/($z1$2*$3$z2$5$z3$7)$8(,1)/;
		}
	}
	elsif ( $par =~ /$a_base_disp_index_scale/ ) {

		$z1 = _nopluses($1);
		$z2 = _nopluses($3);
		$z3 = _nopluses($5);
		if ( is_reg($2) && is_reg($4) ) {
			$par =~ s/$a_base_disp_index_scale/($z3$6*$7)$8($2,$4)/;
		} elsif ( is_reg($2) && is_reg($6) ) {
			$par =~ s/$a_base_disp_index_scale/($z2$4)$8($2,$6,$7)/;
		} elsif ( is_reg($2) && is_reg($7) ) {
			$par =~ s/$a_base_disp_index_scale/($z2$4)$8($2,$7,$6)/;
		} elsif ( is_reg($4) && is_reg($6) ) {
			$par =~ s/$a_base_disp_index_scale/($z1$2)$8($4,$6,$7)/;
		} elsif ( is_reg($4) && is_reg($7) ) {
			$par =~ s/$a_base_disp_index_scale/($z1$2)$8($4,$7,$6)/;
		} elsif ( is_reg($2) ) {
			$par =~ s/$a_base_disp_index_scale/($z2$4$z3$6*$7)$8($2)/;
		} elsif ( is_reg($4) ) {
			$par =~ s/$a_base_disp_index_scale/($z3$6*$7$z1$2)$8($4)/;
		} elsif ( is_reg($6) ) {
			$par =~ s/$a_base_disp_index_scale/($z1$2$z2$4)$8(,$6,$7)/;
		} elsif ( is_reg($7) ) {
			$par =~ s/$a_base_disp_index_scale/($z1$2$z2$4)$8(,$7,$6)/;
		} else {
			$par =~ s/$a_base_disp_index_scale/($z1$2$z2$4$z3$6*$7)$8(,1)/;
		}
	}
	elsif ( $par =~ /$a_base_index_disp/ ) {

		$z1 = _nopluses($1);
		$z2 = _nopluses($3);
		$z3 = _nopluses($5);
		if ( is_reg($2) && is_reg($4) ) {
			$par =~ s/$a_base_index_disp/($z3$6)$7($2,$4)/;
		} elsif ( is_reg($2) && is_reg($6) ) {
			$par =~ s/$a_base_index_disp/($z2$4)$7($2,$6)/;
		} elsif ( is_reg($4) && is_reg($6) ) {
			$par =~ s/$a_base_index_disp/($z1$2)$7($4,$6)/;
		} elsif ( is_reg($2) ) {
			$par =~ s/$a_base_index_disp/($z3$6$z2$4)$7($2)/;
		} elsif ( is_reg($4) ) {
			$par =~ s/$a_base_index_disp/($z3$6+$z1$2)$7($4)/;
		} elsif ( is_reg($6) ) {
			$par =~ s/$a_base_index_disp/($z1$2$z2$4)$7($6)/;
		} else {
			$par =~ s/$a_base_index_disp/($z1$2$z2$4$z3$6)$7(,1)/;
		}
	}
	elsif ( $par =~ /$a_base_index_scale/ ) {

		$z1 = _nopluses($1);
		$z2 = _nopluses($3);
		if ( is_reg($2) && is_reg($4) ) {
			$par =~ s/$a_base_index_scale/($2,$4,$5)/;
		} elsif ( is_reg($2) && is_reg($5) ) {
			$par =~ s/$a_base_index_scale/($2,$5,$4)/;
		} elsif ( is_reg($2) ) {
			$par =~ s/$a_base_index_scale/($z2$4*$5)$6($2)/;
		} elsif ( is_reg($4) ) {
			$par =~ s/$a_base_index_scale/($z1$2)$6(,$4,$5)/;
		} elsif ( is_reg($5) ) {
			$par =~ s/$a_base_index_scale/($z1$2)$6(,$5,$4)/;
		} else {
			$par =~ s/$a_base_index_scale/($z1$2$z2$4*$5)$6(,1)/;
		}
	}
	elsif ( $par =~ /$a_base_index/ ) {

		$z1 = _nopluses($1);
		$z2 = _nopluses($3);
		if ( is_reg($2) && is_reg($4) ) {
			$par =~ s/$a_base_index/($2,$4)/;
		} elsif ( is_reg($2) ) {
			$par =~ s/$a_base_index/($z2$4)$5($2)/;
		} elsif ( is_reg($4) ) {
			$par =~ s/$a_base_index/($z1$2)$5($4)/;
		} else {
			$par =~ s/$a_base_index/($2$z2$4)$5(,1)/;
		}
	}
	elsif ( $par =~ /$a_base/ ) {
		if ( is_reg($1) ) {
			# disp(base)
			$par =~ s/$a_base/($1)/;
		} else {
			$par =~ s/$a_base/$1(,1)/;
		}
	}
	elsif ( $par =~ /$a_index_scale_base/ ) {

		$z1 = _nopluses($1);
		$z2 = _nopluses($4);
		if ( is_reg($2) && is_reg($5) ) {
			$par =~ s/$a_index_scale_base/($5,$2,$3)/;
		} elsif ( is_reg($3) && is_reg($5) ) {
			$par =~ s/$a_index_scale_base/($5,$3,$2)/;
		} elsif ( is_reg($2) ) {
			$par =~ s/$a_index_scale_base/($z2$5)$6(,$2,$3)/;
		} elsif ( is_reg($3) ) {
			$par =~ s/$a_index_scale_base/($z2$5)$6(,$3,$2)/;
		} elsif ( is_reg($5) ) {
			$par =~ s/$a_index_scale_base/($z1$2*$3)$6($5)/;
		} else {
			$par =~ s/$a_index_scale_base/($z1$2*$3$z2$5)$6(,1)/;
		}
	}
	foreach my $i (@regs_intel) {
		$par =~ s/\b($i)\b/%$1/;
	}

	foreach my $r (@regs_intel) {

		$par =~ s/\%\%$r\b/\%$r/gi;
	}
	return $par;
}

# =head2 _change_to_intel_addr_if_applicable
#
#  PRIVATE SUBROUTINE.
#  If the parameter is applicable to be an address (i.e. not a variable,
#   register or a label), returns its value in square brackets (intel-syntax
#   memory reference).
#
# =cut
#
sub _change_to_intel_addr_if_applicable($) {

	my $par = shift;
	# (we mustn't change digits and %st(n), skip also labels)
	if ( $par !~ /\$/o && $par !~ /\%/o && $par !~ /_L\d+/o && $par =~ /[a-zA-Z_\.]/o ) {

		return "[$par]";
	}
	return $par;
}

=head2 conv_att_instr_to_intel

 Converts the given string representing a valid AT&T instruction to Intel syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns the resulting string.

=cut

sub conv_att_instr_to_intel($) {

	my $par = shift;

	# process "jmp cs,sth" early so that it doesn't get substituted
	my $jmp_2arg = qr/^\s*l?(jmp|call)\s*(\w+)\s*,\s*(\w+)\s*$/io;
	if ( $par =~ /$jmp_2arg/ ) {
		$par =~ s/$jmp_2arg/\t$1\t$2:$3/;
	}
	# (changing "xxx" to "[xxx]", if there's no '$' or '%')

	# (elements of memory operands mustn't be taken as instruction operands, so there are no '()'s here)
	if ( $par =~ /^\s*(\w+)\s+([\$\%\w\+\-]+)\s*,\s*([\$\%\w\+\-]+)\s*,\s*([\$\%\w\+\-]+)/o ) {

		my ($a1, $a2, $a3, $a4);

		$a1 = $1;
		$a2 = $2;
		$a3 = $3;
		$a4 = $4;

		#if ( $a1 !~ /call/io && $a1 !~ /^\s*j[a-z]{1,3}/io ) {

			$a2 = _change_to_intel_addr_if_applicable ($a2);
			$a3 = _change_to_intel_addr_if_applicable ($a3);
			$a4 = _change_to_intel_addr_if_applicable ($a4);

			# (ATTENTION: operand order will be changed later)
			$par = "\t$a1\t$a2, $a3, $a4\n";
		#}
	}

	if ( $par =~ /^\s*(\w+)\s+([\$\%\w\+\-]+)\s*,\s*([\$\%\w\+\-]+)\s*$/o ) {

		my ($a1, $a2, $a3);

		$a1 = $1;
		$a2 = $2;
		$a3 = $3;

		#if ( $a1 !~ /call/io && $a1 !~ /^\s*j[a-z]{1,3}/io ) {

			$a2 = _change_to_intel_addr_if_applicable ($a2);
			$a3 = _change_to_intel_addr_if_applicable ($a3);

			# (ATTENTION: operand order will be changed later)
			$par = "\t$a1\t$a2, $a3\n";
		#}
	}

	if ( $par =~ /^\s*(\w+)\s+([\$\%\w\+\-]+)\s*\s*$/o ) {

		my ($a1, $a2);

		$a1 = $1;
		$a2 = $2;

		# (don't touch "call/jmp xxx")
		if ( $a1 !~ /call/io && $a1 !~ /^\s*j[a-z]{1,3}/io ) {

			$a2 = _change_to_intel_addr_if_applicable ($a2);

			# (ATTENTION: operand order will be changed later)
			$par = "\t$a1\t$a2\n";
		}
	}

	# (removing dollar chars)
	$par =~ s/\$//go;
	# (removing percent chars)
	$par =~ s/%//go;
	# (removing asterisk chars)
	$par =~ s/\*//go;

	# (changing memory references):
	$par = conv_att_addr_to_intel $par;

	# (changing "st[N]" to "stN")
	$par =~ s/(\s)st\[(\d)\]/$1 st$2/go;
	# (changing "st" to "st0")
	$par =~ s/(\s)st(\s|,)/$1 st0$2/go;

	# (changing operands' order, but not for jump/call):
	if ( $par!~ /^\s*l?(jmp|call)/io ) {
		my $i_3op = qr/^\s*(\w+)\s+(\[?[:\.\w\*\+\-\(\)]+\]?)\s*,\s*(\[?[:\.\w\*\+\-\(\)]+\]?)\s*,\s*(\[?[:\.\w\*\+\-\(\)]+\]?)/o;
		my $i_2op = qr/^\s*(\w+)\s+(\[?[:\.\w\*\+\-\(\)]+\]?)\s*,\s*(\[?[:\.\w\*\+\-\(\)]+\]?)([^,]*(;.*)?)$/o;
		my $i_1op = qr/^\s*(\w+)\s+(\[?[:\.\w\*\+\-\(\)]+\]?)([^,]*(;.*)?)$/o;
		if ( $par =~ /$i_3op/ ) {
			if ( is_instr($1) ) {
				$par =~ s/$i_3op/\t$1\t$4, $3, $2/;
			}
		}
		if ( $par =~ /$i_2op/) {
			if ( is_instr($1) ) {
				$par =~ s/$i_2op/\t$1\t$3, $2$4/;
			}
		}
		if ( $par =~ /$i_1op/ ) {
			if ( is_instr($1) ) {
				$par =~ s/$i_1op/\t$1\t$2$3/;
			}
		}
	}

	foreach my $i (@instr) {

		next unless $par =~ /^\s*$i[bwl]\s*.*$/i
			&& $par !~ /^\s*f\w+l\s+.*$/
			&& $par !~ /^\s*mov[sz][bwl][bwl]\s+.*$/;
		$par =~ s/^\s*$i[b]\s*(.*)$/\t$i\tbyte $1/i;
		$par =~ s/^\s*$i[w]\s*(.*)$/\t$i\tword $1/i;
		$par =~ s/^\s*$i[l]\s*(.*)$/\t$i\tdword $1/i;
	}

	$par =~ s/^\s*movsbw\s+(.*)\s*,\s*(.*)$/\tmovsx\t$1, byte $2\n/io;
	$par =~ s/^\s*movsbl\s+(.*)\s*,\s*(.*)$/\tmovsx\t$1, byte $2\n/io;
	$par =~ s/^\s*movswl\s+(.*)\s*,\s*(.*)$/\tmovsx\t$1, word $2\n/io;
	$par =~ s/^\s*movzbw\s+(.*)\s*,\s*(.*)$/\tmovzx\t$1, byte $2\n/io;
	$par =~ s/^\s*movzbl\s+(.*)\s*,\s*(.*)$/\tmovzx\t$1, byte $2\n/io;
	$par =~ s/^\s*movzwl\s+(.*)\s*,\s*(.*)$/\tmovzx\t$1, word $2\n/io;

	my $jmp_mem = qr/^\s*l?(jmp|call)\s*(\[[\w\*\+\-\s]+\])\s*$/io;
	my $jmp_nomem = qr/^\s*l?(jmp|call)\s*([\w\*\+\-]+)\s*$/io;
	if ( $par =~ /$jmp_mem/ ) {
		$par =~ s/$jmp_mem/\t$1\tdword $2/;
	}
	elsif ( $par =~ /$jmp_nomem/ ) {
		$par =~ s/$jmp_nomem/\t$1\tdword $2/;
	}
	$par =~ s/^\s*lret\s*(.*)$/\tret\t$1\t/i;

	$par =~ s/^\s*cbtw\s*/\tcbw\t/io;
	$par =~ s/^\s*cwtl\s*/\tcwde\t/io;
	$par =~ s/^\s*cwtd\s*/\tcwd\t/io;
	$par =~ s/^\s*cltd\s*/\tcdq\t/io;

	$par =~ s/^\s*f(\w+)s\s+(.*)$/\tf$1\tdword $2/io unless $par =~ /fchs\s/io;
	$par =~ s/^\s*f(\w+)l\s+(.*)$/\tf$1\tqword $2/io unless $par =~ /fmul\s/io;
	$par =~ s/^\s*f(\w+)q\s+(.*)$/\tf$1\tqword $2/io;
	$par =~ s/^\s*f(\w+)t\s+(.*)$/\tf$1\ttword $2/io unless $par =~ /fst\s/io;

	# (REP**: removing the end of line char)
	$par =~ s/^\s*(rep[enz]{0,2})\s*/\t$1/io;

	return $par;
}

# =head2 _remove_size_qualifiers_add_dollar_add_dollar
#
#  PRIVATE SUBROUTINE.
#  Returns the parameter after removing any size qualifiers (byte, word,
#   dword, etc.) and any leading and trailing whitespace.
#  If the parameter is not a memory reference or a register, prefixes it with
#   a dollar-sign.
#
# =cut
#
sub _remove_size_qualifiers_add_dollar($) {

	my $par = shift;
	$par =~ s/\s+$//o;
	$par =~ s/(t?byte|[dqpftoyz]?word)//io;
	$par =~ s/^\s+//o;
	if ( $par !~ /\[/o && !is_reg($par) )
	{
		$par = "\$$par";
	}
	return $par;
}

=head2 conv_intel_instr_to_att

 Converts the given string representing a valid Intel instruction to AT&T syntax.
 Works best after any pre-processing of the input, i.e. after all macros,
  constants, etc. have been replaced by the real values.
 Returns the resulting string.

=cut

sub conv_intel_instr_to_att($) {

	my $par = shift;
	my ($a1, $a2, $a3, $a4);
	$par =~ s/ptr//gi;

	# (add the suffix)
	foreach my $i (@att_suff_instr) {

		if ( $par =~ /^\s*$i\s+([^,]+)/i ) {

			($a1 = $1) =~ s/\s+$//o;
			if ( $par =~ /[^;]+\bbyte\b/io )     {

				$par =~ s/^\s*$i\b/\t${i}b/i;
				$par =~ s/\b(t?byte|[dqpftoyz]?word)\b//io;

			} elsif ( $par =~ /[^;]+\bword\b/io )  {

				$par =~ s/^\s*$i\b/\t${i}w/i;
				$par =~ s/\b(t?byte|[dqpftoyz]?word)\b//io;

			} elsif ( $par =~ /[^;]+\bdword\b/io ) {

				$par =~ s/^\s*$i\b/\t${i}l/i;
				$par =~ s/\b(t?byte|[dqpftoyz]?word)\b//io;

			} elsif ( $par =~ /[^;]+\bqword\b/io ) {

				$par =~ s/^\s*$i\b/\t${i}q/i;
				$par =~ s/\b(t?byte|[dqpftoyz]?word)\b//io;

			} elsif ( $par =~ /^\s*$i\s+([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)/i ) {

				($a2 = $2) =~ s/\s+$//o;
				($a3 = $3) =~ s/\s+$//o;
				if ( $a3 !~ /\[.*\]/o ) {

					if ( is_reg8 ($a3) )    { $par =~ s/^\s*$i\b/\t${i}b/i; }
					elsif ( is_reg16($a3) ) { $par =~ s/^\s*$i\b/\t${i}w/i; }
					elsif ( is_reg32($a3) ) { $par =~ s/^\s*$i\b/\t${i}l/i; }
					elsif ( is_reg64($a3) ) { $par =~ s/^\s*$i\b/\t${i}q/i; }
					elsif ( $par =~ /^\s*$i\s+([^\[\],]+)\s*,\s*([^,]+)\s*,\s*([^,]+)/i ) {
						$a1 = $1;
						$a1 =~ s/\s+$//o;
						if ( is_reg8 ($a1) )    { $par =~ s/^\s*$i\b/\t${i}b/i; }
						elsif ( is_reg16($a1) ) { $par =~ s/^\s*$i\b/\t${i}w/i; }
						elsif ( is_reg32($a1) ) { $par =~ s/^\s*$i\b/\t${i}l/i; }
						elsif ( is_reg64($a1) ) { $par =~ s/^\s*$i\b/\t${i}q/i; }
						# (default: let the programmer decide)
						#else { $par =~ s/^\s*$i\b/\t${i}l/i; }
					}
					elsif ( $par =~ /^\s*$i\s+([^,]+)\s*,\s*([^\[\],]+)\s*,\s*([^,]+)/i ) {
						$a2 = $2;
						$a2 =~ s/\s+$//o;
						if ( is_reg8 ($a2) )    { $par =~ s/^\s*$i\b/\t${i}b/i; }
						elsif ( is_reg16($a2) ) { $par =~ s/^\s*$i\b/\t${i}w/i; }
						elsif ( is_reg32($a2) ) { $par =~ s/^\s*$i\b/\t${i}l/i; }
						elsif ( is_reg64($a2) ) { $par =~ s/^\s*$i\b/\t${i}q/i; }
						# (default: let the programmer decide)
						#else { $par =~ s/^\s*$i\b/\t${i}l/i; }
					}
					# taken care of by the first conditions
					#else {#if ( $par =~ /^\s*$i\s+([^,]+)\s*,\s*([^,]+),\s*([^\[\],]+)\s*/i ) {
						#$par =~ /^\s*$i\s+([^,]+)\s*,\s*([^,]+),\s*([^\[\],]+)\s*/i;
						#$a3 = $3;
						#$a3 =~ s/\s+$//o;
						#if ( is_reg8 ($a3) )    { $par =~ s/^\s*$i\b/\t${i}b/i; }
						#elsif ( is_reg16($a3) ) { $par =~ s/^\s*$i\b/\t${i}w/i; }
						#elsif ( is_reg32($a3) ) { $par =~ s/^\s*$i\b/\t${i}l/i; }
						#elsif ( is_reg64($a3) ) { $par =~ s/^\s*$i\b/\t${i}q/i; }
						# (default: let the programmer decide)
						#else { $par =~ s/^\s*$i\b/\t${i}l/i; }
					#} else {
						# (default: let the programmer decide)
						#$par =~ s/^\s*$i\b/\t${i}l/i;
					#}

				} elsif ( $a2 !~ /\[.*\]/o ) {

					if ( is_reg8 ($a2) )    { $par =~ s/^\s*$i\b/\t${i}b/i; }
					elsif ( is_reg16($a2) ) { $par =~ s/^\s*$i\b/\t${i}w/i; }
					elsif ( is_reg32($a2) ) { $par =~ s/^\s*$i\b/\t${i}l/i; }
					elsif ( is_reg64($a2) ) { $par =~ s/^\s*$i\b/\t${i}q/i; }
					elsif ( $par =~ /^\s*$i\s+([^\[\],]+)\s*,\s*([^,]+)\s*,\s*([^,]+)/i ) {
						$a1 = $1;
						$a1 =~ s/\s+$//o;
						if ( is_reg8 ($a1) )    { $par =~ s/^\s*$i\b/\t${i}b/i; }
						elsif ( is_reg16($a1) ) { $par =~ s/^\s*$i\b/\t${i}w/i; }
						elsif ( is_reg32($a1) ) { $par =~ s/^\s*$i\b/\t${i}l/i; }
						elsif ( is_reg64($a1) ) { $par =~ s/^\s*$i\b/\t${i}q/i; }
						# (default: let the programmer decide)
						#else { $par =~ s/^\s*$i\b/\t${i}l/i; }
					}
					# taken care of by the first conditions
					#else {#if ( $par =~ /^\s*$i\s+([^,]+)\s*,\s*([^\[\],]+)\s*,\s*([^,]+)/i ) {
						#$par =~ /^\s*$i\s+([^,]+)\s*,\s*([^\[\],]+)\s*,\s*([^,]+)/i;
						#$a1 = $2;
						#$a1 =~ s/\s+$//o;
						#if ( is_reg8 ($a1) )    { $par =~ s/^\s*$i\b/\t${i}b/i; }
						#elsif ( is_reg16($a1) ) { $par =~ s/^\s*$i\b/\t${i}w/i; }
						#elsif ( is_reg32($a1) ) { $par =~ s/^\s*$i\b/\t${i}l/i; }
						#elsif ( is_reg64($a1) ) { $par =~ s/^\s*$i\b/\t${i}q/i; }
						# (default: let the programmer decide)
						#else { $par =~ s/^\s*$i\b/\t${i}l/i; }
					#} else {
						# (default: let the programmer decide)
						#$par =~ s/^\s*$i\b/\t${i}l/i;
					#}

				} elsif ( $par =~ /^\s*$i\s+([^\[\],]+)\s*,\s*([^,]+)\s*,\s*([^,]+)/i ) {

					$a1 = $1;
					$a1 =~ s/\s+$//o;
					if ( is_reg8 ($a1) )    { $par =~ s/^\s*$i\b/\t${i}b/i; }
					elsif ( is_reg16($a1) ) { $par =~ s/^\s*$i\b/\t${i}w/i; }
					elsif ( is_reg32($a1) ) { $par =~ s/^\s*$i\b/\t${i}l/i; }
					elsif ( is_reg64($a1) ) { $par =~ s/^\s*$i\b/\t${i}q/i; }
					# (default: let the programmer decide)
					#else { $par =~ s/^\s*$i\b/\t${i}l/i; }

				#} else {
					# (default: let the programmer decide)
					#$par =~ s/^\s*$i\b/\t${i}l/i;
				}
			} elsif ( $par =~ /^\s*$i\s+([^,]+)\s*,\s*([^,]+)/i ) {

				($a2 = $2) =~ s/\s+$//o;
				if ( $a2 !~ /\[.*\]/o ) {

					if ( is_reg8 ($a2) )    { $par =~ s/^\s*$i\b/\t${i}b/i; }
					elsif ( is_reg16($a2) ) { $par =~ s/^\s*$i\b/\t${i}w/i; }
					elsif ( is_reg32($a2) ) { $par =~ s/^\s*$i\b/\t${i}l/i; }
					elsif ( is_reg64($a2) ) { $par =~ s/^\s*$i\b/\t${i}q/i; }
					elsif ( $par =~ /^\s*$i\s+([^\[\],]+)\s*,\s*([^,]+)/i ) {
						$a1 = $1;
						$a1 =~ s/\s+$//o;
						if ( is_reg8 ($a1) )    { $par =~ s/^\s*$i\b/\t${i}b/i; }
						elsif ( is_reg16($a1) ) { $par =~ s/^\s*$i\b/\t${i}w/i; }
						elsif ( is_reg32($a1) ) { $par =~ s/^\s*$i\b/\t${i}l/i; }
						elsif ( is_reg64($a1) ) { $par =~ s/^\s*$i\b/\t${i}q/i; }
						# (default: let the programmer decide)
						#else { $par =~ s/^\s*$i\b/\t${i}l/i; }
					}
					# taken care of by the first conditions
					#else {#if ( $par =~ /^\s*$i\s+([^,]+)\s*,\s*([^\[\],]+)/i ) {
						#$a1 = $2;
						#$a1 =~ s/\s+$//o;
						#if ( is_reg8 ($a1) )    { $par =~ s/^\s*$i\b/\t${i}b/i; }
						#elsif ( is_reg16($a1) ) { $par =~ s/^\s*$i\b/\t${i}w/i; }
						#elsif ( is_reg32($a1) ) { $par =~ s/^\s*$i\b/\t${i}l/i; }
						#elsif ( is_reg64($a1) ) { $par =~ s/^\s*$i\b/\t${i}q/i; }
						# (default: let the programmer decide)
						#else { $par =~ s/^\s*$i\b/\t${i}l/i; }
					#} else {
						# (default: let the programmer decide)
						#$par =~ s/^\s*$i\b/\t${i}l/i;
					#}

				} elsif ( $par =~ /^\s*$i\s+([^\[\],]+)\s*,\s*([^,]+)/i ) {

					$a1 = $1;
					$a1 =~ s/\s+$//o;
					if ( is_reg8 ($a1) )    { $par =~ s/^\s*$i\b/\t${i}b/i; }
					elsif ( is_reg16($a1) ) { $par =~ s/^\s*$i\b/\t${i}w/i; }
					elsif ( is_reg32($a1) ) { $par =~ s/^\s*$i\b/\t${i}l/i; }
					elsif ( is_reg64($a1) ) { $par =~ s/^\s*$i\b/\t${i}q/i; }
					# (default: let the programmer decide)
					#else { $par =~ s/^\s*$i\b/\t${i}l/i; }

				#} else {
					# (default: let the programmer decide)
					#$par =~ s/^\s*$i\b/\t${i}l/i;
				}
			} else { #if ( $par =~ /^\s*$i\s+([^,]+)\s*/i ) {

				$par =~ /^\s*$i\s+([^,]+)\s*/i;
				($a1 = $1) =~ s/\s+$//o;
				if ( is_reg8 ($a1) )    { $par =~ s/^\s*$i\b/\t${i}b/i; }
				elsif ( is_reg16($a1) ) { $par =~ s/^\s*$i\b/\t${i}w/i; }
				elsif ( is_reg32($a1) ) { $par =~ s/^\s*$i\b/\t${i}l/i; }
				elsif ( is_reg64($a1) ) { $par =~ s/^\s*$i\b/\t${i}q/i; }
				#else {
					# (default: let the programmer decide)
					#$par =~ s/^\s*$i\b/\t${i}l/i;
				#}

			#} else {
				# (default: long)
				# unreachable code
				#$par =~ s/^\s*$i\b/\t${i}l/i;
			}
			last;
		}
	}

	# (add suffixes to MOVSX/MOVZX instructions)
	if ( $par =~ /^\s*(mov[sz])x\s+([^,]+)\s*,\s*([^,]+)(.*)/io ) {

		my ($inst, $arg1, $arg2, $rest, $z1, $z2);
		$inst = $1;
		$z1 = $2;
		$z2 = $3;
		$rest = $4;
		($arg1 = $z1) =~ s/\s*$//o;
		($arg2 = $z2) =~ s/\s*$//o;
		# operand order is changed later
		if ( ($par =~ /\bbyte\b/io || is_reg8($arg2) ) && is_reg32($arg1) ) {
			$par = "\t${inst}bl\t$arg1, $arg2 $rest\n";
		} elsif ( ($par =~ /\bbyte\b/io || is_reg8($arg2) ) && is_reg16($arg1) ) {
			$par = "\t${inst}bw\t$arg1, $arg2 $rest\n";
		} elsif ( ($par =~ /\bword\b/io || is_reg16($arg2)) && is_reg32($arg1)  ) {
			$par = "\t${inst}wl\t$arg1, $arg2 $rest\n";
		} elsif ( ($par =~ /\bbyte\b/io || is_reg8($arg2)) && is_reg64($arg1)  ) {
			$par = "\t${inst}bq\t$arg1, $arg2 $rest\n";
		} elsif ( ($par =~ /\bword\b/io || is_reg16($arg2)) && is_reg64($arg1)  ) {
			$par = "\t${inst}wq\t$arg1, $arg2 $rest\n";
		}
		# if we can't decide on register sizes, leave it for the programmer to fix
	}

	# (changing operands' order):
	my $i_3op = qr/^\s*(\w+)\s+((t?byte|[dqpftoyz]?word)?\s*\[?[\.\w\*\+\-\s\(\)\[\]]+\]?)\s*,\s*((t?byte|[dqpftoyz]?word)?\s*\[?[\.\w\*\+\-\s\(\)\[\]]+\]?)\s*,\s*((t?byte|[dqpftoyz]?word)?\s*\[?[\.\w\*\+\-\s\(\)\[\]]+\]?)/o;
	my $i_2op = qr/^\s*(\w+)\s+((t?byte|[dqpftoyz]?word)?\s*\[?[\.\w\*\+\-\s\(\)\[\]]+\]?)\s*,\s*((t?byte|[dqpftoyz]?word)?\s*\[?[\.\w\*\+\-\s\(\)\[\]]+\]?)([^,]*(;.*)?)$/o;
	my $i_1op = qr/^\s*(\w+)\s+((t?byte|[dqpftoyz]?word)?\s*\[?[\.\w\*\+\-\s\(\)\[\]]+\]?)([^,]*(;.*)?)$/o;
	if ( $par =~ /$i_3op/ ) {
		if ( is_instr($1) ) {
			$par =~ s/$i_3op/\t$1\t$6, $4, $2/;
		}
	}
	if ( $par =~ /$i_2op/ ) {
		if ( is_instr($1) ) {
			$par =~ s/$i_2op/\t$1\t$4, $2$6\n/;
		}
	}
	if ( $par =~ /$i_1op/ ) {
		if ( is_instr($1) ) {
			$par =~ s/$i_1op/\t$1\t$2$4\n/;
		}
	}

	# (FPU instructions)
	$par =~ s/^\s*fi(\w+)\s+word\s*(.*)/\tfi${1}s\t$2/io;
	$par =~ s/^\s*fi(\w+)\s+dword\s*(.*)/\tfi${1}l\t$2/io;
	$par =~ s/^\s*fi(\w+)\s+qword\s*(.*)/\tfi${1}q\t$2/io;

	$par =~ s/^\s*f([^iI]\w+)\s+dword\s*(.*)/\tf${1}s\t$2/io;
	$par =~ s/^\s*f([^iI]\w+)\s+qword\s*(.*)/\tf${1}l\t$2/io;
	$par =~ s/^\s*f([^iI]\w+)\s+t(word|byte)\s*(.*)/\tf${1}t\t$3/io;

	# (change "xxx" to "$xxx", if there are no "[]")
	# (don't touch "call/jmp xxx")
	if ( $par !~ /^\s*(j[a-z]+|call)/io ) {

		if ( $par =~ /^\s*(\w+)\s+([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*/gio ) {

			$a1 = $1;
			$a1 =~ s/\s+$//o;
			$a2 = _remove_size_qualifiers_add_dollar ($2);
			$a3 = _remove_size_qualifiers_add_dollar ($3);
			$a4 = _remove_size_qualifiers_add_dollar ($4);

			$par = "\t$a1\t$a2, $a3, $a4\n";

		} elsif ( $par =~ /^\s*(\w+)\s+([^,]+)\s*,\s*([^,]+)\s*/gio ) {

			$a1 = $1;
			$a1 =~ s/\s+$//o;
			$a2 = _remove_size_qualifiers_add_dollar ($2);
			$a3 = _remove_size_qualifiers_add_dollar ($3);

			$par = "\t$a1\t$a2, $a3\n";

		} elsif ( $par =~ /^\s*(\w+)\s+([^,]+)\s*/gio ) {

			$a1 = $1;
			$a1 =~ s/\s+$//o;
			$a2 = _remove_size_qualifiers_add_dollar ($2);

			$par = "\t$a1\t$a2\n";
		}
	}

	$par =~ s/^\s*cbw\b/\tcbtw/io;
	$par =~ s/^\s*cwde\b/\tcwtl/io;
	$par =~ s/^\s*cwd\b/\tcwtd/io;
	$par =~ s/^\s*cdq\b/\tcltd/io;

	# (adding asterisk chars)
	$par =~ s/^\s*(jmp|call)\s+([dp]word|word|near|far|short)?\s*(\[[\w\*\+\-\s]+\])/\t$1\t*$3/io;
	$par =~ s/^\s*(jmp|call)\s+([dp]word|word|near|far|short)?\s*((0x)?\d+h?)/\t$1\t*$3/io;
	$par =~ s/^\s*(jmp|call)\s+([dp]word|word|near|far|short)?\s*([\w\*\+\-\s]+)/\t$1\t$3/io;
	$par =~ s/^\s*(jmp|call)\s+([^:]+)\s*:\s*([^:]+)/\tl$1\t$2, $3/io;
	$par =~ s/^\s*retf\s+(.*)$/\tlret\t$1/io;

	# (changing memory references):
	$par = conv_intel_addr_to_att $par;

	# (changing "stN" to "st(N)")
	$par =~ s/\bst(\d)\b/\%st($1)/go;

	# (adding percent chars)
	foreach my $r (@regs_intel) {

		$par =~ s/\b$r\b/\%$r/gi;
	}
	foreach my $r (@regs_intel) {

		$par =~ s/\%\%$r\b/\%$r/gi;
	}

	# (REP**: adding the end of line char)
	$par =~ s/^\s*(rep[enz]{0,2})\s+/\t$1\n\t/io;

	return $par;
}

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the perldoc command.

    perldoc Asm::X86

You can also look for information at:

    Search CPAN
        https://metacpan.org/dist/Asm-X86

    CPAN Request Tracker:
        https://rt.cpan.org/Public/Dist/Display.html?Name=Asm-X86

=head1 AUTHOR

Bogdan Drozdowski, C<< <bogdro at cpan.org> >>

=head1 COPYRIGHT

Copyright 2008-2024 Bogdan Drozdowski, all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Asm::X86
