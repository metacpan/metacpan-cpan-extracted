#!/usr/bin/perl -w
# Asm::X86 - a test for conversion routines.
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

use strict;
use warnings;

use Test::More;
use Asm::X86 qw(
	conv_att_addr_to_intel conv_intel_addr_to_att
	conv_att_instr_to_intel conv_intel_instr_to_att
	add_att_suffix_instr
	);

# NOTE: some instructions are invalid on purpose, to test the various
# syntax elements and regular expressions
my %intel_instr_to_att;

$intel_instr_to_att{'mov al, byte [ecx+ebx*2+-1]'} = qr/^\s*movb.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%al\s*$/io;
$intel_instr_to_att{'mov al, [ecx+ebx*2+-1]'} = qr/^\s*movb.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%al\s*$/io;
$intel_instr_to_att{'mov ax, word [ecx+ebx*2+-1]'} = qr/^\s*movw.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%ax\s*$/io;
$intel_instr_to_att{'mov ax, [ecx+ebx*2+-1]'} = qr/^\s*movw.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%ax\s*$/io;
$intel_instr_to_att{'mov eax, dword [ecx+ebx*2+-1]'} = qr/^\s*movl.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%eax\s*$/io;
$intel_instr_to_att{'mov eax, [ecx+ebx*2+-1]'} = qr/^\s*movl.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%eax\s*$/io;
$intel_instr_to_att{'mov rax, qword [ecx+ebx*2+-1]'} = qr/^\s*movq.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%rax\s*$/io;
$intel_instr_to_att{'mov rax, [ecx+ebx*2+-1]'} = qr/^\s*movq.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%rax\s*$/io;

$intel_instr_to_att{'mov byte [ecx+ebx*2+-1], al'} = qr/^\s*movb\s*\%al\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io;
$intel_instr_to_att{'mov [ecx+ebx*2+-1], al'} = qr/^\s*movb\s*\%al\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io;
$intel_instr_to_att{'mov word [ecx+ebx*2+-1], ax'} = qr/^\s*movw\s*\%ax\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io;
$intel_instr_to_att{'mov [ecx+ebx*2+-1], ax'} = qr/^\s*movw\s*\%ax\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io;
$intel_instr_to_att{'mov dword [ecx+ebx*2+-1], eax'} = qr/^\s*movl\s*\%eax\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io;
$intel_instr_to_att{'mov [ecx+ebx*2+-1], eax'} = qr/^\s*movl\s*\%eax\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io;
$intel_instr_to_att{'mov qword [ecx+ebx*2+-1], rax'} = qr/^\s*movq\s*\%rax\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io;
$intel_instr_to_att{'mov [ecx+ebx*2+-1], rax'} = qr/^\s*movq\s*\%rax\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io;
$intel_instr_to_att{'mov [ecx+ebx*2+-1], [eax]'} = qr/^\s*mov\s*\[\%eax\]\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io;

$intel_instr_to_att{'inc byte ptr [si]'} = qr/^\s*incb\s*\(\%si\)\s*$/io;
$intel_instr_to_att{'inc word ptr [si]'} = qr/^\s*incw\s*\(\%si\)\s*$/io;
$intel_instr_to_att{'inc dword ptr [si]'} = qr/^\s*incl\s*\(\%si\)\s*$/io;
$intel_instr_to_att{'inc qword ptr [rsi]'} = qr/^\s*incq\s*\(\%rsi\)\s*$/io;

$intel_instr_to_att{'inc al'} = qr/^\s*incb\s*\%al\s*$/io;
$intel_instr_to_att{'inc ax'} = qr/^\s*incw\s*\%ax\s*$/io;
$intel_instr_to_att{'inc eax'} = qr/^\s*incl\s*\%eax\s*$/io;
$intel_instr_to_att{'inc rax'} = qr/^\s*incq\s*\%rax\s*$/io;
$intel_instr_to_att{'inc zzz'} = qr/^\s*inc\s*\$zzz\s*$/io;

$intel_instr_to_att{'pop'} = qr/^\s*pop\s*$/io;

$intel_instr_to_att{'imul eax, ebx, 2'} = qr/^\s*imull\s*\$2\s*,\s*%ebx\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, [ebx], 2'} = qr/^\s*imull\s*\$2\s*,\s*\(%ebx\)\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul [eax], ebx, 2'} = qr/^\s*imull\s*\$2\s*,\s*%ebx\s*,\s*\(%eax\)\s*$/io;
$intel_instr_to_att{'imul [eax], [ebx], 2'} = qr/^\s*imul\s*\$2\s*,\s*\(%ebx\)\s*,\s*\[%eax\]\s*$/io;

$intel_instr_to_att{'imul eax, 2, ebx'} = qr/^\s*imull\s*%ebx\s*,\s*\$2\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, 2, [ebx]'} = qr/^\s*imull\s*\(%ebx\)\s*,\s*\$2\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul [eax], 2, ebx'} = qr/^\s*imull\s*%ebx\s*,\s*\$2\s*,\s*\(%eax\)\s*$/io;
$intel_instr_to_att{'imul [eax], 2, [ebx]'} = qr/^\s*imul\s*\(%ebx\)\s*,\s*\$2\s*,\s*\[%eax\]\s*$/io;

$intel_instr_to_att{'imul 2, eax, ebx'} = qr/^\s*imull\s*%ebx\s*,\s*%eax\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, eax, [ebx]'} = qr/^\s*imull\s*\(%ebx\)\s*,\s*%eax\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, [eax], ebx'} = qr/^\s*imull\s*%ebx\s*,\s*\(%eax\)\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, [eax], [ebx]'} = qr/^\s*imul\s*\(%ebx\)\s*,\s*\[%eax\]\s*,\s*\$2\s*$/io;

$intel_instr_to_att{'imul eax, bl, [ebx]'} = qr/^\s*imulb\s*\(%ebx\)\s*,\s*%bl\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, bx, [ebx]'} = qr/^\s*imulw\s*\(%ebx\)\s*,\s*%bx\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, ebx, [ebx]'} = qr/^\s*imull\s*\(%ebx\)\s*,\s*%ebx\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, rbx, [ebx]'} = qr/^\s*imulq\s*\(%ebx\)\s*,\s*%rbx\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, zzz, [ebx]'} = qr/^\s*imull\s*\(%ebx\)\s*,\s*\$zzz\s*,\s*%eax\s*$/io;

$intel_instr_to_att{'imul [eax], bl, [ebx]'} = qr/^\s*imulb\s*\(%ebx\)\s*,\s*%bl\s*,\s*\[%eax\]\s*$/io;
$intel_instr_to_att{'imul [eax], bx, [ebx]'} = qr/^\s*imulw\s*\(%ebx\)\s*,\s*%bx\s*,\s*\[%eax\]\s*$/io;
$intel_instr_to_att{'imul [eax], ebx, [ebx]'} = qr/^\s*imull\s*\(%ebx\)\s*,\s*%ebx\s*,\s*\[%eax\]\s*$/io;
$intel_instr_to_att{'imul [eax], rbx, [ebx]'} = qr/^\s*imulq\s*\(%ebx\)\s*,\s*%rbx\s*,\s*\[%eax\]\s*$/io;
$intel_instr_to_att{'imul [eax], zzz, [ebx]'} = qr/^\s*imul\s*\(%ebx\)\s*,\s*\$zzz\s*,\s*\[%eax\]\s*$/io;

