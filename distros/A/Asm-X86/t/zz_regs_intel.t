#!/usr/bin/perl -T -w

use strict;
use warnings;

use Test::More;
use Asm::X86 qw(
	@regs8_intel @regs16_intel @segregs_intel @regs32_intel @regs64_intel
	@regs_mm_intel @regs_intel @regs_fpu_intel @regs_opmask_intel

	is_reg_intel is_reg8_intel is_reg16_intel is_reg32_intel is_reg64_intel
	is_reg_mm_intel is_segreg_intel is_reg_fpu_intel is_reg_opmask_intel
	is_addressable32_intel is_r32_in64_intel

	is_reg_att is_reg8_att is_reg16_att is_reg32_att is_reg64_att
	is_reg_mm_att is_segreg_att is_reg_fpu_att is_reg_opmask_att
	is_addressable32_att is_r32_in64_att

	is_reg is_reg8 is_reg16 is_reg32 is_reg64
	is_reg_mm is_segreg is_reg_fpu is_reg_opmask
	is_addressable32 is_r32_in64
);

my @addressable32 = (
		'eax',	'ebx', 'ecx', 'edx', 'esi', 'edi', 'esp', 'ebp',
);

my @r32_in64 = (
		'r8d', 'r8l', 'r9d', 'r9l', 'r10d', 'r10l', 'r11d', 'r11l',
		'r12d', 'r12l', 'r13d', 'r13l', 'r14d', 'r14l', 'r15d', 'r15l',
);

my @invalid_regs = ('axmm6', 'cax', 'abx', 'dal', 'ald', 'rsid',
	'eabx', 'ceax', 'ebxc', 'amm1', 'mm30', 'r15db',
	'ar15d', 'ads', 'esx', 'ast0',
	'st5b', 'k02', 'cal', 'dax', 'reax', 'amm0', 'xmm',
	'ymm', 'zmm', 'k12', 'axh', 'eaxl', 'r10ld', 'mm0l',
	'xmm0d', 'ymm0l', 'zmm0d', 'k3l', '[eax', 'eax]'
);

# Test::More:
plan tests => 9
	+ (@regs8_intel + 1) * 33
	+ (@regs16_intel + 1) * 31 + 33
	+ (@regs32_intel + 1) * 29 + 31 + 31
	+ (@regs64_intel + 1) * 33
	+ (@regs_mm_intel + 4) * 33
	+ (@regs_fpu_intel + 1) * 33
	+ (@segregs_intel + 1) * 33
	+ (@regs_opmask_intel + 1) * 33
	+ @addressable32 * 33
	+ (@r32_in64 + 1) * 33
	+ @invalid_regs * 33
	;

