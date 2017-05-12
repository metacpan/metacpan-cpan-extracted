#!perl -T -w

use strict;
use warnings;

use Test::More tests => 8;
use Asm::X86 qw(
	conv_att_addr_to_intel conv_intel_addr_to_att
	conv_att_instr_to_intel conv_intel_instr_to_att
	);

# NOTE: these routines have already been well tested in the fasm2gas, nasm2gas,
#	gas2fasm and gas2nasm scripts

is ( conv_intel_instr_to_att ('mov eax, [ecx+ebx*2+-1]') =~
	/^\s*movl.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%eax\s*$/i, 1, 'mov test' );
is ( conv_att_instr_to_intel ('addl	%eax, %ebx') =~
	/^\s*add\s*(dword)?\s*ebx,\s*eax\s*$/i, 1, 'add test' );
is ( conv_att_instr_to_intel ('subb	(%esi), %bl') =~
	/^\s*sub\s*(byte)?\s*bl,\s*\[esi\]\s*$/i, 1, 'sub test' );
is ( conv_intel_instr_to_att ('inc word ptr [si]') =~
	/^\s*incw\s*\(\%si\)\s*$/i, 1, 'inc test' );

is ( conv_att_addr_to_intel ('-8(%esi,%ebp,4)') =~
	/^\s*\[\s*esi\s*\+\s*ebp\s*\*\s*4\s*\+*-8\s*\]\s*$/i, 1, 'AT&T->Intel mem test 1' );
is ( conv_intel_addr_to_att ('[eax+esi*2+7]') =~
	/^\s*\(\+*7\)\(\s*%eax\s*,\s*%esi\s*,\s*2\s*\)\s*$/i, 1, 'Intel->AT&T mem test 1' );
is ( conv_att_addr_to_intel ('(,%ebp,8)') =~
	/^\s*\[\s*ebp\s*\*\s*8\s*]\s*$/i, 1, 'AT&T->Intel mem test 2' );
is ( conv_intel_addr_to_att ('[ebx-9]') =~
	/^\s*\(\+*-9\)\(\s*%ebx\s*\)\s*$/i, 1, 'Intel->AT&T mem test 2' );