$intel_instr_to_att{'imul bl, [eax], [ebx]'} = qr/^\s*imulb\s*\(%ebx\)\s*,\s*\[%eax\]\s*,\s*%bl\s*$/io;
$intel_instr_to_att{'imul bx, [eax], [ebx]'} = qr/^\s*imulw\s*\(%ebx\)\s*,\s*\[%eax\]\s*,\s*%bx\s*$/io;
$intel_instr_to_att{'imul ebx, [eax], [ebx]'} = qr/^\s*imull\s*\(%ebx\)\s*,\s*\[%eax\]\s*,\s*%ebx\s*$/io;
$intel_instr_to_att{'imul rbx, [eax], [ebx]'} = qr/^\s*imulq\s*\(%ebx\)\s*,\s*\[%eax\]\s*,\s*%rbx\s*$/io;
$intel_instr_to_att{'imul zzz, [eax], [ebx]'} = qr/^\s*imul\s*\(%ebx\)\s*,\s*\[%eax\],\s*\$zzz\s*\s*$/io;

$intel_instr_to_att{'imul eax, bx, 2'} = qr/^\s*imull\s*\$2\s*,\s*%bx\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, [bx], 2'} = qr/^\s*imull\s*\$2\s*,\s*\(%bx\)\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul [eax], bx, 2'} = qr/^\s*imulw\s*\$2\s*,\s*%bx\s*,\s*\(%eax\)\s*$/io;
$intel_instr_to_att{'imul [eax], [bx], 2'} = qr/^\s*imul\s*\$2\s*,\s*\(%bx\)\s*,\s*\[%eax\]\s*$/io;
$intel_instr_to_att{'imul eax, 2, bx'} = qr/^\s*imulw\s*%bx\s*,\s*\$2\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, 2, [bx]'} = qr/^\s*imull\s*\(%bx\)\s*,\s*\$2\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul [eax], 2, bx'} = qr/^\s*imulw\s*%bx\s*,\s*\$2\s*,\s*\(%eax\)\s*$/io;
$intel_instr_to_att{'imul [eax], 2, [bx]'} = qr/^\s*imul\s*\(%bx\)\s*,\s*\$2\s*,\s*\[%eax\]\s*$/io;
$intel_instr_to_att{'imul 2, eax, bx'} = qr/^\s*imulw\s*%bx\s*,\s*%eax\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, eax, [bx]'} = qr/^\s*imull\s*\(%bx\)\s*,\s*%eax\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, [eax], bx'} = qr/^\s*imulw\s*%bx\s*,\s*\(%eax\)\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, [eax], [bx]'} = qr/^\s*imul\s*\(%bx\)\s*,\s*\[%eax\]\s*,\s*\$2\s*$/io;

$intel_instr_to_att{'imul bx, eax, 2'} = qr/^\s*imulw\s*\$2\s*,\s*%eax\s*,\s*%bx\s*$/io;
$intel_instr_to_att{'imul [bx], eax, 2'} = qr/^\s*imull\s*\$2\s*,\s*%eax\s*,\s*\(%bx\)\s*$/io;
$intel_instr_to_att{'imul bx, [eax], 2'} = qr/^\s*imulw\s*\$2\s*,\s*\(%eax\)\s*,\s*%bx\s*$/io;
$intel_instr_to_att{'imul [bx], [eax], 2'} = qr/^\s*imul\s*\$2\s*,\s*\(%eax\)\s*,\s*\[%bx\]\s*$/io;
$intel_instr_to_att{'imul bx, 2, eax'} = qr/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*%bx\s*$/io;
$intel_instr_to_att{'imul [bx], 2, eax'} = qr/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*\(%bx\)\s*$/io;
$intel_instr_to_att{'imul bx, 2, [eax]'} = qr/^\s*imulw\s*\(%eax\)\s*,\s*\$2\s*,\s*%bx\s*$/io;
$intel_instr_to_att{'imul [bx], 2, [eax]'} = qr/^\s*imul\s\(%eax\)\s*,\s*\$2,\s*\[%bx\]\s*\s*$/io;

$intel_instr_to_att{'imul eax, bl, 2'} = qr/^\s*imull\s*\$2\s*,\s*%bl\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, [bl], 2'} = qr/^\s*imull\s*\$2\s*,\s*\(%bl\)\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul [eax], bl, 2'} = qr/^\s*imulb\s*\$2\s*,\s*%bl\s*,\s*\(%eax\)\s*$/io;
$intel_instr_to_att{'imul [eax], [bl], 2'} = qr/^\s*imul\s*\$2\s*,\s*\(%bl\)\s*,\s*\[%eax\]\s*$/io;
$intel_instr_to_att{'imul eax, 2, bl'} = qr/^\s*imulb\s*%bl\s*,\s*\$2\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, 2, [bl]'} = qr/^\s*imull\s*\(%bl\)\s*,\s*\$2\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul [eax], 2, bl'} = qr/^\s*imulb\s*%bl\s*,\s*\$2\s*,\s*\(%eax\)\s*$/io;
$intel_instr_to_att{'imul [eax], 2, [bl]'} = qr/^\s*imul\s*\(%bl\)\s*,\s*\$2\s*,\s*\[%eax\]\s*$/io;
$intel_instr_to_att{'imul 2, eax, bl'} = qr/^\s*imulb\s*%bl\s*,\s*%eax\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, eax, [bl]'} = qr/^\s*imull\s*\(%bl\)\s*,\s*%eax\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, [eax], bl'} = qr/^\s*imulb\s*%bl\s*,\s*\(%eax\)\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, [eax], [bl]'} = qr/^\s*imul\s*\(%bl\)\s*,\s*\[%eax\]\s*,\s*\$2\s*$/io;

$intel_instr_to_att{'imul bl, eax, 2'} = qr/^\s*imulb\s*\$2\s*,\s*%eax\s*,\s*%bl\s*$/io;
$intel_instr_to_att{'imul [bl], eax, 2'} = qr/^\s*imull\s*\$2\s*,\s*%eax\s*,\s*\(%bl\)\s*$/io;
$intel_instr_to_att{'imul bl, [eax], 2'} = qr/^\s*imulb\s*\$2\s*,\s*\(%eax\)\s*,\s*%bl\s*$/io;
$intel_instr_to_att{'imul [bl], [eax], 2'} = qr/^\s*imul\s*\$2\s*,\s*\(%eax\)\s*,\s*\[%bl\]\s*$/io;
$intel_instr_to_att{'imul bl, 2, eax'} = qr/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*%bl\s*$/io;
$intel_instr_to_att{'imul [bl], 2, eax'} = qr/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*\(%bl\)\s*$/io;
$intel_instr_to_att{'imul bl, 2, [eax]'} = qr/^\s*imulb\s*\(%eax\)\s*,\s*\$2\s*,\s*%bl\s*$/io;
$intel_instr_to_att{'imul [bl], 2, [eax]'} = qr/^\s*imul\s\(%eax\)\s*,\s*\$2,\s*\[%bl\]\s*\s*$/io;

$intel_instr_to_att{'imul eax, rbx, 2'} = qr/^\s*imull\s*\$2\s*,\s*%rbx\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, [rbx], 2'} = qr/^\s*imull\s*\$2\s*,\s*\(%rbx\)\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul [eax], rbx, 2'} = qr/^\s*imulq\s*\$2\s*,\s*%rbx\s*,\s*\(%eax\)\s*$/io;
$intel_instr_to_att{'imul [eax], [rbx], 2'} = qr/^\s*imul\s*\$2\s*,\s*\(%rbx\)\s*,\s*\[%eax\]\s*$/io;
$intel_instr_to_att{'imul eax, 2, rbx'} = qr/^\s*imulq\s*%rbx\s*,\s*\$2\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, 2, [rbx]'} = qr/^\s*imull\s*\(%rbx\)\s*,\s*\$2\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul [eax], 2, rbx'} = qr/^\s*imulq\s*%rbx\s*,\s*\$2\s*,\s*\(%eax\)\s*$/io;
$intel_instr_to_att{'imul [eax], 2, [rbx]'} = qr/^\s*imul\s*\(%rbx\)\s*,\s*\$2\s*,\s*\[%eax\]\s*$/io;
$intel_instr_to_att{'imul 2, eax, rbx'} = qr/^\s*imulq\s*%rbx\s*,\s*%eax\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, eax, [rbx]'} = qr/^\s*imull\s*\(%rbx\)\s*,\s*%eax\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, [eax], rbx'} = qr/^\s*imulq\s*%rbx\s*,\s*\(%eax\)\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, [eax], [rbx]'} = qr/^\s*imul\s*\(%rbx\)\s*,\s*\[%eax\]\s*,\s*\$2\s*$/io;