cmp_ok ( $#regs8_intel,   '>', 0, 'Non-empty 8-bit register list' );
cmp_ok ( $#regs16_intel,  '>', 0, 'Non-empty 16-bit register list' );
cmp_ok ( $#segregs_intel, '>', 0, 'Non-empty segment register list' );
cmp_ok ( $#regs32_intel,  '>', 0, 'Non-empty 32-bit register list' );
cmp_ok ( $#regs64_intel,  '>', 0, 'Non-empty 64-bit register list' );
cmp_ok ( $#regs_mm_intel, '>', 0, 'Non-empty multimedia register list' );
cmp_ok ( $#regs_fpu_intel,'>', 0, 'Non-empty FPU register list' );
cmp_ok ( $#regs_opmask_intel,'>', 0, 'Non-empty opmask register list' );
cmp_ok ( $#regs_intel,    '>', 0, 'Non-empty register list' );

my ($name_reg, $name_reg8, $name_reg16, $name_reg32, $name_reg64,
	$name_reg_mm, $name_reg_seg, $name_reg_fpu, $name_reg_opmask,
	$name_reg_add32, $name_reg32_64)
= ('reg', 'reg8', 'reg16', 'reg32', 'reg64', 'regmm', 'segreg', 'fpureg',
	'opmaskreg', 'reg_address32', 'reg32_in_64');

sub check_reg_intel($$) {

	my $regs = shift;
	my $types = shift;
	foreach my $r (@$regs) {

		is ( is_reg_intel ($r), $$types{$name_reg}, "'$r' is a valid Intel-syntax register" ) if defined $$types{$name_reg};
		is ( is_reg8_intel ($r), $$types{$name_reg8}, "'$r' is a valid Intel-syntax 8-bit register" ) if defined $$types{$name_reg8};
		is ( is_reg16_intel ($r), $$types{$name_reg16}, "'$r' is a valid Intel-syntax 16-bit register" ) if defined $$types{$name_reg16};
		is ( is_reg32_intel ($r), $$types{$name_reg32}, "'$r' is a valid Intel-syntax 32-bit register" ) if defined $$types{$name_reg32};
		is ( is_reg64_intel ($r), $$types{$name_reg64}, "'$r' is a valid Intel-syntax 64-bit register" ) if defined $$types{$name_reg64};
		is ( is_reg_mm_intel ($r), $$types{$name_reg_mm}, "'$r' is a valid Intel-syntax multimedia register" ) if defined $$types{$name_reg_mm};
		is ( is_segreg_intel ($r), $$types{$name_reg_seg}, "'$r' is a valid Intel-syntax segment register" ) if defined $$types{$name_reg_seg};
		is ( is_reg_fpu_intel ($r), $$types{$name_reg_fpu}, "'$r' is a valid Intel-syntax FPU register" ) if defined $$types{$name_reg_fpu};
		is ( is_reg_opmask_intel ($r), $$types{$name_reg_opmask}, "'$r' is a valid Intel-syntax opmask register" )
			if defined $$types{$name_reg_opmask};
		is ( is_addressable32_intel ($r), $$types{$name_reg_add32}, "'$r' is a valid Intel-syntax 32-bit register which can be used for 32-bit addressing" )
			if defined $$types{$name_reg_add32};
		is ( is_r32_in64_intel ($r), $$types{$name_reg32_64}, "'$r' is a valid Intel-syntax 32-in-64-bit register" )
			if defined $$types{$name_reg32_64};

		# always invalid in AT&T syntax:
		is ( is_reg_att ($r), 0, "'$r' is a valid AT&T-syntax register" );
		is ( is_reg8_att ($r), 0, "'$r' is a valid AT&T-syntax 8-bit register" );
		is ( is_reg16_att ($r), 0, "'$r' is a valid AT&T-syntax 16-bit register" );
		is ( is_reg32_att ($r), 0, "'$r' is a valid AT&T-syntax 32-bit register" );
		is ( is_reg64_att ($r), 0, "'$r' is a valid AT&T-syntax 64-bit register" );
		is ( is_reg_mm_att ($r), 0, "'$r' is a valid AT&T-syntax multimedia register" );
		is ( is_segreg_att ($r), 0, "'$r' is a valid AT&T-syntax segment register" );
		is ( is_reg_fpu_att ($r), 0, "'$r' is a valid AT&T-syntax FPU register" );
		is ( is_reg_opmask_att ($r), 0, "'$r' is a valid AT&T-syntax opmask register" );
		is ( is_addressable32_att ($r), 0, "'$r' is a valid AT&T-syntax 32-bit register which can be used for 32-bit addressing" );
		is ( is_r32_in64_att ($r), 0, "'$r' is a valid AT&T-syntax 32-in-64-bit register" );

		is ( is_reg ($r), $$types{$name_reg}, "'$r' is a valid register" ) if defined $$types{$name_reg};
		is ( is_reg8 ($r), $$types{$name_reg8}, "'$r' is a valid 8-bit register" ) if defined $$types{$name_reg8};
		is ( is_reg16 ($r), $$types{$name_reg16}, "'$r' is a valid 16-bit register" ) if defined $$types{$name_reg16};
		is ( is_reg32 ($r), $$types{$name_reg32}, "'$r' is a valid 32-bit register" ) if defined $$types{$name_reg32};
		is ( is_reg64 ($r), $$types{$name_reg64}, "'$r' is a valid 64-bit register" ) if defined $$types{$name_reg64};
		is ( is_reg_mm ($r), $$types{$name_reg_mm}, "'$r' is a valid multimedia register" ) if defined $$types{$name_reg_mm};
		is ( is_segreg ($r), $$types{$name_reg_seg}, "'$r' is a valid segment register" ) if defined $$types{$name_reg_seg};
		is ( is_reg_fpu ($r), $$types{$name_reg_fpu}, "'$r' is a valid FPU register" ) if defined $$types{$name_reg_fpu};
		is ( is_reg_opmask ($r), $$types{$name_reg_opmask}, "'$r' is a valid opmask register" ) if defined $$types{$name_reg_opmask};
		is ( is_addressable32 ($r), $$types{$name_reg_add32}, "'$r' is a valid 32-bit register which can be used for 32-bit addressing" )
			if defined $$types{$name_reg_add32};
		is ( is_r32_in64 ($r), $$types{$name_reg32_64}, "'$r' is a valid 32-in-64-bit register" ) if defined $$types{$name_reg32_64};
	}
}

my %reg_tests = ();

# NOTE: we add some default example register to (almost) each group
# to avoid the case when something bad happens to the exported array.

$reg_tests{$name_reg} = 1;
$reg_tests{$name_reg8} = 1;
$reg_tests{$name_reg16} = 0;
$reg_tests{$name_reg32} = 0;
$reg_tests{$name_reg64} = 0;
$reg_tests{$name_reg_mm} = 0;
$reg_tests{$name_reg_seg} = 0;
$reg_tests{$name_reg_fpu} = 0;
$reg_tests{$name_reg_opmask} = 0;
$reg_tests{$name_reg_add32} = 0;
$reg_tests{$name_reg32_64} = 0;

check_reg_intel ([@regs8_intel, 'al'], \%reg_tests);

$reg_tests{$name_reg} = 1;
$reg_tests{$name_reg8} = 0;
$reg_tests{$name_reg16} = 1;
$reg_tests{$name_reg32} = 0;
$reg_tests{$name_reg64} = 0;
$reg_tests{$name_reg_mm} = 0;
# NOTE: some 16-bit registers are segment registers
$reg_tests{$name_reg_seg} = undef;
$reg_tests{$name_reg_fpu} = 0;
$reg_tests{$name_reg_opmask} = 0;
$reg_tests{$name_reg_add32} = 0;
$reg_tests{$name_reg32_64} = 0;

check_reg_intel ([@regs16_intel, 'ax'], \%reg_tests);

$reg_tests{$name_reg_seg} = 1;

check_reg_intel (['cs'], \%reg_tests);

$reg_tests{$name_reg} = 1;
$reg_tests{$name_reg8} = 0;
$reg_tests{$name_reg16} = 0;
$reg_tests{$name_reg32} = 1;
$reg_tests{$name_reg64} = 0;
$reg_tests{$name_reg_mm} = 0;
$reg_tests{$name_reg_seg} = 0;
$reg_tests{$name_reg_fpu} = 0;
$reg_tests{$name_reg_opmask} = 0;
# NOTE: most 32-bit general-purpose registers can be used for addressing
# NOTE: some 32-bit registers are parts of 64-bit registers
$reg_tests{$name_reg_add32} = undef;
$reg_tests{$name_reg32_64} = undef;

check_reg_intel ([@regs32_intel, 'eax'], \%reg_tests);

$reg_tests{$name_reg_add32} = 1;

check_reg_intel (['ebx'], \%reg_tests);

$reg_tests{$name_reg_add32} = undef;
$reg_tests{$name_reg32_64} = 1;

check_reg_intel (['r9d'], \%reg_tests);

$reg_tests{$name_reg} = 1;
$reg_tests{$name_reg8} = 0;
$reg_tests{$name_reg16} = 0;
$reg_tests{$name_reg32} = 0;
$reg_tests{$name_reg64} = 1;
$reg_tests{$name_reg_mm} = 0;
$reg_tests{$name_reg_seg} = 0;
$reg_tests{$name_reg_fpu} = 0;
$reg_tests{$name_reg_opmask} = 0;
$reg_tests{$name_reg_add32} = 0;
$reg_tests{$name_reg32_64} = 0;

check_reg_intel ([@regs64_intel, 'rax'], \%reg_tests);

$reg_tests{$name_reg} = 1;
$reg_tests{$name_reg8} = 0;
$reg_tests{$name_reg16} = 0;
$reg_tests{$name_reg32} = 0;
$reg_tests{$name_reg64} = 0;
$reg_tests{$name_reg_mm} = 1;
$reg_tests{$name_reg_seg} = 0;
$reg_tests{$name_reg_fpu} = 0;
$reg_tests{$name_reg_opmask} = 0;
$reg_tests{$name_reg_add32} = 0;
$reg_tests{$name_reg32_64} = 0;

check_reg_intel ([@regs_mm_intel, 'mm0', 'xmm0', 'ymm0', 'zmm0'], \%reg_tests);

$reg_tests{$name_reg} = 1;
$reg_tests{$name_reg8} = 0;
$reg_tests{$name_reg16} = 0;
$reg_tests{$name_reg32} = 0;
$reg_tests{$name_reg64} = 0;
$reg_tests{$name_reg_mm} = 0;
$reg_tests{$name_reg_seg} = 0;
$reg_tests{$name_reg_fpu} = 1;
$reg_tests{$name_reg_opmask} = 0;
$reg_tests{$name_reg_add32} = 0;
$reg_tests{$name_reg32_64} = 0;

check_reg_intel ([@regs_fpu_intel, 'st0'], \%reg_tests);

$reg_tests{$name_reg} = 1;
$reg_tests{$name_reg8} = 0;
$reg_tests{$name_reg16} = 1;
$reg_tests{$name_reg32} = 0;
$reg_tests{$name_reg64} = 0;
$reg_tests{$name_reg_mm} = 0;
$reg_tests{$name_reg_seg} = 1;
$reg_tests{$name_reg_fpu} = 0;
$reg_tests{$name_reg_opmask} = 0;
$reg_tests{$name_reg_add32} = 0;
$reg_tests{$name_reg32_64} = 0;

check_reg_intel ([@segregs_intel, 'cs'], \%reg_tests);

$reg_tests{$name_reg} = 1;
$reg_tests{$name_reg8} = 0;
$reg_tests{$name_reg16} = 0;
$reg_tests{$name_reg32} = 0;
$reg_tests{$name_reg64} = 0;
$reg_tests{$name_reg_mm} = 0;
$reg_tests{$name_reg_seg} = 0;
$reg_tests{$name_reg_fpu} = 0;
$reg_tests{$name_reg_opmask} = 1;
$reg_tests{$name_reg_add32} = 0;
$reg_tests{$name_reg32_64} = 0;

check_reg_intel ([@regs_opmask_intel, 'k0'], \%reg_tests);

$reg_tests{$name_reg} = 1;
$reg_tests{$name_reg8} = 0;
$reg_tests{$name_reg16} = 0;
$reg_tests{$name_reg32} = 1;
$reg_tests{$name_reg64} = 0;
$reg_tests{$name_reg_mm} = 0;
$reg_tests{$name_reg_seg} = 0;
$reg_tests{$name_reg_fpu} = 0;
$reg_tests{$name_reg_opmask} = 0;
$reg_tests{$name_reg_add32} = 1;
$reg_tests{$name_reg32_64} = 0;

check_reg_intel (\@addressable32, \%reg_tests);

$reg_tests{$name_reg} = 1;
$reg_tests{$name_reg8} = 0;
$reg_tests{$name_reg16} = 0;
$reg_tests{$name_reg32} = 1;
$reg_tests{$name_reg64} = 0;
$reg_tests{$name_reg_mm} = 0;
$reg_tests{$name_reg_seg} = 0;
$reg_tests{$name_reg_fpu} = 0;
$reg_tests{$name_reg_opmask} = 0;
$reg_tests{$name_reg_add32} = 0;
$reg_tests{$name_reg32_64} = 1;

check_reg_intel ([@r32_in64, 'r10d'], \%reg_tests);

$reg_tests{$name_reg} = 0;
$reg_tests{$name_reg8} = 0;
$reg_tests{$name_reg16} = 0;
$reg_tests{$name_reg32} = 0;
$reg_tests{$name_reg64} = 0;
$reg_tests{$name_reg_mm} = 0;
$reg_tests{$name_reg_seg} = 0;
$reg_tests{$name_reg_fpu} = 0;
$reg_tests{$name_reg_opmask} = 0;
$reg_tests{$name_reg_add32} = 0;
$reg_tests{$name_reg32_64} = 0;

check_reg_intel (\@invalid_regs, \%reg_tests);