$intel_instr_to_att{'imul rbx, eax, 2'} = qr/^\s*imulq\s*\$2\s*,\s*%eax\s*,\s*%rbx\s*$/io;
$intel_instr_to_att{'imul [rbx], eax, 2'} = qr/^\s*imull\s*\$2\s*,\s*%eax\s*,\s*\(%rbx\)\s*$/io;
$intel_instr_to_att{'imul rbx, [eax], 2'} = qr/^\s*imulq\s*\$2\s*,\s*\(%eax\)\s*,\s*%rbx\s*$/io;
$intel_instr_to_att{'imul [rbx], [eax], 2'} = qr/^\s*imul\s*\$2\s*,\s*\(%eax\)\s*,\s*\[%rbx\]\s*$/io;
$intel_instr_to_att{'imul rbx, 2, eax'} = qr/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*%rbx\s*$/io;
$intel_instr_to_att{'imul [rbx], 2, eax'} = qr/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*\(%rbx\)\s*$/io;
$intel_instr_to_att{'imul rbx, 2, [eax]'} = qr/^\s*imulq\s*\(%eax\)\s*,\s*\$2\s*,\s*%rbx\s*$/io;
$intel_instr_to_att{'imul [rbx], 2, [eax]'} = qr/^\s*imul\s\(%eax\)\s*,\s*\$2,\s*\[%rbx\]\s*\s*$/io;

$intel_instr_to_att{'imul eax, zzz, 2'} = qr/^\s*imull\s*\$2\s*,\s*\$zzz\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, [zzz], 2'} = qr/^\s*imull\s*\$2\s*,\s*\$?zzz\(,1\)\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul [eax], zzz, 2'} = qr/^\s*imul\s*\$2\s*,\s*\$zzz\s*,\s*\(%eax\)\s*$/io;
$intel_instr_to_att{'imul [eax], [zzz], 2'} = qr/^\s*imul\s*\$2\s*,\s*\$?zzz\(,1\)\s*,\s*\[%eax\]\s*$/io;
$intel_instr_to_att{'imul eax, 2, zzz'} = qr/^\s*imull\s*\$zzz\s*,\s*\$2\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul eax, 2, [zzz]'} = qr/^\s*imull\s*\$?zzz\(,1\)\s*,\s*\$2\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'imul [eax], 2, zzz'} = qr/^\s*imul\s*\$zzz\s*,\s*\$2\s*,\s*\(%eax\)\s*$/io;
$intel_instr_to_att{'imul [eax], 2, [zzz]'} = qr/^\s*imul\s*\$?zzz\(,1\)\s*,\s*\$2\s*,\s*\[%eax\]\s*$/io;
$intel_instr_to_att{'imul 2, eax, zzz'} = qr/^\s*imul\s*\$zzz\s*,\s*%eax\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, eax, [zzz]'} = qr/^\s*imull\s*\$?zzz\(,1\)\s*,\s*%eax\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, [eax], zzz'} = qr/^\s*imul\s*\$zzz\s*,\s*\(%eax\)\s*,\s*\$2\s*$/io;
$intel_instr_to_att{'imul 2, [eax], [zzz]'} = qr/^\s*imul\s*\$?zzz\(,1\)\s*,\s*\[%eax\]\s*,\s*\$2\s*$/io;

$intel_instr_to_att{'imul zzz, eax, 2'} = qr/^\s*imul\s*\$2\s*,\s*%eax\s*,\s*\$zzz\s*$/io;
$intel_instr_to_att{'imul [zzz], eax, 2'} = qr/^\s*imull\s*\$2\s*,\s*%eax\s*,\s*\$?zzz\(,1\)\s*$/io;
$intel_instr_to_att{'imul zzz, [eax], 2'} = qr/^\s*imul\s*\$2\s*,\s*\(%eax\)\s*,\s*\$zzz\s*$/io;
$intel_instr_to_att{'imul [zzz], [eax], 2'} = qr/^\s*imul\s*\$2\s*,\s*\(%eax\)\s*,\s*\[zzz\]\s*$/io;
$intel_instr_to_att{'imul zzz, 2, eax'} = qr/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*\$zzz\s*$/io;
$intel_instr_to_att{'imul [zzz], 2, eax'} = qr/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*\$?zzz\(,1\)\s*$/io;
$intel_instr_to_att{'imul zzz, 2, [eax]'} = qr/^\s*imul\s*\(%eax\)\s*,\s*\$2\s*,\s*\$zzz\s*$/io;
$intel_instr_to_att{'imul [zzz], 2, [eax]'} = qr/^\s*imul\s\(%eax\)\s*,\s*\$2,\s*\[zzz\]\s*\s*$/io;

$intel_instr_to_att{'imul [ecx], [eax], bl'} = qr/^\s*imulb\s*%bl\s*,\s*\(%eax\)\s*,\s*\[%ecx\]\s*$/io;
$intel_instr_to_att{'imul [ecx], [eax], bx'} = qr/^\s*imulw\s*%bx\s*,\s*\(%eax\)\s*,\s*\[%ecx\]\s*$/io;
$intel_instr_to_att{'imul [ecx], [eax], ebx'} = qr/^\s*imull\s*%ebx\s*,\s*\(%eax\)\s*,\s*\[%ecx\]\s*$/io;
$intel_instr_to_att{'imul [ecx], [eax], rbx'} = qr/^\s*imulq\s*%rbx\s*,\s*\(%eax\)\s*,\s*\[%ecx\]\s*$/io;
$intel_instr_to_att{'imul [ecx], [eax], zzz'} = qr/^\s*imul\s*\$zzz\s*,\s*\(%eax\)\s*,\s*\[%ecx\]\s*$/io;
$intel_instr_to_att{'imul [ecx], [eax], [rbx]'} = qr/^\s*imul\s*\(%rbx\)\s*,\s*\[%eax\]\s*,\s*\[%ecx\]\s*$/io;

#$intel_instr_to_att{'imul eax, rbx, \[2'} = qr/^\s*imull\s*\$2\s*,\s*%rbx\s*,\s*%eax\s*$/io;

$intel_instr_to_att{'sub ebx, eax'} = qr/^\s*subl\s*%eax\s*,\s*%ebx\s*$/io;
$intel_instr_to_att{'sub ebx, 2'} = qr/^\s*subl\s*\$2\s*,\s*%ebx\s*$/io;
$intel_instr_to_att{'sub ebx, rax'} = qr/^\s*subq\s*%rax\s*,\s*%ebx\s*$/io;
$intel_instr_to_att{'sub ebx, bl'} = qr/^\s*subb\s*%bl\s*,\s*%ebx\s*$/io;
$intel_instr_to_att{'sub ebx, ax'} = qr/^\s*subw\s*%ax\s*,\s*%ebx\s*$/io;
$intel_instr_to_att{'sub ebx, zzz'} = qr/^\s*subl\s*\$zzz\s*,\s*%ebx\s*$/io;

$intel_instr_to_att{'sub bl, eax'} = qr/^\s*subl\s*%eax\s*,\s*%bl\s*$/io;
$intel_instr_to_att{'sub bx, eax'} = qr/^\s*subl\s*%eax\s*,\s*%bx\s*$/io;
$intel_instr_to_att{'sub rbx, eax'} = qr/^\s*subl\s*%eax\s*,\s*%rbx\s*$/io;

$intel_instr_to_att{'sub bl, [eax]'} = qr/^\s*subb\s*\(%eax\)\s*,\s*%bl\s*$/io;
$intel_instr_to_att{'sub bx, [eax]'} = qr/^\s*subw\s*\(%eax\)\s*,\s*%bx\s*$/io;
$intel_instr_to_att{'sub ebx, [eax]'} = qr/^\s*subl\s*\(%eax\)\s*,\s*%ebx\s*$/io;
$intel_instr_to_att{'sub rbx, [eax]'} = qr/^\s*subq\s*\(%eax\)\s*,\s*%rbx\s*$/io;
$intel_instr_to_att{'sub 2, [ebx]'} = qr/^\s*sub\s*\(%ebx\)\s*,\s*\$2\s*$/io;

$intel_instr_to_att{'sub [ebx], [eax]'} = qr/^\s*sub\s*\(%eax\)\s*,\s*\[%ebx\]\s*$/io;

$intel_instr_to_att{'sub [ebx], al'} = qr/^\s*subb\s*%al\s*,\s*\(%ebx\)\s*$/io;
$intel_instr_to_att{'sub [ebx], ax'} = qr/^\s*subw\s*%ax\s*,\s*\(%ebx\)\s*$/io;
$intel_instr_to_att{'sub [ebx], eax'} = qr/^\s*subl\s*%eax\s*,\s*\(%ebx\)\s*$/io;
$intel_instr_to_att{'sub [ebx], rax'} = qr/^\s*subq\s*%rax\s*,\s*\(%ebx\)\s*$/io;
$intel_instr_to_att{'sub [ebx], 2'} = qr/^\s*sub\s*\$2\s*,\s*\(%ebx\)\s*$/io;

$intel_instr_to_att{'sub bl, zzz'} = qr/^\s*subb\s*\$zzz\s*,\s*%bl\s*$/io;
$intel_instr_to_att{'sub bx, zzz'} = qr/^\s*subw\s*\$zzz\s*,\s*%bx\s*$/io;
$intel_instr_to_att{'sub ebx, zzz'} = qr/^\s*subl\s*\$zzz\s*,\s*%ebx\s*$/io;
$intel_instr_to_att{'sub rbx, zzz'} = qr/^\s*subq\s*\$zzz\s*,\s*%rbx\s*$/io;
$intel_instr_to_att{'sub yyy, zzz'} = qr/^\s*sub\s*\$zzz\s*,\s*\$yyy\s*$/io;

$intel_instr_to_att{'sub 2, ebx'} = qr/^\s*subl\s*%ebx\s*,\s*\$2\s*$/io;

$intel_instr_to_att{'not ebx'} = qr/^\s*notl\s*%ebx\s*$/io;
$intel_instr_to_att{'not zzz'} = qr/^\s*not\s*\$zzz\s*$/io;
$intel_instr_to_att{'not [ebx]'} = qr/^\s*not\s*\(%ebx\)\s*$/io;

$intel_instr_to_att{'movzx ebx, byte [eax]'} = qr/^\s*movzbl\s*\(%eax\)\s*,\s*%ebx\s*$/io;
$intel_instr_to_att{'movsx ebx, cl'} = qr/^\s*movsbl\s*%cl\s*,\s*%ebx\s*$/io;
$intel_instr_to_att{'movzx bx, byte [eax]'} = qr/^\s*movzbw\s*\(%eax\)\s*,\s*%bx\s*$/io;
$intel_instr_to_att{'movsx bx, cl'} = qr/^\s*movsbw\s*%cl\s*,\s*%bx\s*$/io;
$intel_instr_to_att{'movzx ebx, word [eax]'} = qr/^\s*movzwl\s*\(%eax\)\s*,\s*%ebx\s*$/io;
$intel_instr_to_att{'movsx ebx, cx'} = qr/^\s*movswl\s*%cx\s*,\s*%ebx\s*$/io;
$intel_instr_to_att{'movzx rbx, byte [eax]'} = qr/^\s*movzbq\s*\(%eax\)\s*,\s*%rbx\s*$/io;
$intel_instr_to_att{'movsx rbx, cl'} = qr/^\s*movsbq\s*%cl\s*,\s*%rbx\s*$/io;
$intel_instr_to_att{'movzx rbx, word [eax]'} = qr/^\s*movzwq\s*\(%eax\)\s*,\s*%rbx\s*$/io;
$intel_instr_to_att{'movsx rbx, cx'} = qr/^\s*movswq\s*%cx\s*,\s*%rbx\s*$/io;
# undecideable result:
$intel_instr_to_att{'movzx ebx, [zz]'} = qr/^\s*movzx\s*zz\(,1\)\s*,\s*%ebx\s*$/io;
$intel_instr_to_att{'movzx cl, al'} = qr/^\s*movzx\s*%al\s*,\s*%cl\s*$/io;
$intel_instr_to_att{'movzx cl, byte [eax]'} = qr/^\s*movzx\s*\(%eax\)\s*,\s*%cl\s*$/io;
$intel_instr_to_att{'movzx cx, ax'} = qr/^\s*movzx\s*%ax\s*,\s*%cx\s*$/io;
$intel_instr_to_att{'movzx cx, word [eax]'} = qr/^\s*movzx\s*\(%eax\)\s*,\s*%cx\s*$/io;
$intel_instr_to_att{'movzx ecx, eax'} = qr/^\s*movzx\s*%eax\s*,\s*%ecx\s*$/io;
$intel_instr_to_att{'movzx ecx, dword [eax]'} = qr/^\s*movzx\s*\(%eax\)\s*,\s*%ecx\s*$/io;
$intel_instr_to_att{'movzx rcx, eax'} = qr/^\s*movzx\s*%eax\s*,\s*%rcx\s*$/io;
$intel_instr_to_att{'movzx rcx, dword [eax]'} = qr/^\s*movzx\s*\(%eax\)\s*,\s*%rcx\s*$/io;
$intel_instr_to_att{'movzx rcx, rax'} = qr/^\s*movzx\s*%rax\s*,\s*%rcx\s*$/io;
$intel_instr_to_att{'movzx rcx, qword [eax]'} = qr/^\s*movzx\s*\(%eax\)\s*,\s*%rcx\s*$/io;

$intel_instr_to_att{'zzz rcx, eax, bl'} = qr/^\s*zzz\s*%rcx\s*,\s*%eax\s*,\s*%bl\s*$/io;
$intel_instr_to_att{'zzz rcx, eax'} = qr/^\s*zzz\s*%rcx\s*,\s*%eax\s*$/io;
$intel_instr_to_att{'zzz rcx'} = qr/^\s*zzz\s*%rcx\s*/io;
$intel_instr_to_att{'jmp [zzz]'} = qr/^\s*jmp\s*\*zzz\s*/io;
$intel_instr_to_att{'call [zzz]'} = qr/^\s*call\s*\*zzz\s*/io;
$intel_instr_to_att{'jmp zzz'} = qr/^\s*jmp\s*zzz\s*/io;
$intel_instr_to_att{'call 0x123'} = qr/^\s*call\s*\*0x123\s*/io;
$intel_instr_to_att{'jmp	cs:zzz'} = qr/^\s*ljmp\s*%cs\s*,\s*zzz\s*/io;
$intel_instr_to_att{'retf x'} = qr/^\s*lret\s*\$x\s*/io;

$intel_instr_to_att{'cbw'} = qr/^\s*cbtw\s*$/io;
$intel_instr_to_att{'cwde'} = qr/^\s*cwtl\s*$/io;
$intel_instr_to_att{'cwd'} = qr/^\s*cwtd\s*$/io;
$intel_instr_to_att{'cdq'} = qr/^\s*cltd\s*$/io;

$intel_instr_to_att{'fild word [eax]'} = qr/^\s*filds\s*\(\s*%eax\s*\)\s*$/io;
$intel_instr_to_att{'fild dword [eax + ebx*2]'} = qr/^\s*fildl\s*\(\s*%eax\s*,\s*%ebx\s*,\s*2\s*\)\s*$/io;
$intel_instr_to_att{'fild qword [eax]'} = qr/^\s*fildq\s*\(\s*%eax\s*\)\s*$/io;

$intel_instr_to_att{'fld dword [ebx]'} = qr/^\s*flds\s*\(\s*%ebx\s*\)\s*$/io;
$intel_instr_to_att{'fld qword [ebx + ecx*2]'} = qr/^\s*fldl\s*\(\s*%ebx\s*,\s*%ecx\s*,\s*2\s*\)\s*$/io;
$intel_instr_to_att{'fld tword [ebx]'} = qr/^\s*fldt\s*\(\s*%ebx\s*\)\s*$/io;

my %intel_addr_to_att;

$intel_addr_to_att{'[ebx]'} = qr/^\s*\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ebx-9]'} = qr/^\s*\(\+*-9\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'[ebx + eax]'} = qr/^\s*\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + 2]'} = qr/^\s*\(\+*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[2 + ebx]'} = qr/^\s*\(\+*2\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'[ebx + eax + 1]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + 1 + eax]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io;
$intel_addr_to_att{'[1 + ebx + eax]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io;

$intel_addr_to_att{'[3 + eax + 1]'} = qr/^\s*\(\+*1\++3\)\(\s*%eax\s*\)\s*$/io;
$intel_addr_to_att{'[3 + 1 + eax]'} = qr/^\s*\(\+*3\++1\)\(\s*%eax\s*\)\s*$/io;
$intel_addr_to_att{'[eax + 1 + 3]'} = qr/^\s*\(\+*3\++1\)\(\s*%eax\s*\)\s*$/io;

$intel_addr_to_att{'[ebx + eax * 2]'} = qr/^\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + 2 * eax]'} = qr/^\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[eax * 2 + ebx]'} = qr/^\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[2 * eax + ebx]'} = qr/^\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;

$intel_addr_to_att{'[3 + eax * 2]'} = qr/^\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[3 + 2 * eax]'} = qr/^\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[eax * 2 + 3]'} = qr/^\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[2 * eax + 3]'} = qr/^\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;

$intel_addr_to_att{'[ebx + 3 * 2]'} = qr/^\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + 2 * 3]'} = qr/^\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[3 * 2 + ebx]'} = qr/^\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[2 * 3 + ebx]'} = qr/^\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'[ebx + eax * 2 + 1]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + 2 * eax + 1]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[eax * 2 + ebx + 1]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[2 * eax + ebx + 1]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + 1 + eax * 2]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + 1 + 2 * eax]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[eax * 2 + 1 + ebx]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[2 * eax + 1 + ebx]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[1 + ebx + eax * 2]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[1 + ebx + 2 * eax]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[1 + eax * 2 + ebx]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[1 + 2 * eax + ebx]'} = qr/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;

$intel_addr_to_att{'[3 + eax * 2 + 1]'} = qr/^\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[3 + 2 * eax + 1]'} = qr/^\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[eax * 2 + 3 + 1]'} = qr/^\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[2 * eax + 3 + 1]'} = qr/^\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[3 + 1 + eax * 2]'} = qr/^\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[3 + 1 + 2 * eax]'} = qr/^\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[eax * 2 + 1 + 3]'} = qr/^\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[2 * eax + 1 + 3]'} = qr/^\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[1 + 3 + eax * 2]'} = qr/^\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[1 + 3 + 2 * eax]'} = qr/^\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[1 + eax * 2 + 3]'} = qr/^\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[1 + 2 * eax + 3]'} = qr/^\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;

$intel_addr_to_att{'[ebx + 3 * 2]'} = qr/^\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + 2 * 3]'} = qr/^\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[3 * 2 + ebx]'} = qr/^\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[2 * 3 + ebx]'} = qr/^\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'[ebx + 3 * 2 + 1]'} = qr/^\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + 2 * 3 + 1]'} = qr/^\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[3 * 2 + ebx + 1]'} = qr/^\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[2 * 3 + ebx + 1]'} = qr/^\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + 1 + 3 * 2]'} = qr/^\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + 1 + 2 * 3]'} = qr/^\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[3 * 2 + 1 + ebx]'} = qr/^\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[2 * 3 + 1 + ebx]'} = qr/^\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[1 + ebx + 3 * 2]'} = qr/^\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[1 + ebx + 2 * 3]'} = qr/^\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[1 + 3 * 2 + ebx]'} = qr/^\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[1 + 2 * 3 + ebx]'} = qr/^\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'[ebx + 3 * 2 + ecx]'} = qr/^\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + 2 * 3 + ecx]'} = qr/^\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'[3 * 2 + ebx + ecx]'} = qr/^\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'[2 * 3 + ebx + ecx]'} = qr/^\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + ecx + 3 * 2]'} = qr/^\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'[ebx + ecx + 2 * 3]'} = qr/^\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'[3 * 2 + ecx + ebx]'} = qr/^\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[2 * 3 + ecx + ebx]'} = qr/^\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ecx + ebx + 3 * 2]'} = qr/^\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ecx + ebx + 2 * 3]'} = qr/^\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ecx + 3 * 2 + ebx]'} = qr/^\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ecx + 2 * 3 + ebx]'} = qr/^\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'ds:[ebx]'} = qr/^\s*%ds:\s*\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx-9]'} = qr/^\s*%ds:\s*\(\+*-9\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'ds:[ebx + eax]'} = qr/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + 2]'} = qr/^\s*%ds:\s*\(\+*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[2 + ebx]'} = qr/^\s*%ds:\s*\(\+*2\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'ds:[ebx + eax + 1]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + 1 + eax]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io;
$intel_addr_to_att{'ds:[1 + ebx + eax]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io;

$intel_addr_to_att{'ds:[3 + eax + 1]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(\s*%eax\s*\)\s*$/io;
$intel_addr_to_att{'ds:[3 + 1 + eax]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(\s*%eax\s*\)\s*$/io;
$intel_addr_to_att{'ds:[eax + 1 + 3]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(\s*%eax\s*\)\s*$/io;

$intel_addr_to_att{'ds:[ebx + eax * 2]'} = qr/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + 2 * eax]'} = qr/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[eax * 2 + ebx]'} = qr/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[2 * eax + ebx]'} = qr/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;

$intel_addr_to_att{'ds:[3 + eax * 2]'} = qr/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[3 + 2 * eax]'} = qr/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[eax * 2 + 3]'} = qr/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[2 * eax + 3]'} = qr/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;

$intel_addr_to_att{'ds:[ebx + 3 * 2]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[3 * 2 + ebx]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[2 * 3 + ebx]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'ds:[ebx + eax * 2 + 1]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + 2 * eax + 1]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[eax * 2 + ebx + 1]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[2 * eax + ebx + 1]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + 1 + eax * 2]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + 1 + 2 * eax]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[eax * 2 + 1 + ebx]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[2 * eax + 1 + ebx]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[1 + ebx + eax * 2]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[1 + ebx + 2 * eax]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[1 + eax * 2 + ebx]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[1 + 2 * eax + ebx]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;

$intel_addr_to_att{'ds:[3 + eax * 2 + 1]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[3 + 2 * eax + 1]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[eax * 2 + 3 + 1]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[2 * eax + 3 + 1]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[3 + 1 + eax * 2]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[3 + 1 + 2 * eax]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[eax * 2 + 1 + 3]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[2 * eax + 1 + 3]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[1 + 3 + eax * 2]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[1 + 3 + 2 * eax]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[1 + eax * 2 + 3]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'ds:[1 + 2 * eax + 3]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;

$intel_addr_to_att{'ds:[ebx + 3 * 2]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[3 * 2 + ebx]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[2 * 3 + ebx]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'ds:[ebx + 3 * 2 + 1]'} = qr/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + 2 * 3 + 1]'} = qr/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[3 * 2 + ebx + 1]'} = qr/^\s*%ds:\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[2 * 3 + ebx + 1]'} = qr/^\s*%ds:\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + 1 + 3 * 2]'} = qr/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + 1 + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[3 * 2 + 1 + ebx]'} = qr/^\s*%ds:\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[2 * 3 + 1 + ebx]'} = qr/^\s*%ds:\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[1 + ebx + 3 * 2]'} = qr/^\s*%ds:\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[1 + ebx + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[1 + 3 * 2 + ebx]'} = qr/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[1 + 2 * 3 + ebx]'} = qr/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'ds:[ebx + 3 * 2 + ecx]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + 2 * 3 + ecx]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[3 * 2 + ebx + ecx]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[2 * 3 + ebx + ecx]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + ecx + 3 * 2]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ebx + ecx + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[3 * 2 + ecx + ebx]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[2 * 3 + ecx + ebx]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ecx + ebx + 3 * 2]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ecx + ebx + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ecx + 3 * 2 + ebx]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'ds:[ecx + 2 * 3 + ebx]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'[ds:ebx]'} = qr/^\s*%ds:\s*\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ebx-9]'} = qr/^\s*%ds:\s*\(\+*-9\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'[ds:ebx + eax]'} = qr/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*(,\s*)?\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + 2]'} = qr/^\s*%ds:\s*\(\+*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 + ebx]'} = qr/^\s*%ds:\s*\(\+*2\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'[ds:ebx + eax + 1]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*(,\s*)?\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + 1 + eax]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*(,\s*)?\)\s*$/io;
$intel_addr_to_att{'[ds:1 + ebx + eax]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%eax\s*,\s*%ebx\s*(,\s*)?\)\s*$/io;

$intel_addr_to_att{'[ds:3 + eax + 1]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(\s*%eax\s*\)\s*$/io;
$intel_addr_to_att{'[ds:3 + 1 + eax]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(\s*%eax\s*\)\s*$/io;
$intel_addr_to_att{'[ds:eax + 1 + 3]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(\s*%eax\s*\)\s*$/io;

$intel_addr_to_att{'[ds:ebx + eax * 2]'} = qr/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + 2 * eax]'} = qr/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:eax * 2 + ebx]'} = qr/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * eax + ebx]'} = qr/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;

$intel_addr_to_att{'[ds:3 + eax * 2]'} = qr/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:3 + 2 * eax]'} = qr/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:eax * 2 + 3]'} = qr/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * eax + 3]'} = qr/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;

$intel_addr_to_att{'[ds:ebx + 3 * 2]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:3 * 2 + ebx]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * 3 + ebx]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'[ds:ebx + eax * 2 + 1]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + 2 * eax + 1]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:eax * 2 + ebx + 1]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * eax + ebx + 1]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + 1 + eax * 2]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + 1 + 2 * eax]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:eax * 2 + 1 + ebx]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * eax + 1 + ebx]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + ebx + eax * 2]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + ebx + 2 * eax]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + eax * 2 + ebx]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + 2 * eax + ebx]'} = qr/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io;

$intel_addr_to_att{'[ds:3 + eax * 2 + 1]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:3 + 2 * eax + 1]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:eax * 2 + 3 + 1]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * eax + 3 + 1]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:3 + 1 + eax * 2]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:3 + 1 + 2 * eax]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:eax * 2 + 1 + 3]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * eax + 1 + 3]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + 3 + eax * 2]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + 3 + 2 * eax]'} = qr/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + eax * 2 + 3]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + 2 * eax + 3]'} = qr/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io;

$intel_addr_to_att{'[ds:ebx + 3 * 2]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:3 * 2 + ebx]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * 3 + ebx]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'[ds:ebx + 3 * 2 + 1]'} = qr/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + 2 * 3 + 1]'} = qr/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:3 * 2 + ebx + 1]'} = qr/^\s*%ds:\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * 3 + ebx + 1]'} = qr/^\s*%ds:\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + 1 + 3 * 2]'} = qr/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + 1 + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:3 * 2 + 1 + ebx]'} = qr/^\s*%ds:\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * 3 + 1 + ebx]'} = qr/^\s*%ds:\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + ebx + 3 * 2]'} = qr/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + ebx + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + 3 * 2 + ebx]'} = qr/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + 2 * 3 + ebx]'} = qr/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'[ds:ebx + 3 * 2 + ecx]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + 2 * 3 + ecx]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:3 * 2 + ebx + ecx]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * 3 + ebx + ecx]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + ecx + 3 * 2]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ebx + ecx + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:3 * 2 + ecx + ebx]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * 3 + ecx + ebx]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ecx + ebx + 3 * 2]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ecx + ebx + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ecx + 3 * 2 + ebx]'} = qr/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;
$intel_addr_to_att{'[ds:ecx + 2 * 3 + ebx]'} = qr/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io;

$intel_addr_to_att{'[ds:1 + 2 * 3 + 4]'} = qr/^\s*%ds:\s*\(\+*1\++2\*3\++4\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + 4 + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*1\++4\++2\*3\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * 3 + 1 + 4]'} = qr/^\s*%ds:\s*\(\+*2\*3\++1\++4\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + 2 * 3]'} = qr/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[ds:2 * 3 + 1]'} = qr/^\s*%ds:\s*\(\+*2\*3\++1\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + 2 + 3]'} = qr/^\s*%ds:\s*\(\+*1\++2\++3\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1 + 2]'} = qr/^\s*%ds:\s*\(\+*1\++2\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[ds:1]'} = qr/^\s*%ds:\s*\(?\+*1\)?\(\s*,1\s*\)\s*$/io;

$intel_addr_to_att{'[1 + 2 * 3 + 4]'} = qr/^\s*\(\+*1\++2\*3\++4\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[1 + 4 + 2 * 3]'} = qr/^\s*\(\+*1\++4\++2\*3\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[2 * 3 + 1 + 4]'} = qr/^\s*\(\+*2\*3\++1\++4\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[1 + 2 * 3]'} = qr/^\s*\(\+*1\++2\*3\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[2 * 3 + 1]'} = qr/^\s*\(\+*2\*3\++1\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[1 + 2 + 3]'} = qr/^\s*\(\+*1\++2\++3\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[1 + 2]'} = qr/^\s*\(\+*1\++2\)\(\s*,1\s*\)\s*$/io;
$intel_addr_to_att{'[1]'} = qr/^\s*\(?\+*1\)?\(\s*,1\s*\)\s*$/io;

my %att_instr_to_intel;

$att_instr_to_intel{'addl	%eax, %ebx'} = qr/^\s*add\s*(dword)?\s*ebx,\s*eax\s*$/io;
$att_instr_to_intel{'jmp	name'} = qr/^\s*jmp\s*(dword)?\s*name\s*$/io;
$att_instr_to_intel{'call	name'} = qr/^\s*call\s*(dword)?\s*name\s*$/io;

$att_instr_to_intel{'subb	(%esi), %bl'} = qr/^\s*sub\s*(byte)?\s*bl\s*,\s*\[esi\]\s*$/io;
$att_instr_to_intel{'subb	(%esi), 2'} = qr/^\s*sub\s*(byte)?\s*2\s*,\s*\[esi\]\s*$/io;
$att_instr_to_intel{'subb	(%esi), $2'} = qr/^\s*sub\s*(byte)?\s*2\s*,\s*\[esi\]\s*$/io;
$att_instr_to_intel{'subb	(%esi), zz'} = qr/^\s*sub\s*(byte)?\s*zz\s*,\s*\[esi\]\s*$/io;
$att_instr_to_intel{'subb	(%esi), _L1'} = qr/^\s*sub\s*(byte)?\s*_L1\s*,\s*\[esi\]\s*$/io;
$att_instr_to_intel{'subb	%esi, %bl'} = qr/^\s*sub\s*(byte)?\s*bl\s*,\s*esi\s*$/io;
$att_instr_to_intel{'subb	%esi, 2'} = qr/^\s*sub\s*(byte)?\s*2\s*,\s*esi\s*$/io;
$att_instr_to_intel{'subb	%esi, $2'} = qr/^\s*sub\s*(byte)?\s*2\s*,\s*esi\s*$/io;
$att_instr_to_intel{'subb	%esi, zz'} = qr/^\s*sub\s*(byte)?\s*\[zz\]\s*,\s*esi\s*$/io;
$att_instr_to_intel{'subb	%esi, _L1'} = qr/^\s*sub\s*(byte)?\s*_L1\s*,\s*esi\s*$/io;
$att_instr_to_intel{'subb	2, %bl'} = qr/^\s*sub\s*(byte)?\s*bl\s*,\s*2\s*$/io;
$att_instr_to_intel{'subb	$2, %bl'} = qr/^\s*sub\s*(byte)?\s*bl\s*,\s*2\s*$/io;
$att_instr_to_intel{'subb	zz, %bl'} = qr/^\s*sub\s*(byte)?\s*bl\s*,\s*\[zz\]\s*$/io;
$att_instr_to_intel{'subb	_L1, %bl'} = qr/^\s*sub\s*(byte)?\s*bl\s*,\s*_L1\s*$/io;

$att_instr_to_intel{'notb	%bl'} = qr/^\s*not\s*(byte)?\s*bl\s*$/io;
$att_instr_to_intel{'notb	2'} = qr/^\s*not\s*(byte)?\s*2\s*$/io;
$att_instr_to_intel{'notb	$2'} = qr/^\s*not\s*(byte)?\s*2\s*$/io;
$att_instr_to_intel{'notb	zz'} = qr/^\s*not\s*(byte)?\s*\[zz\]\s*$/io;
$att_instr_to_intel{'notb	_L1'} = qr/^\s*not\s*(byte)?\s*_L1\s*$/io;

$att_instr_to_intel{'imul	(%esi), %bl, 2'} = qr/^\s*imul\s*(dword)?\s*2,\s*bl\s*,\s*\[esi\]\s*$/io;
$att_instr_to_intel{'imul	(%esi), %bl, $2'} = qr/^\s*imul\s*(dword)?\s*2,\s*bl\s*,\s*\[esi\]\s*$/io;
$att_instr_to_intel{'imul	(%esi), %bl, zz'} = qr/^\s*imul\s*(dword)?\s*zz,\s*bl\s*,\s*\[esi\]\s*$/io;
$att_instr_to_intel{'imul	(%esi), %bl, _L1'} = qr/^\s*imul\s*(dword)?\s*_L1,\s*bl\s*,\s*\[esi\]\s*$/io;
$att_instr_to_intel{'imul	(%esi), 2, %bl'} = qr/^\s*imul\s*(dword)?\s*bl,\s*2\s*,\s*\[esi\]\s*$/io;
$att_instr_to_intel{'imul	(%esi), $2, %bl'} = qr/^\s*imul\s*(dword)?\s*bl,\s*2\s*,\s*\[esi\]\s*$/io;
$att_instr_to_intel{'imul	(%esi), zz, %bl'} = qr/^\s*imul\s*(dword)?\s*bl,\s*zz\s*,\s*\[esi\]\s*$/io;
$att_instr_to_intel{'imul	(%esi), _L1, %bl'} = qr/^\s*imul\s*(dword)?\s*bl,\s*_L1\s*,\s*\[esi\]\s*$/io;
$att_instr_to_intel{'imul	%esi, %bl, 2'} = qr/^\s*imul\s*(dword)?\s*2,\s*bl\s*,\s*esi\s*$/io;
$att_instr_to_intel{'imul	%esi, %bl, $2'} = qr/^\s*imul\s*(dword)?\s*2,\s*bl\s*,\s*esi\s*$/io;
$att_instr_to_intel{'imul	%esi, %bl, zz'} = qr/^\s*imul\s*(dword)?\s*\[zz\],\s*bl\s*,\s*esi\s*$/io;
$att_instr_to_intel{'imul	%esi, %bl, _L1'} = qr/^\s*imul\s*(dword)?\s*_L1,\s*bl\s*,\s*esi\s*$/io;
$att_instr_to_intel{'imul	%esi, 2, %bl'} = qr/^\s*imul\s*(dword)?\s*bl,\s*2\s*,\s*esi\s*$/io;
$att_instr_to_intel{'imul	%esi, $2, %bl'} = qr/^\s*imul\s*(dword)?\s*bl,\s*2\s*,\s*esi\s*$/io;
$att_instr_to_intel{'imul	%esi, zz, %bl'} = qr/^\s*imul\s*(dword)?\s*bl,\s*\[zz\]\s*,\s*esi\s*$/io;
$att_instr_to_intel{'imul	%esi, _L1, %bl'} = qr/^\s*imul\s*(dword)?\s*bl,\s*_L1\s*,\s*esi\s*$/io;
$att_instr_to_intel{'imul	2, %esi, %bl'} = qr/^\s*imul\s*(dword)?\s*bl,\s*esi\s*,\s*2\s*$/io;
$att_instr_to_intel{'imul	$2, %esi, %bl'} = qr/^\s*imul\s*(dword)?\s*bl,\s*esi\s*,\s*2\s*$/io;
$att_instr_to_intel{'imul	zz, %esi, %bl'} = qr/^\s*imul\s*(dword)?\s*bl,\s*esi\s*,\s*\[zz\]\s*$/io;
$att_instr_to_intel{'imul	_L1, %esi, %bl'} = qr/^\s*imul\s*(dword)?\s*bl,\s*esi\s*,\s*_L1\s*$/io;

$att_instr_to_intel{'movsbw (%ecx), %edx'} = qr/^\s*movsx\s*edx\s*,\s*byte\s*\[ecx\]\s*$/io;
$att_instr_to_intel{'movsbl (%ecx), %eax'} = qr/^\s*movsx\s*eax\s*,\s*byte\s*\[ecx\]\s*$/io;
$att_instr_to_intel{'movswl (%ebx), %eax'} = qr/^\s*movsx\s*eax\s*,\s*word\s*\[ebx\]\s*$/io;
$att_instr_to_intel{'movzbw (%eax), %ebx'} = qr/^\s*movzx\s*ebx\s*,\s*byte\s*\[eax\]\s*$/io;
$att_instr_to_intel{'movzbl (%ebx), %ecx'} = qr/^\s*movzx\s*ecx\s*,\s*byte\s*\[ebx\]\s*$/io;
$att_instr_to_intel{'movzwl (%ecx), %edx'} = qr/^\s*movzx\s*edx\s*,\s*word\s*\[ecx\]\s*$/io;

$att_instr_to_intel{'zzzz	(%esi), %bl, 2'} = qr/^\s*zzzz\s*(dword)?\s*\[esi\]\s*,\s*bl\s*,\s*2\s*$/io;
$att_instr_to_intel{'zzzz	(%esi), %bl'} = qr/^\s*zzzz\s*(dword)?\s*\[esi\]\s*,\s*bl\s*$/io;
$att_instr_to_intel{'zzzz	(%esi)'} = qr/^\s*zzzz\s*(dword)?\s*\[esi\]\s*$/io;
$att_instr_to_intel{'zzzz	%esi, %bl, 2'} = qr/^\s*zzzz\s*(dword)?\s*esi\s*,\s*bl\s*,\s*2\s*$/io;
$att_instr_to_intel{'zzzz	%esi, %bl'} = qr/^\s*zzzz\s*(dword)?\s*esi\s*,\s*bl\s*$/io;
$att_instr_to_intel{'zzzz	%esi'} = qr/^\s*zzzz\s*(dword)?\s*esi\s*$/io;

$att_instr_to_intel{'fchs st(0)'} = qr/^\s*fchs\s*st\(0\)\s*$/io;
$att_instr_to_intel{'fmul st(0)'} = qr/^\s*fmul\s*st\(0\)\s*$/io;
$att_instr_to_intel{'fst st(0)'} = qr/^\s*fst\s*st\(0\)\s*$/io;
$att_instr_to_intel{'flds (%eax)'} = qr/^\s*fld\s*dword\s*\[\s*eax\s*\]\s*$/io;
$att_instr_to_intel{'fldl (%eax, %ebx, 2)'} = qr/^\s*fld\s*qword\s*\[\s*eax\s*\+\s*ebx\s*\*\s*2\]\s*$/io;
$att_instr_to_intel{'fldq zzz(,1)'} = qr/^\s*fld\s*qword\s*\[\s*zzz\s*\]\s*$/io;
$att_instr_to_intel{'fldt (%ecx)'} = qr/^\s*fld\s*tword\s*\[\s*ecx\s*\]\s*$/io;

$att_instr_to_intel{'ljmp [zzz]'} = qr/^\s*jmp\s*dword\s*\[\s*zzz\s*\]\s*$/io;
$att_instr_to_intel{'lcall zzz'} = qr/^\s*call\s*dword\s*zzz\s*$/io;
$att_instr_to_intel{'jmp a, b'} = qr/^\s*jmp\s*a:b\s*$/io;
$att_instr_to_intel{'lret 123'} = qr/^\s*ret\s*123\s*$/io;

$att_instr_to_intel{'cbtw'} = qr/^\s*cbw\s*$/io;
$att_instr_to_intel{'cwtl'} = qr/^\s*cwde\s*$/io;
$att_instr_to_intel{'cwtd'} = qr/^\s*cwd\s*$/io;
$att_instr_to_intel{'cltd'} = qr/^\s*cdq\s*$/io;

my %att_addr_to_intel;

$att_addr_to_intel{'-8(%esi,%ebp,4)'} = qr/^\s*\[\s*esi\s*\+\s*ebp\s*\*\s*4\s*\+*-8\s*\]\s*$/io;
$att_addr_to_intel{'(,%ebp,8)'} = qr/^\s*\[\s*ebp\s*\*\s*8\s*]\s*$/io;
$att_addr_to_intel{'st(0)'} = qr/^\s*st\(0\)\s*$/io;

# -----------

# Test::More:
plan tests => (keys %intel_instr_to_att)
	+ (keys %intel_addr_to_att)
	+ (keys %att_instr_to_intel)
	+ (keys %att_addr_to_intel)
	+ 10 + 10 + 5;

# -----------

foreach my $expr (keys %intel_instr_to_att) {

	my $res = conv_intel_instr_to_att ($expr);
	like ($res, $intel_instr_to_att{$expr},
	      "The result of conv_intel_instr_to_att ($expr) should match '$intel_instr_to_att{$expr}', but was '$res'.");
}

foreach my $expr (keys %intel_addr_to_att) {

	my $res = conv_intel_addr_to_att ($expr);
	like ($res, $intel_addr_to_att{$expr},
	      "The result of conv_intel_addr_to_att ($expr) should match '$intel_addr_to_att{$expr}', but was '$res'.");
}

foreach my $expr (keys %att_instr_to_intel) {

	my $res = conv_att_instr_to_intel ($expr);
	like ($res, $att_instr_to_intel{$expr},
	      "The result of conv_att_instr_to_intel ($expr) should match '$att_instr_to_intel{$expr}', but was '$res'.");
}

foreach my $expr (keys %att_addr_to_intel) {

	my $res = conv_att_addr_to_intel ($expr);
	like ($res, $att_addr_to_intel{$expr},
	      "The result of conv_att_addr_to_intel ($expr) should match '$att_addr_to_intel{$expr}', but was '$res'.");
}
# -----------

sub arr_contains($$) {

	my $arr = shift;
	my $key = shift;
	foreach (@$arr) {
		return 1 if $_ =~ /^$key$/i;
	}
	return 0;
}

my @converted = add_att_suffix_instr (
	'movzx',
	'movsx',

);
is ( arr_contains ( \@converted, 'movzbl'), 1, 'movzbl properly converted');
is ( arr_contains ( \@converted, 'movzwl'), 1, 'movzwl properly converted');
is ( arr_contains ( \@converted, 'movzbw'), 1, 'movzbw properly converted');
is ( arr_contains ( \@converted, 'movzbq'), 1, 'movzbq properly converted');
is ( arr_contains ( \@converted, 'movzwq'), 1, 'movzwq properly converted');

is ( arr_contains ( \@converted, 'movsbl'), 1, 'movsbl properly converted');
is ( arr_contains ( \@converted, 'movswl'), 1, 'movswl properly converted');
is ( arr_contains ( \@converted, 'movsbw'), 1, 'movsbw properly converted');
is ( arr_contains ( \@converted, 'movsbq'), 1, 'movsbq properly converted');
is ( arr_contains ( \@converted, 'movswq'), 1, 'movswq properly converted');

@converted = add_att_suffix_instr ('movzx eax, al');
is ( arr_contains ( \@converted, 'movzbl'), 1, 'movzbl properly converted 2');

@converted = add_att_suffix_instr ('movzx eax, ax');
is ( arr_contains ( \@converted, 'movzwl'), 1, 'movzwl properly converted 2');

@converted = add_att_suffix_instr ('movzx ax, al');
is ( arr_contains ( \@converted, 'movzbw'), 1, 'movzbw properly converted 2');

@converted = add_att_suffix_instr ('movzx rax, al');
is ( arr_contains ( \@converted, 'movzbq'), 1, 'movzbq properly converted 2');

@converted = add_att_suffix_instr ('movzx rax, ax');
is ( arr_contains ( \@converted, 'movzwq'), 1, 'movzwq properly converted 2');

@converted = add_att_suffix_instr ('movsx eax, al');
is ( arr_contains ( \@converted, 'movsbl'), 1, 'movsbl properly converted 2');

@converted = add_att_suffix_instr ('movsx eax, ax');
is ( arr_contains ( \@converted, 'movswl'), 1, 'movswl properly converted 2');

@converted = add_att_suffix_instr ('movsx ax, al');
is ( arr_contains ( \@converted, 'movsbw'), 1, 'movsbw properly converted 2');

@converted = add_att_suffix_instr ('movsx rax, al');
is ( arr_contains ( \@converted, 'movsbq'), 1, 'movsbq properly converted 2');

@converted = add_att_suffix_instr ('movsx rax, ax');
is ( arr_contains ( \@converted, 'movswq'), 1, 'movswq properly converted 2');


@converted = add_att_suffix_instr ('movzx bl, al'); # invalid
is ( arr_contains ( \@converted, 'movzbb'), 0, 'movzbb properly converted');

@converted = add_att_suffix_instr ('movzx bx, ax'); # invalid
is ( arr_contains ( \@converted, 'movzww'), 0, 'movzww properly converted');

@converted = add_att_suffix_instr ('movzx ebx, eax'); # invalid
is ( arr_contains ( \@converted, 'movzll'), 0, 'movzll properly converted');

@converted = add_att_suffix_instr ('movzx rax, eax'); # invalid
is ( arr_contains ( \@converted, 'movzlq'), 0, 'movzlq properly converted');

@converted = add_att_suffix_instr ('movzx rax, rbx'); # invalid
is ( arr_contains ( \@converted, 'movzqq'), 0, 'movzqq properly converted');
