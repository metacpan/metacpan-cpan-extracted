#!perl -T -w

use strict;
use warnings;

use Test::More tests => 17 + 10 + 127 + 12 + 3 + 21 + 5 + 75 + 75 + 75 + 50 + 20 + 10 + 10 + 5;
use Asm::X86 qw(
	conv_att_addr_to_intel conv_intel_addr_to_att
	conv_att_instr_to_intel conv_intel_instr_to_att
	add_att_suffix_instr
	);

is ( conv_intel_instr_to_att ('mov al, byte [ecx+ebx*2+-1]') =~
	/^\s*movb.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%al\s*$/io, 1, 'mov test 1 - ' . conv_intel_instr_to_att ('mov al, byte [ecx+ebx*2+-1]'));
is ( conv_intel_instr_to_att ('mov al, [ecx+ebx*2+-1]') =~
	/^\s*movb.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%al\s*$/io, 1, 'mov test 2 - ' . conv_intel_instr_to_att ('mov al, [ecx+ebx*2+-1]'));
is ( conv_intel_instr_to_att ('mov ax, word [ecx+ebx*2+-1]') =~
	/^\s*movw.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%ax\s*$/io, 1, 'mov test 3 - ' . conv_intel_instr_to_att ('mov ax, word [ecx+ebx*2+-1]'));
is ( conv_intel_instr_to_att ('mov ax, [ecx+ebx*2+-1]') =~
	/^\s*movw.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%ax\s*$/io, 1, 'mov test 4 - ' . conv_intel_instr_to_att ('mov ax, [ecx+ebx*2+-1]'));
is ( conv_intel_instr_to_att ('mov eax, dword [ecx+ebx*2+-1]') =~
	/^\s*movl.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%eax\s*$/io, 1, 'mov test 5 - ' . conv_intel_instr_to_att ('mov eax, dword [ecx+ebx*2+-1]'));
is ( conv_intel_instr_to_att ('mov eax, [ecx+ebx*2+-1]') =~
	/^\s*movl.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%eax\s*$/io, 1, 'mov test 6 - ' . conv_intel_instr_to_att ('mov eax, [ecx+ebx*2+-1]'));
is ( conv_intel_instr_to_att ('mov rax, qword [ecx+ebx*2+-1]') =~
	/^\s*movq.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%rax\s*$/io, 1, 'mov test 7 - ' . conv_intel_instr_to_att ('mov rax, qword [ecx+ebx*2+-1]'));
is ( conv_intel_instr_to_att ('mov rax, [ecx+ebx*2+-1]') =~
	/^\s*movq.*\(?-1\)?\(\%ecx,\%ebx,2\),\s*\%rax\s*$/io, 1, 'mov test 8 - ' . conv_intel_instr_to_att ('mov rax, [ecx+ebx*2+-1]'));

is ( conv_intel_instr_to_att ('mov byte [ecx+ebx*2+-1], al') =~
	/^\s*movb\s*\%al\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io, 1, 'mov test 9 - ' . conv_intel_instr_to_att ('mov byte [ecx+ebx*2+-1], al'));
is ( conv_intel_instr_to_att ('mov [ecx+ebx*2+-1], al') =~
	/^\s*movb\s*\%al\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io, 1, 'mov test 10 - ' . conv_intel_instr_to_att ('mov [ecx+ebx*2+-1], al'));
is ( conv_intel_instr_to_att ('mov word [ecx+ebx*2+-1], ax') =~
	/^\s*movw\s*\%ax\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io, 1, 'mov test 11 - ' . conv_intel_instr_to_att ('mov word [ecx+ebx*2+-1], ax'));
is ( conv_intel_instr_to_att ('mov [ecx+ebx*2+-1], ax') =~
	/^\s*movw\s*\%ax\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io, 1, 'mov test 12 - ' . conv_intel_instr_to_att ('mov [ecx+ebx*2+-1], ax'));
is ( conv_intel_instr_to_att ('mov dword [ecx+ebx*2+-1], eax') =~
	/^\s*movl\s*\%eax\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io, 1, 'mov test 13 - ' . conv_intel_instr_to_att ('mov dword [ecx+ebx*2+-1], eax'));
is ( conv_intel_instr_to_att ('mov [ecx+ebx*2+-1], eax') =~
	/^\s*movl\s*\%eax\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io, 1, 'mov test 14 - ' . conv_intel_instr_to_att ('mov [ecx+ebx*2+-1], eax'));
is ( conv_intel_instr_to_att ('mov qword [ecx+ebx*2+-1], rax') =~
	/^\s*movq\s*\%rax\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io, 1, 'mov test 15 - ' . conv_intel_instr_to_att ('mov qword [ecx+ebx*2+-1], rax'));
is ( conv_intel_instr_to_att ('mov [ecx+ebx*2+-1], rax') =~
	/^\s*movq\s*\%rax\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io, 1, 'mov test 16 - ' . conv_intel_instr_to_att ('mov [ecx+ebx*2+-1], rax'));
is ( conv_intel_instr_to_att ('mov [ecx+ebx*2+-1], [eax]') =~ # fake instruction, fake result
	/^\s*mov\s*\[\%eax\]\s*,\s*\(?-1\)?\(\%ecx,\%ebx,2\)\s*$/io, 1, 'mov test 17 - ' . conv_intel_instr_to_att ('mov [ecx+ebx*2+-1], [eax]'));

is ( conv_intel_instr_to_att ('inc byte ptr [si]') =~
	/^\s*incb\s*\(\%si\)\s*$/io, 1, 'inc test 1' );
is ( conv_intel_instr_to_att ('inc word ptr [si]') =~
	/^\s*incw\s*\(\%si\)\s*$/io, 1, 'inc test 2' );
is ( conv_intel_instr_to_att ('inc dword ptr [si]') =~
	/^\s*incl\s*\(\%si\)\s*$/io, 1, 'inc test 3' );
is ( conv_intel_instr_to_att ('inc qword ptr [rsi]') =~
	/^\s*incq\s*\(\%rsi\)\s*$/io, 1, 'inc test 4' );
is ( conv_intel_instr_to_att ('inc al') =~
	/^\s*incb\s*\%al\s*$/io, 1, 'inc test 5 - ' . conv_intel_instr_to_att ('inc al') );
is ( conv_intel_instr_to_att ('inc ax') =~
	/^\s*incw\s*\%ax\s*$/io, 1, 'inc test 6 - ' . conv_intel_instr_to_att ('inc ax') );
is ( conv_intel_instr_to_att ('inc eax') =~
	/^\s*incl\s*\%eax\s*$/io, 1, 'inc test 7 - ' . conv_intel_instr_to_att ('inc eax') );
is ( conv_intel_instr_to_att ('inc rax') =~
	/^\s*incq\s*\%rax\s*$/io, 1, 'inc test 8 - ' . conv_intel_instr_to_att ('inc rax') );
is ( conv_intel_instr_to_att ('inc zzz') =~
	/^\s*inc\s*\$zzz\s*$/io, 1, 'inc test 9 - ' . conv_intel_instr_to_att ('inc zzz') );
is ( conv_intel_instr_to_att ('pop') =~
	/^\s*pop\s*$/io, 1, 'pop test - ' . conv_intel_instr_to_att ('pop') );

is ( conv_intel_instr_to_att ('imul eax, ebx, 2') =~
	/^\s*imull\s*\$2\s*,\s*%ebx\s*,\s*%eax\s*$/io, 1, 'imul intel test 1');
is ( conv_intel_instr_to_att ('imul eax, [ebx], 2') =~
	/^\s*imull\s*\$2\s*,\s*\(%ebx\)\s*,\s*%eax\s*$/io, 1, 'imul intel test 2');
is ( conv_intel_instr_to_att ('imul [eax], ebx, 2') =~
	/^\s*imull\s*\$2\s*,\s*%ebx\s*,\s*\(%eax\)\s*$/io, 1, 'imul intel test 3');
is ( conv_intel_instr_to_att ('imul [eax], [ebx], 2') =~
	/^\s*imul\s*\$2\s*,\s*\(%ebx\)\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 4 - ' . conv_intel_instr_to_att ('imul [eax], [ebx], 2') );
is ( conv_intel_instr_to_att ('imul eax, 2, ebx') =~
	/^\s*imull\s*%ebx\s*,\s*\$2\s*,\s*%eax\s*$/io, 1, 'imul intel test 5');
is ( conv_intel_instr_to_att ('imul eax, 2, [ebx]') =~
	/^\s*imull\s*\(%ebx\)\s*,\s*\$2\s*,\s*%eax\s*$/io, 1, 'imul intel test 6');
is ( conv_intel_instr_to_att ('imul [eax], 2, ebx') =~
	/^\s*imull\s*%ebx\s*,\s*\$2\s*,\s*\(%eax\)\s*$/io, 1, 'imul intel test 7 - ' . conv_intel_instr_to_att ('imul [eax], 2, ebx') );
is ( conv_intel_instr_to_att ('imul [eax], 2, [ebx]') =~
	/^\s*imul\s*\(%ebx\)\s*,\s*\$2\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 8 - ' . conv_intel_instr_to_att ('imul [eax], 2, [ebx]') );
is ( conv_intel_instr_to_att ('imul 2, eax, ebx') =~
	/^\s*imull\s*%ebx\s*,\s*%eax\s*,\s*\$2\s*$/io, 1, 'imul intel test 9');
is ( conv_intel_instr_to_att ('imul 2, eax, [ebx]') =~
	/^\s*imull\s*\(%ebx\)\s*,\s*%eax\s*,\s*\$2\s*$/io, 1, 'imul intel test 10');
is ( conv_intel_instr_to_att ('imul 2, [eax], ebx') =~
	/^\s*imull\s*%ebx\s*,\s*\(%eax\)\s*,\s*\$2\s*$/io, 1, 'imul intel test 11 - ' . conv_intel_instr_to_att ('imul 2, [eax], ebx') );
is ( conv_intel_instr_to_att ('imul 2, [eax], [ebx]') =~
	/^\s*imul\s*\(%ebx\)\s*,\s*\[%eax\]\s*,\s*\$2\s*$/io, 1, 'imul intel test 12 - ' . conv_intel_instr_to_att ('imul 2, [eax], [ebx]') );

is ( conv_intel_instr_to_att ('imul eax, bl, [ebx]') =~
	/^\s*imulb\s*\(%ebx\)\s*,\s*%bl\s*,\s*%eax\s*$/io, 1, 'imul intel test 13 - ' . conv_intel_instr_to_att ('imul eax, bl, [ebx]') );
is ( conv_intel_instr_to_att ('imul eax, bx, [ebx]') =~
	/^\s*imulw\s*\(%ebx\)\s*,\s*%bx\s*,\s*%eax\s*$/io, 1, 'imul intel test 14 - ' . conv_intel_instr_to_att ('imul eax, bx, [ebx]') );
is ( conv_intel_instr_to_att ('imul eax, ebx, [ebx]') =~
	/^\s*imull\s*\(%ebx\)\s*,\s*%ebx\s*,\s*%eax\s*$/io, 1, 'imul intel test 15 - ' . conv_intel_instr_to_att ('imul eax, ebx, [ebx]') );
is ( conv_intel_instr_to_att ('imul eax, rbx, [ebx]') =~
	/^\s*imulq\s*\(%ebx\)\s*,\s*%rbx\s*,\s*%eax\s*$/io, 1, 'imul intel test 16 - ' . conv_intel_instr_to_att ('imul eax, rbx, [ebx]') );
is ( conv_intel_instr_to_att ('imul eax, zzz, [ebx]') =~
	/^\s*imull\s*\(%ebx\)\s*,\s*\$zzz\s*,\s*%eax\s*$/io, 1, 'imul intel test 17 - ' . conv_intel_instr_to_att ('imul eax, zzz, [ebx]') );

is ( conv_intel_instr_to_att ('imul [eax], bl, [ebx]') =~
	/^\s*imulb\s*\(%ebx\)\s*,\s*%bl\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 18 - ' . conv_intel_instr_to_att ('imul [eax], bl, [ebx]') );
is ( conv_intel_instr_to_att ('imul [eax], bx, [ebx]') =~
	/^\s*imulw\s*\(%ebx\)\s*,\s*%bx\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 19 - ' . conv_intel_instr_to_att ('imul [eax], bx, [ebx]') );
is ( conv_intel_instr_to_att ('imul [eax], ebx, [ebx]') =~
	/^\s*imull\s*\(%ebx\)\s*,\s*%ebx\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 20 - ' . conv_intel_instr_to_att ('imul [eax], ebx, [ebx]') );
is ( conv_intel_instr_to_att ('imul [eax], rbx, [ebx]') =~
	/^\s*imulq\s*\(%ebx\)\s*,\s*%rbx\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 21 - ' . conv_intel_instr_to_att ('imul [eax], rbx, [ebx]') );
is ( conv_intel_instr_to_att ('imul [eax], zzz, [ebx]') =~
	/^\s*imul\s*\(%ebx\)\s*,\s*\$zzz\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 22 - ' . conv_intel_instr_to_att ('imul [eax], zzz, [ebx]') );

is ( conv_intel_instr_to_att ('imul bl, [eax], [ebx]') =~
	/^\s*imulb\s*\(%ebx\)\s*,\s*\[%eax\]\s*,\s*%bl\s*$/io, 1, 'imul intel test 23 - ' . conv_intel_instr_to_att ('imul bl, [eax], [ebx]') );
is ( conv_intel_instr_to_att ('imul bx, [eax], [ebx]') =~
	/^\s*imulw\s*\(%ebx\)\s*,\s*\[%eax\]\s*,\s*%bx\s*$/io, 1, 'imul intel test 24 - ' . conv_intel_instr_to_att ('imul bx, [eax], [ebx]') );
is ( conv_intel_instr_to_att ('imul ebx, [eax], [ebx]') =~
	/^\s*imull\s*\(%ebx\)\s*,\s*\[%eax\]\s*,\s*%ebx\s*$/io, 1, 'imul intel test 25 - ' . conv_intel_instr_to_att ('imul ebx, [eax], [ebx]') );
is ( conv_intel_instr_to_att ('imul rbx, [eax], [ebx]') =~
	/^\s*imulq\s*\(%ebx\)\s*,\s*\[%eax\]\s*,\s*%rbx\s*$/io, 1, 'imul intel test 26 - ' . conv_intel_instr_to_att ('imul rbx, [eax], [ebx]') );
is ( conv_intel_instr_to_att ('imul zzz, [eax], [ebx]') =~
	/^\s*imul\s*\(%ebx\)\s*,\s*\[%eax\],\s*\$zzz\s*\s*$/io, 1, 'imul intel test 27 - ' . conv_intel_instr_to_att ('imul zzz, [eax], [ebx]') );

is ( conv_intel_instr_to_att ('imul eax, bx, 2') =~
	/^\s*imull\s*\$2\s*,\s*%bx\s*,\s*%eax\s*$/io, 1, 'imul intel test 28');
is ( conv_intel_instr_to_att ('imul eax, [bx], 2') =~
	/^\s*imull\s*\$2\s*,\s*\(%bx\)\s*,\s*%eax\s*$/io, 1, 'imul intel test 29');
is ( conv_intel_instr_to_att ('imul [eax], bx, 2') =~
	/^\s*imulw\s*\$2\s*,\s*%bx\s*,\s*\(%eax\)\s*$/io, 1, 'imul intel test 30');
is ( conv_intel_instr_to_att ('imul [eax], [bx], 2') =~
	/^\s*imul\s*\$2\s*,\s*\(%bx\)\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 31 - ' . conv_intel_instr_to_att ('imul [eax], [bx], 2') );
is ( conv_intel_instr_to_att ('imul eax, 2, bx') =~
	/^\s*imulw\s*%bx\s*,\s*\$2\s*,\s*%eax\s*$/io, 1, 'imul intel test 32');
is ( conv_intel_instr_to_att ('imul eax, 2, [bx]') =~
	/^\s*imull\s*\(%bx\)\s*,\s*\$2\s*,\s*%eax\s*$/io, 1, 'imul intel test 33');
is ( conv_intel_instr_to_att ('imul [eax], 2, bx') =~
	/^\s*imulw\s*%bx\s*,\s*\$2\s*,\s*\(%eax\)\s*$/io, 1, 'imul intel test 34 - ' . conv_intel_instr_to_att ('imul [eax], 2, bx') );
is ( conv_intel_instr_to_att ('imul [eax], 2, [bx]') =~
	/^\s*imul\s*\(%bx\)\s*,\s*\$2\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 35 - ' . conv_intel_instr_to_att ('imul [eax], 2, [bx]') );
is ( conv_intel_instr_to_att ('imul 2, eax, bx') =~
	/^\s*imulw\s*%bx\s*,\s*%eax\s*,\s*\$2\s*$/io, 1, 'imul intel test 36');
is ( conv_intel_instr_to_att ('imul 2, eax, [bx]') =~
	/^\s*imull\s*\(%bx\)\s*,\s*%eax\s*,\s*\$2\s*$/io, 1, 'imul intel test 37');
is ( conv_intel_instr_to_att ('imul 2, [eax], bx') =~
	/^\s*imulw\s*%bx\s*,\s*\(%eax\)\s*,\s*\$2\s*$/io, 1, 'imul intel test 38 - ' . conv_intel_instr_to_att ('imul 2, [eax], bx') );
is ( conv_intel_instr_to_att ('imul 2, [eax], [bx]') =~
	/^\s*imul\s*\(%bx\)\s*,\s*\[%eax\]\s*,\s*\$2\s*$/io, 1, 'imul intel test 39 - ' . conv_intel_instr_to_att ('imul 2, [eax], [bx]') );

is ( conv_intel_instr_to_att ('imul bx, eax, 2') =~
	/^\s*imulw\s*\$2\s*,\s*%eax\s*,\s*%bx\s*$/io, 1, 'imul intel test 40 - ' . conv_intel_instr_to_att ('imul bx, eax, 2'));
is ( conv_intel_instr_to_att ('imul [bx], eax, 2') =~
	/^\s*imull\s*\$2\s*,\s*%eax\s*,\s*\(%bx\)\s*$/io, 1, 'imul intel test 41');
is ( conv_intel_instr_to_att ('imul bx, [eax], 2') =~
	/^\s*imulw\s*\$2\s*,\s*\(%eax\)\s*,\s*%bx\s*$/io, 1, 'imul intel test 42 - ' . conv_intel_instr_to_att ('imul bx, [eax], 2'));
is ( conv_intel_instr_to_att ('imul [bx], [eax], 2') =~
	/^\s*imul\s*\$2\s*,\s*\(%eax\)\s*,\s*\[%bx\]\s*$/io, 1, 'imul intel test 43 - ' . conv_intel_instr_to_att ('imul [bx], [eax], 2') );
is ( conv_intel_instr_to_att ('imul bx, 2, eax') =~
	/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*%bx\s*$/io, 1, 'imul intel test 44 - ' . conv_intel_instr_to_att ('imul bx, 2, eax'));
is ( conv_intel_instr_to_att ('imul [bx], 2, eax') =~
	/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*\(%bx\)\s*$/io, 1, 'imul intel test 45');
is ( conv_intel_instr_to_att ('imul bx, 2, [eax]') =~
	/^\s*imulw\s*\(%eax\)\s*,\s*\$2\s*,\s*%bx\s*$/io, 1, 'imul intel test 46 - ' . conv_intel_instr_to_att ('imul bx, 2, [eax]') );
is ( conv_intel_instr_to_att ('imul [bx], 2, [eax]') =~
	/^\s*imul\s\(%eax\)\s*,\s*\$2,\s*\[%bx\]\s*\s*$/io, 1, 'imul intel test 47 - ' . conv_intel_instr_to_att ('imul [bx], 2, [eax]') );

is ( conv_intel_instr_to_att ('imul eax, bl, 2') =~
	/^\s*imull\s*\$2\s*,\s*%bl\s*,\s*%eax\s*$/io, 1, 'imul intel test 48');
is ( conv_intel_instr_to_att ('imul eax, [bl], 2') =~
	/^\s*imull\s*\$2\s*,\s*\(%bl\)\s*,\s*%eax\s*$/io, 1, 'imul intel test 49');
is ( conv_intel_instr_to_att ('imul [eax], bl, 2') =~
	/^\s*imulb\s*\$2\s*,\s*%bl\s*,\s*\(%eax\)\s*$/io, 1, 'imul intel test 50');
is ( conv_intel_instr_to_att ('imul [eax], [bl], 2') =~
	/^\s*imul\s*\$2\s*,\s*\(%bl\)\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 51 - ' . conv_intel_instr_to_att ('imul [eax], [bl], 2') );
is ( conv_intel_instr_to_att ('imul eax, 2, bl') =~
	/^\s*imulb\s*%bl\s*,\s*\$2\s*,\s*%eax\s*$/io, 1, 'imul intel test 52');
is ( conv_intel_instr_to_att ('imul eax, 2, [bl]') =~
	/^\s*imull\s*\(%bl\)\s*,\s*\$2\s*,\s*%eax\s*$/io, 1, 'imul intel test 53');
is ( conv_intel_instr_to_att ('imul [eax], 2, bl') =~
	/^\s*imulb\s*%bl\s*,\s*\$2\s*,\s*\(%eax\)\s*$/io, 1, 'imul intel test 54 - ' . conv_intel_instr_to_att ('imul [eax], 2, bl') );
is ( conv_intel_instr_to_att ('imul [eax], 2, [bl]') =~
	/^\s*imul\s*\(%bl\)\s*,\s*\$2\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 55 - ' . conv_intel_instr_to_att ('imul [eax], 2, [bl]') );
is ( conv_intel_instr_to_att ('imul 2, eax, bl') =~
	/^\s*imulb\s*%bl\s*,\s*%eax\s*,\s*\$2\s*$/io, 1, 'imul intel test 56');
is ( conv_intel_instr_to_att ('imul 2, eax, [bl]') =~
	/^\s*imull\s*\(%bl\)\s*,\s*%eax\s*,\s*\$2\s*$/io, 1, 'imul intel test 57');
is ( conv_intel_instr_to_att ('imul 2, [eax], bl') =~
	/^\s*imulb\s*%bl\s*,\s*\(%eax\)\s*,\s*\$2\s*$/io, 1, 'imul intel test 58 - ' . conv_intel_instr_to_att ('imul 2, [eax], bl') );
is ( conv_intel_instr_to_att ('imul 2, [eax], [bl]') =~
	/^\s*imul\s*\(%bl\)\s*,\s*\[%eax\]\s*,\s*\$2\s*$/io, 1, 'imul intel test 59 - ' . conv_intel_instr_to_att ('imul 2, [eax], [bl]') );

is ( conv_intel_instr_to_att ('imul bl, eax, 2') =~
	/^\s*imulb\s*\$2\s*,\s*%eax\s*,\s*%bl\s*$/io, 1, 'imul intel test 60');
is ( conv_intel_instr_to_att ('imul [bl], eax, 2') =~
	/^\s*imull\s*\$2\s*,\s*%eax\s*,\s*\(%bl\)\s*$/io, 1, 'imul intel test 61');
is ( conv_intel_instr_to_att ('imul bl, [eax], 2') =~
	/^\s*imulb\s*\$2\s*,\s*\(%eax\)\s*,\s*%bl\s*$/io, 1, 'imul intel test 62');
is ( conv_intel_instr_to_att ('imul [bl], [eax], 2') =~
	/^\s*imul\s*\$2\s*,\s*\(%eax\)\s*,\s*\[%bl\]\s*$/io, 1, 'imul intel test 63 - ' . conv_intel_instr_to_att ('imul [bl], [eax], 2') );
is ( conv_intel_instr_to_att ('imul bl, 2, eax') =~
	/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*%bl\s*$/io, 1, 'imul intel test 64 - ' . conv_intel_instr_to_att ('imul bl, 2, eax'));
is ( conv_intel_instr_to_att ('imul [bl], 2, eax') =~
	/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*\(%bl\)\s*$/io, 1, 'imul intel test 65');
is ( conv_intel_instr_to_att ('imul bl, 2, [eax]') =~
	/^\s*imulb\s*\(%eax\)\s*,\s*\$2\s*,\s*%bl\s*$/io, 1, 'imul intel test 66 - ' . conv_intel_instr_to_att ('imul bl, 2, [eax]') );
is ( conv_intel_instr_to_att ('imul [bl], 2, [eax]') =~
	/^\s*imul\s\(%eax\)\s*,\s*\$2,\s*\[%bl\]\s*\s*$/io, 1, 'imul intel test 67 - ' . conv_intel_instr_to_att ('imul [bl], 2, [eax]') );

is ( conv_intel_instr_to_att ('imul eax, rbx, 2') =~
	/^\s*imull\s*\$2\s*,\s*%rbx\s*,\s*%eax\s*$/io, 1, 'imul intel test 68');
is ( conv_intel_instr_to_att ('imul eax, [rbx], 2') =~
	/^\s*imull\s*\$2\s*,\s*\(%rbx\)\s*,\s*%eax\s*$/io, 1, 'imul intel test 69');
is ( conv_intel_instr_to_att ('imul [eax], rbx, 2') =~
	/^\s*imulq\s*\$2\s*,\s*%rbx\s*,\s*\(%eax\)\s*$/io, 1, 'imul intel test 70 - ' . conv_intel_instr_to_att ('imul [eax], rbx, 2') );
is ( conv_intel_instr_to_att ('imul [eax], [rbx], 2') =~
	/^\s*imul\s*\$2\s*,\s*\(%rbx\)\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 71 - ' . conv_intel_instr_to_att ('imul [eax], [rbx], 2') );
is ( conv_intel_instr_to_att ('imul eax, 2, rbx') =~
	/^\s*imulq\s*%rbx\s*,\s*\$2\s*,\s*%eax\s*$/io, 1, 'imul intel test 72 - ' . conv_intel_instr_to_att ('imul eax, 2, rbx'));
is ( conv_intel_instr_to_att ('imul eax, 2, [rbx]') =~
	/^\s*imull\s*\(%rbx\)\s*,\s*\$2\s*,\s*%eax\s*$/io, 1, 'imul intel test 73');
is ( conv_intel_instr_to_att ('imul [eax], 2, rbx') =~
	/^\s*imulq\s*%rbx\s*,\s*\$2\s*,\s*\(%eax\)\s*$/io, 1, 'imul intel test 74 - ' . conv_intel_instr_to_att ('imul [eax], 2, rbx') );
is ( conv_intel_instr_to_att ('imul [eax], 2, [rbx]') =~
	/^\s*imul\s*\(%rbx\)\s*,\s*\$2\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 75 - ' . conv_intel_instr_to_att ('imul [eax], 2, [rbx]') );
is ( conv_intel_instr_to_att ('imul 2, eax, rbx') =~
	/^\s*imulq\s*%rbx\s*,\s*%eax\s*,\s*\$2\s*$/io, 1, 'imul intel test 76 - ' . conv_intel_instr_to_att ('imul 2, eax, rbx'));
is ( conv_intel_instr_to_att ('imul 2, eax, [rbx]') =~
	/^\s*imull\s*\(%rbx\)\s*,\s*%eax\s*,\s*\$2\s*$/io, 1, 'imul intel test 77');
is ( conv_intel_instr_to_att ('imul 2, [eax], rbx') =~
	/^\s*imulq\s*%rbx\s*,\s*\(%eax\)\s*,\s*\$2\s*$/io, 1, 'imul intel test 78 - ' . conv_intel_instr_to_att ('imul 2, [eax], rbx') );
is ( conv_intel_instr_to_att ('imul 2, [eax], [rbx]') =~
	/^\s*imul\s*\(%rbx\)\s*,\s*\[%eax\]\s*,\s*\$2\s*$/io, 1, 'imul intel test 79 - ' . conv_intel_instr_to_att ('imul 2, [eax], [rbx]') );

is ( conv_intel_instr_to_att ('imul rbx, eax, 2') =~
	/^\s*imulq\s*\$2\s*,\s*%eax\s*,\s*%rbx\s*$/io, 1, 'imul intel test 80');
is ( conv_intel_instr_to_att ('imul [rbx], eax, 2') =~
	/^\s*imull\s*\$2\s*,\s*%eax\s*,\s*\(%rbx\)\s*$/io, 1, 'imul intel test 81');
is ( conv_intel_instr_to_att ('imul rbx, [eax], 2') =~
	/^\s*imulq\s*\$2\s*,\s*\(%eax\)\s*,\s*%rbx\s*$/io, 1, 'imul intel test 82');
is ( conv_intel_instr_to_att ('imul [rbx], [eax], 2') =~
	/^\s*imul\s*\$2\s*,\s*\(%eax\)\s*,\s*\[%rbx\]\s*$/io, 1, 'imul intel test 83 - ' . conv_intel_instr_to_att ('imul [rbx], [eax], 2') );
is ( conv_intel_instr_to_att ('imul rbx, 2, eax') =~
	/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*%rbx\s*$/io, 1, 'imul intel test 84 - ' . conv_intel_instr_to_att ('imul rbx, 2, eax'));
is ( conv_intel_instr_to_att ('imul [rbx], 2, eax') =~
	/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*\(%rbx\)\s*$/io, 1, 'imul intel test 85');
is ( conv_intel_instr_to_att ('imul rbx, 2, [eax]') =~
	/^\s*imulq\s*\(%eax\)\s*,\s*\$2\s*,\s*%rbx\s*$/io, 1, 'imul intel test 86 - ' . conv_intel_instr_to_att ('imul rbx, 2, [eax]') );
is ( conv_intel_instr_to_att ('imul [rbx], 2, [eax]') =~
	/^\s*imul\s\(%eax\)\s*,\s*\$2,\s*\[%rbx\]\s*\s*$/io, 1, 'imul intel test 87 - ' . conv_intel_instr_to_att ('imul [rbx], 2, [eax]') );

is ( conv_intel_instr_to_att ('imul eax, zzz, 2') =~
	/^\s*imull\s*\$2\s*,\s*\$zzz\s*,\s*%eax\s*$/io, 1, 'imul intel test 88');
is ( conv_intel_instr_to_att ('imul eax, [zzz], 2') =~
	/^\s*imull\s*\$2\s*,\s*\$?zzz\(,1\)\s*,\s*%eax\s*$/io, 1, 'imul intel test 89 - ' . conv_intel_instr_to_att ('imul eax, [zzz], 2'));
is ( conv_intel_instr_to_att ('imul [eax], zzz, 2') =~
	/^\s*imul\s*\$2\s*,\s*\$zzz\s*,\s*\(%eax\)\s*$/io, 1, 'imul intel test 90 - ' . conv_intel_instr_to_att ('imul [eax], zzz, 2') );
is ( conv_intel_instr_to_att ('imul [eax], [zzz], 2') =~
	/^\s*imul\s*\$2\s*,\s*\$?zzz\(,1\)\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 91 - ' . conv_intel_instr_to_att ('imul [eax], [zzz], 2') );
is ( conv_intel_instr_to_att ('imul eax, 2, zzz') =~
	/^\s*imull\s*\$zzz\s*,\s*\$2\s*,\s*%eax\s*$/io, 1, 'imul intel test 92 - ' . conv_intel_instr_to_att ('imul eax, 2, zzz'));
is ( conv_intel_instr_to_att ('imul eax, 2, [zzz]') =~
	/^\s*imull\s*\$?zzz\(,1\)\s*,\s*\$2\s*,\s*%eax\s*$/io, 1, 'imul intel test 93 - ' . conv_intel_instr_to_att ('imul eax, 2, [zzz]'));
is ( conv_intel_instr_to_att ('imul [eax], 2, zzz') =~
	/^\s*imul\s*\$zzz\s*,\s*\$2\s*,\s*\(%eax\)\s*$/io, 1, 'imul intel test 94 - ' . conv_intel_instr_to_att ('imul [eax], 2, zzz') );
is ( conv_intel_instr_to_att ('imul [eax], 2, [zzz]') =~
	/^\s*imul\s*\$?zzz\(,1\)\s*,\s*\$2\s*,\s*\[%eax\]\s*$/io, 1, 'imul intel test 95 - ' . conv_intel_instr_to_att ('imul [eax], 2, [zzz]') );
is ( conv_intel_instr_to_att ('imul 2, eax, zzz') =~
	/^\s*imul\s*\$zzz\s*,\s*%eax\s*,\s*\$2\s*$/io, 1, 'imul intel test 96 - ' . conv_intel_instr_to_att ('imul 2, eax, zzz'));
is ( conv_intel_instr_to_att ('imul 2, eax, [zzz]') =~
	/^\s*imull\s*\$?zzz\(,1\)\s*,\s*%eax\s*,\s*\$2\s*$/io, 1, 'imul intel test 97 - ' . conv_intel_instr_to_att ('imul 2, eax, [zzz]'));
is ( conv_intel_instr_to_att ('imul 2, [eax], zzz') =~
	/^\s*imul\s*\$zzz\s*,\s*\(%eax\)\s*,\s*\$2\s*$/io, 1, 'imul intel test 98 - ' . conv_intel_instr_to_att ('imul 2, [eax], zzz') );
is ( conv_intel_instr_to_att ('imul 2, [eax], [zzz]') =~
	/^\s*imul\s*\$?zzz\(,1\)\s*,\s*\[%eax\]\s*,\s*\$2\s*$/io, 1, 'imul intel test 99 - ' . conv_intel_instr_to_att ('imul 2, [eax], [zzz]') );

is ( conv_intel_instr_to_att ('imul zzz, eax, 2') =~
	/^\s*imul\s*\$2\s*,\s*%eax\s*,\s*\$zzz\s*$/io, 1, 'imul intel test 100');
is ( conv_intel_instr_to_att ('imul [zzz], eax, 2') =~
	/^\s*imull\s*\$2\s*,\s*%eax\s*,\s*\$?zzz\(,1\)\s*$/io, 1, 'imul intel test 101 - ' . conv_intel_instr_to_att ('imul [zzz], eax, 2'));
is ( conv_intel_instr_to_att ('imul zzz, [eax], 2') =~
	/^\s*imul\s*\$2\s*,\s*\(%eax\)\s*,\s*\$zzz\s*$/io, 1, 'imul intel test 102');
is ( conv_intel_instr_to_att ('imul [zzz], [eax], 2') =~
	/^\s*imul\s*\$2\s*,\s*\(%eax\)\s*,\s*\[zzz\]\s*$/io, 1, 'imul intel test 103 - ' . conv_intel_instr_to_att ('imul [zzz], [eax], 2') );
is ( conv_intel_instr_to_att ('imul zzz, 2, eax') =~
	/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*\$zzz\s*$/io, 1, 'imul intel test 104 - ' . conv_intel_instr_to_att ('imul zzz, 2, eax'));
is ( conv_intel_instr_to_att ('imul [zzz], 2, eax') =~
	/^\s*imull\s*%eax\s*,\s*\$2\s*,\s*\$?zzz\(,1\)\s*$/io, 1, 'imul intel test 105 - '. conv_intel_instr_to_att ('imul [zzz], 2, eax'));
is ( conv_intel_instr_to_att ('imul zzz, 2, [eax]') =~
	/^\s*imul\s*\(%eax\)\s*,\s*\$2\s*,\s*\$zzz\s*$/io, 1, 'imul intel test 106 - ' . conv_intel_instr_to_att ('imul zzz, 2, [eax]') );
is ( conv_intel_instr_to_att ('imul [zzz], 2, [eax]') =~
	/^\s*imul\s\(%eax\)\s*,\s*\$2,\s*\[zzz\]\s*\s*$/io, 1, 'imul intel test 107 - ' . conv_intel_instr_to_att ('imul [zzz], 2, [eax]') );

is ( conv_intel_instr_to_att ('imul [ecx], [eax], bl') =~
	/^\s*imulb\s*%bl\s*,\s*\(%eax\)\s*,\s*\[%ecx\]\s*$/io, 1, 'imul intel test 108 - ' . conv_intel_instr_to_att ('imul [ecx], [eax], bl') );
is ( conv_intel_instr_to_att ('imul [ecx], [eax], bx') =~
	/^\s*imulw\s*%bx\s*,\s*\(%eax\)\s*,\s*\[%ecx\]\s*$/io, 1, 'imul intel test 109 - ' . conv_intel_instr_to_att ('imul [ecx], [eax], bx') );
is ( conv_intel_instr_to_att ('imul [ecx], [eax], ebx') =~
	/^\s*imull\s*%ebx\s*,\s*\(%eax\)\s*,\s*\[%ecx\]\s*$/io, 1, 'imul intel test 110 - ' . conv_intel_instr_to_att ('imul [ecx], [eax], ebx') );
is ( conv_intel_instr_to_att ('imul [ecx], [eax], rbx') =~
	/^\s*imulq\s*%rbx\s*,\s*\(%eax\)\s*,\s*\[%ecx\]\s*$/io, 1, 'imul intel test 111 - ' . conv_intel_instr_to_att ('imul [ecx], [eax], rbx') );
is ( conv_intel_instr_to_att ('imul [ecx], [eax], zzz') =~
	/^\s*imul\s*\$zzz\s*,\s*\(%eax\)\s*,\s*\[%ecx\]\s*$/io, 1, 'imul intel test 112 - ' . conv_intel_instr_to_att ('imul [ecx], [eax], zzz') );
is ( conv_intel_instr_to_att ('imul [ecx], [eax], [rbx]') =~
	/^\s*imul\s*\(%rbx\)\s*,\s*\[%eax\]\s*,\s*\[%ecx\]\s*$/io, 1, 'imul intel test 113 - ' . conv_intel_instr_to_att ('imul [ecx], [eax], [rbx]') );

#is ( conv_intel_instr_to_att ('imul eax, rbx, \[2') =~
#	/^\s*imull\s*\$2\s*,\s*%rbx\s*,\s*%eax\s*$/io, 1, 'imul intel test 1 - ' . conv_intel_instr_to_att ('imul eax, rbx, \[2') );

is ( conv_intel_instr_to_att ('sub ebx, eax') =~
	/^\s*subl\s*%eax\s*,\s*%ebx\s*$/io, 1, 'sub intel test 1');
is ( conv_intel_instr_to_att ('sub ebx, 2') =~
	/^\s*subl\s*\$2\s*,\s*%ebx\s*$/io, 1, 'sub intel test 2');
is ( conv_intel_instr_to_att ('sub ebx, rax') =~
	/^\s*subq\s*%rax\s*,\s*%ebx\s*$/io, 1, 'sub intel test 3');
is ( conv_intel_instr_to_att ('sub ebx, bl') =~
	/^\s*subb\s*%bl\s*,\s*%ebx\s*$/io, 1, 'sub intel test 4');
is ( conv_intel_instr_to_att ('sub ebx, ax') =~
	/^\s*subw\s*%ax\s*,\s*%ebx\s*$/io, 1, 'sub intel test 5');
is ( conv_intel_instr_to_att ('sub ebx, zzz') =~
	/^\s*subl\s*\$zzz\s*,\s*%ebx\s*$/io, 1, 'sub intel test 6');

is ( conv_intel_instr_to_att ('sub bl, eax') =~
	/^\s*subl\s*%eax\s*,\s*%bl\s*$/io, 1, 'sub intel test 7');
is ( conv_intel_instr_to_att ('sub bx, eax') =~
	/^\s*subl\s*%eax\s*,\s*%bx\s*$/io, 1, 'sub intel test 8');
is ( conv_intel_instr_to_att ('sub rbx, eax') =~
	/^\s*subl\s*%eax\s*,\s*%rbx\s*$/io, 1, 'sub intel test 9');

is ( conv_intel_instr_to_att ('sub bl, [eax]') =~
	/^\s*subb\s*\(%eax\)\s*,\s*%bl\s*$/io, 1, 'sub intel test 10');
is ( conv_intel_instr_to_att ('sub bx, [eax]') =~
	/^\s*subw\s*\(%eax\)\s*,\s*%bx\s*$/io, 1, 'sub intel test 11');
is ( conv_intel_instr_to_att ('sub ebx, [eax]') =~
	/^\s*subl\s*\(%eax\)\s*,\s*%ebx\s*$/io, 1, 'sub intel test 12');
is ( conv_intel_instr_to_att ('sub rbx, [eax]') =~
	/^\s*subq\s*\(%eax\)\s*,\s*%rbx\s*$/io, 1, 'sub intel test 13');
is ( conv_intel_instr_to_att ('sub 2, [ebx]') =~
	/^\s*sub\s*\(%ebx\)\s*,\s*\$2\s*$/io, 1, 'sub intel test 14');

is ( conv_intel_instr_to_att ('sub [ebx], [eax]') =~
	/^\s*sub\s*\(%eax\)\s*,\s*\[%ebx\]\s*$/io, 1, 'sub intel test 15');

is ( conv_intel_instr_to_att ('sub [ebx], al') =~
	/^\s*subb\s*%al\s*,\s*\(%ebx\)\s*$/io, 1, 'sub intel test 16');
is ( conv_intel_instr_to_att ('sub [ebx], ax') =~
	/^\s*subw\s*%ax\s*,\s*\(%ebx\)\s*$/io, 1, 'sub intel test 17');
is ( conv_intel_instr_to_att ('sub [ebx], eax') =~
	/^\s*subl\s*%eax\s*,\s*\(%ebx\)\s*$/io, 1, 'sub intel test 18');
is ( conv_intel_instr_to_att ('sub [ebx], rax') =~
	/^\s*subq\s*%rax\s*,\s*\(%ebx\)\s*$/io, 1, 'sub intel test 19');
is ( conv_intel_instr_to_att ('sub [ebx], 2') =~
	/^\s*sub\s*\$2\s*,\s*\(%ebx\)\s*$/io, 1, 'sub intel test 20 - ' . conv_intel_instr_to_att ('sub [ebx], 2'));

is ( conv_intel_instr_to_att ('sub bl, zzz') =~
	/^\s*subb\s*\$zzz\s*,\s*%bl\s*$/io, 1, 'sub intel test 21');
is ( conv_intel_instr_to_att ('sub bx, zzz') =~
	/^\s*subw\s*\$zzz\s*,\s*%bx\s*$/io, 1, 'sub intel test 22');
is ( conv_intel_instr_to_att ('sub ebx, zzz') =~
	/^\s*subl\s*\$zzz\s*,\s*%ebx\s*$/io, 1, 'sub intel test 23');
is ( conv_intel_instr_to_att ('sub rbx, zzz') =~
	/^\s*subq\s*\$zzz\s*,\s*%rbx\s*$/io, 1, 'sub intel test 24');
is ( conv_intel_instr_to_att ('sub yyy, zzz') =~
	/^\s*sub\s*\$zzz\s*,\s*\$yyy\s*$/io, 1, 'sub intel test 25');

is ( conv_intel_instr_to_att ('sub 2, ebx') =~
	/^\s*subl\s*%ebx\s*,\s*\$2\s*$/io, 1, 'sub intel test 26');

is ( conv_intel_instr_to_att ('not ebx') =~
	/^\s*notl\s*%ebx\s*$/io, 1, 'not intel test 1');
is ( conv_intel_instr_to_att ('not zzz') =~
	/^\s*not\s*\$zzz\s*$/io, 1, 'not intel test 2 - ' . conv_intel_instr_to_att ('not zzz'));
is ( conv_intel_instr_to_att ('not [ebx]') =~
	/^\s*not\s*\(%ebx\)\s*$/io, 1, 'not intel test 3');

is ( conv_intel_instr_to_att ('movzx ebx, byte [eax]') =~
	/^\s*movzbl\s*\(%eax\)\s*,\s*%ebx\s*$/io, 1, 'movzx intel test 1 - ' . conv_intel_instr_to_att ('movzx ebx, byte [eax]'));
is ( conv_intel_instr_to_att ('movsx ebx, cl') =~
	/^\s*movsbl\s*%cl\s*,\s*%ebx\s*$/io, 1, 'movzx intel test 2 - ' . conv_intel_instr_to_att ('movsx ebx, cl'));
is ( conv_intel_instr_to_att ('movzx bx, byte [eax]') =~
	/^\s*movzbw\s*\(%eax\)\s*,\s*%bx\s*$/io, 1, 'movzx intel test 3 - ' . conv_intel_instr_to_att ('movzx bx, byte [eax]'));
is ( conv_intel_instr_to_att ('movsx bx, cl') =~
	/^\s*movsbw\s*%cl\s*,\s*%bx\s*$/io, 1, 'movzx intel test 4 - ' . conv_intel_instr_to_att ('movsx bx, cl'));
is ( conv_intel_instr_to_att ('movzx ebx, word [eax]') =~
	/^\s*movzwl\s*\(%eax\)\s*,\s*%ebx\s*$/io, 1, 'movzx intel test 5 - ' . conv_intel_instr_to_att ('movzx ebx, word [eax]'));
is ( conv_intel_instr_to_att ('movsx ebx, cx') =~
	/^\s*movswl\s*%cx\s*,\s*%ebx\s*$/io, 1, 'movzx intel test 6 - ' . conv_intel_instr_to_att ('movsx ebx, cx'));
is ( conv_intel_instr_to_att ('movzx rbx, byte [eax]') =~
	/^\s*movzbq\s*\(%eax\)\s*,\s*%rbx\s*$/io, 1, 'movzx intel test 7 - ' . conv_intel_instr_to_att ('movzx rbx, byte [eax]'));
is ( conv_intel_instr_to_att ('movsx rbx, cl') =~
	/^\s*movsbq\s*%cl\s*,\s*%rbx\s*$/io, 1, 'movzx intel test 8 - ' . conv_intel_instr_to_att ('movsx rbx, cl'));
is ( conv_intel_instr_to_att ('movzx rbx, word [eax]') =~
	/^\s*movzwq\s*\(%eax\)\s*,\s*%rbx\s*$/io, 1, 'movzx intel test 9 - ' . conv_intel_instr_to_att ('movzx rbx, word [eax]'));
is ( conv_intel_instr_to_att ('movsx rbx, cx') =~
	/^\s*movswq\s*%cx\s*,\s*%rbx\s*$/io, 1, 'movzx intel test 10 - ' . conv_intel_instr_to_att ('movsx rbx, cx'));
# undecideable result:
is ( conv_intel_instr_to_att ('movzx ebx, [zz]') =~
	/^\s*movzx\s*zz\(,1\)\s*,\s*%ebx\s*$/io, 1, 'movzx intel test 11 - ' . conv_intel_instr_to_att ('movzx ebx, [zz]'));
is ( conv_intel_instr_to_att ('movzx cl, al') =~
	/^\s*movzx\s*%al\s*,\s*%cl\s*$/io, 1, 'movzx intel test 12 - ' . conv_intel_instr_to_att ('movzx cl, al'));
is ( conv_intel_instr_to_att ('movzx cl, byte [eax]') =~
	/^\s*movzx\s*\(%eax\)\s*,\s*%cl\s*$/io, 1, 'movzx intel test 13 - ' . conv_intel_instr_to_att ('movzx cl, byte [eax]'));
is ( conv_intel_instr_to_att ('movzx cx, ax') =~
	/^\s*movzx\s*%ax\s*,\s*%cx\s*$/io, 1, 'movzx intel test 14 - ' . conv_intel_instr_to_att ('movzx cx, ax'));
is ( conv_intel_instr_to_att ('movzx cx, word [eax]') =~
	/^\s*movzx\s*\(%eax\)\s*,\s*%cx\s*$/io, 1, 'movzx intel test 15 - ' . conv_intel_instr_to_att ('movzx cx, word [eax]'));
is ( conv_intel_instr_to_att ('movzx ecx, eax') =~
	/^\s*movzx\s*%eax\s*,\s*%ecx\s*$/io, 1, 'movzx intel test 16 - ' . conv_intel_instr_to_att ('movzx ecx, eax'));
is ( conv_intel_instr_to_att ('movzx ecx, dword [eax]') =~
	/^\s*movzx\s*\(%eax\)\s*,\s*%ecx\s*$/io, 1, 'movzx intel test 17 - ' . conv_intel_instr_to_att ('movzx ecx, dword [eax]'));
is ( conv_intel_instr_to_att ('movzx rcx, eax') =~
	/^\s*movzx\s*%eax\s*,\s*%rcx\s*$/io, 1, 'movzx intel test 18 - ' . conv_intel_instr_to_att ('movzx rcx, eax'));
is ( conv_intel_instr_to_att ('movzx rcx, dword [eax]') =~
	/^\s*movzx\s*\(%eax\)\s*,\s*%rcx\s*$/io, 1, 'movzx intel test 19 - ' . conv_intel_instr_to_att ('movzx rcx, dword [eax]'));
is ( conv_intel_instr_to_att ('movzx rcx, rax') =~
	/^\s*movzx\s*%rax\s*,\s*%rcx\s*$/io, 1, 'movzx intel test 20 - ' . conv_intel_instr_to_att ('movzx rcx, rax'));
is ( conv_intel_instr_to_att ('movzx rcx, qword [eax]') =~
	/^\s*movzx\s*\(%eax\)\s*,\s*%rcx\s*$/io, 1, 'movzx intel test 21 - ' . conv_intel_instr_to_att ('movzx rcx, qword [eax]'));

is ( conv_intel_instr_to_att ('zzz rcx, eax, bl') =~
	/^\s*zzz\s*%rcx\s*,\s*%eax\s*,\s*%bl\s*$/io, 1, 'movzx intel test 22 - ' . conv_intel_instr_to_att ('zzz rcx, eax, bl'));
is ( conv_intel_instr_to_att ('zzz rcx, eax') =~
	/^\s*zzz\s*%rcx\s*,\s*%eax\s*$/io, 1, 'movzx intel test 23 - ' . conv_intel_instr_to_att ('zzz rcx, eax'));
is ( conv_intel_instr_to_att ('zzz rcx') =~
	/^\s*zzz\s*%rcx\s*/io, 1, 'movzx intel test 24 - ' . conv_intel_instr_to_att ('zzz rcx'));
is ( conv_intel_instr_to_att ('jmp [zzz]') =~
	/^\s*jmp\s*\*zzz\s*/io, 1, 'movzx intel test 25 - ' . conv_intel_instr_to_att ('jmp [zzz]'));
is ( conv_intel_instr_to_att ('call [zzz]') =~
	/^\s*call\s*\*zzz\s*/io, 1, 'movzx intel test 26 - ' . conv_intel_instr_to_att ('call [zzz]'));

is ( conv_intel_addr_to_att ('[ebx]') =~
	/^\s*\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 1' );
is ( conv_intel_addr_to_att ('[ebx-9]') =~
	/^\s*\(\+*-9\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 2' );

is ( conv_intel_addr_to_att ('[ebx + eax]') =~
	/^\s*\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 3' );
is ( conv_intel_addr_to_att ('[ebx + 2]') =~
	/^\s*\(\+*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 4' );
is ( conv_intel_addr_to_att ('[2 + ebx]') =~
	/^\s*\(\+*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 5' );

is ( conv_intel_addr_to_att ('[ebx + eax + 1]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 6' );
is ( conv_intel_addr_to_att ('[ebx + 1 + eax]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 7' );
is ( conv_intel_addr_to_att ('[1 + ebx + eax]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 8' );

is ( conv_intel_addr_to_att ('[3 + eax + 1]') =~
	/^\s*\(\+*1\++3\)\(\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 9' );
is ( conv_intel_addr_to_att ('[3 + 1 + eax]') =~
	/^\s*\(\+*3\++1\)\(\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 10' );
is ( conv_intel_addr_to_att ('[eax + 1 + 3]') =~
	/^\s*\(\+*3\++1\)\(\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 11' );

is ( conv_intel_addr_to_att ('[ebx + eax * 2]') =~
	/^\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 12' );
is ( conv_intel_addr_to_att ('[ebx + 2 * eax]') =~
	/^\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 13' );
is ( conv_intel_addr_to_att ('[eax * 2 + ebx]') =~
	/^\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 14' );
is ( conv_intel_addr_to_att ('[2 * eax + ebx]') =~
	/^\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 15' );

is ( conv_intel_addr_to_att ('[3 + eax * 2]') =~
	/^\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 16' );
is ( conv_intel_addr_to_att ('[3 + 2 * eax]') =~
	/^\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 17' );
is ( conv_intel_addr_to_att ('[eax * 2 + 3]') =~
	/^\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 18' );
is ( conv_intel_addr_to_att ('[2 * eax + 3]') =~
	/^\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 19' );

is ( conv_intel_addr_to_att ('[ebx + 3 * 2]') =~
	/^\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 20' );
is ( conv_intel_addr_to_att ('[ebx + 2 * 3]') =~
	/^\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 21' );
is ( conv_intel_addr_to_att ('[3 * 2 + ebx]') =~
	/^\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 22' );
is ( conv_intel_addr_to_att ('[2 * 3 + ebx]') =~
	/^\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 23' );

is ( conv_intel_addr_to_att ('[ebx + eax * 2 + 1]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 24' );
is ( conv_intel_addr_to_att ('[ebx + 2 * eax + 1]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 25' );
is ( conv_intel_addr_to_att ('[eax * 2 + ebx + 1]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 26' );
is ( conv_intel_addr_to_att ('[2 * eax + ebx + 1]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 27' );
is ( conv_intel_addr_to_att ('[ebx + 1 + eax * 2]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 28' );
is ( conv_intel_addr_to_att ('[ebx + 1 + 2 * eax]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 29' );
is ( conv_intel_addr_to_att ('[eax * 2 + 1 + ebx]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 30' );
is ( conv_intel_addr_to_att ('[2 * eax + 1 + ebx]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 31' );
is ( conv_intel_addr_to_att ('[1 + ebx + eax * 2]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 32' );
is ( conv_intel_addr_to_att ('[1 + ebx + 2 * eax]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 33' );
is ( conv_intel_addr_to_att ('[1 + eax * 2 + ebx]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 34' );
is ( conv_intel_addr_to_att ('[1 + 2 * eax + ebx]') =~
	/^\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 35' );

is ( conv_intel_addr_to_att ('[3 + eax * 2 + 1]') =~
	/^\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 36 - ' . conv_intel_addr_to_att ('[3 + eax * 2 + 1]'));
is ( conv_intel_addr_to_att ('[3 + 2 * eax + 1]') =~
	/^\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 37' );
is ( conv_intel_addr_to_att ('[eax * 2 + 3 + 1]') =~
	/^\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 38 - ' . conv_intel_addr_to_att ('[eax * 2 + 3 + 1]') );
is ( conv_intel_addr_to_att ('[2 * eax + 3 + 1]') =~
	/^\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 39' );
is ( conv_intel_addr_to_att ('[3 + 1 + eax * 2]') =~
	/^\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 40' );
is ( conv_intel_addr_to_att ('[3 + 1 + 2 * eax]') =~
	/^\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 41' );
is ( conv_intel_addr_to_att ('[eax * 2 + 1 + 3]') =~
	/^\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 42' );
is ( conv_intel_addr_to_att ('[2 * eax + 1 + 3]') =~
	/^\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 43' );
is ( conv_intel_addr_to_att ('[1 + 3 + eax * 2]') =~
	/^\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 44' );
is ( conv_intel_addr_to_att ('[1 + 3 + 2 * eax]') =~
	/^\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 45' );
is ( conv_intel_addr_to_att ('[1 + eax * 2 + 3]') =~
	/^\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 46' );
is ( conv_intel_addr_to_att ('[1 + 2 * eax + 3]') =~
	/^\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 47' );

is ( conv_intel_addr_to_att ('[ebx + 3 * 2]') =~
	/^\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 48' );
is ( conv_intel_addr_to_att ('[ebx + 2 * 3]') =~
	/^\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 49' );
is ( conv_intel_addr_to_att ('[3 * 2 + ebx]') =~
	/^\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 50' );
is ( conv_intel_addr_to_att ('[2 * 3 + ebx]') =~
	/^\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 51' );

is ( conv_intel_addr_to_att ('[ebx + 3 * 2 + 1]') =~
	/^\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 52' );
is ( conv_intel_addr_to_att ('[ebx + 2 * 3 + 1]') =~
	/^\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 53' );
is ( conv_intel_addr_to_att ('[3 * 2 + ebx + 1]') =~
	/^\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 54' );
is ( conv_intel_addr_to_att ('[2 * 3 + ebx + 1]') =~
	/^\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 55' );
is ( conv_intel_addr_to_att ('[ebx + 1 + 3 * 2]') =~
	/^\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 56' );
is ( conv_intel_addr_to_att ('[ebx + 1 + 2 * 3]') =~
	/^\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 57' );
is ( conv_intel_addr_to_att ('[3 * 2 + 1 + ebx]') =~
	/^\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 58' );
is ( conv_intel_addr_to_att ('[2 * 3 + 1 + ebx]') =~
	/^\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 59' );
is ( conv_intel_addr_to_att ('[1 + ebx + 3 * 2]') =~
	/^\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 60' );
is ( conv_intel_addr_to_att ('[1 + ebx + 2 * 3]') =~
	/^\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 61' );
is ( conv_intel_addr_to_att ('[1 + 3 * 2 + ebx]') =~
	/^\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 62' );
is ( conv_intel_addr_to_att ('[1 + 2 * 3 + ebx]') =~
	/^\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 63' );

is ( conv_intel_addr_to_att ('[ebx + 3 * 2 + ecx]') =~
	/^\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 64' );
is ( conv_intel_addr_to_att ('[ebx + 2 * 3 + ecx]') =~
	/^\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 65' );
is ( conv_intel_addr_to_att ('[3 * 2 + ebx + ecx]') =~
	/^\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 66' );
is ( conv_intel_addr_to_att ('[2 * 3 + ebx + ecx]') =~
	/^\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 67' );
is ( conv_intel_addr_to_att ('[ebx + ecx + 3 * 2]') =~
	/^\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 68' );
is ( conv_intel_addr_to_att ('[ebx + ecx + 2 * 3]') =~
	/^\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 69' );
is ( conv_intel_addr_to_att ('[3 * 2 + ecx + ebx]') =~
	/^\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 70' );
is ( conv_intel_addr_to_att ('[2 * 3 + ecx + ebx]') =~
	/^\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 71' );
is ( conv_intel_addr_to_att ('[ecx + ebx + 3 * 2]') =~
	/^\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 72' );
is ( conv_intel_addr_to_att ('[ecx + ebx + 2 * 3]') =~
	/^\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 73' );
is ( conv_intel_addr_to_att ('[ecx + 3 * 2 + ebx]') =~
	/^\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 74' );
is ( conv_intel_addr_to_att ('[ecx + 2 * 3 + ebx]') =~
	/^\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 75' );

is ( conv_intel_addr_to_att ('ds:[ebx]') =~
	/^\s*%ds:\s*\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 76 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx-9]') =~
	/^\s*%ds:\s*\(\+*-9\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 77 ds:[]' );

is ( conv_intel_addr_to_att ('ds:[ebx + eax]') =~
	/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 78 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + 2]') =~
	/^\s*%ds:\s*\(\+*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 79 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[2 + ebx]') =~
	/^\s*%ds:\s*\(\+*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 80 ds:[]' );

is ( conv_intel_addr_to_att ('ds:[ebx + eax + 1]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 81 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + 1 + eax]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 82 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[1 + ebx + eax]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 83 ds:[]' );

is ( conv_intel_addr_to_att ('ds:[3 + eax + 1]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 84 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[3 + 1 + eax]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 85 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[eax + 1 + 3]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 86 ds:[]' );

is ( conv_intel_addr_to_att ('ds:[ebx + eax * 2]') =~
	/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 87 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + 2 * eax]') =~
	/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 88 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[eax * 2 + ebx]') =~
	/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 89 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[2 * eax + ebx]') =~
	/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 90 ds:[]' );

is ( conv_intel_addr_to_att ('ds:[3 + eax * 2]') =~
	/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 91 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[3 + 2 * eax]') =~
	/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 92 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[eax * 2 + 3]') =~
	/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 93 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[2 * eax + 3]') =~
	/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 94 ds:[]' );

is ( conv_intel_addr_to_att ('ds:[ebx + 3 * 2]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 95 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 96 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[3 * 2 + ebx]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 97 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[2 * 3 + ebx]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 98 ds:[]' );

is ( conv_intel_addr_to_att ('ds:[ebx + eax * 2 + 1]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 99 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + 2 * eax + 1]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 100 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[eax * 2 + ebx + 1]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 101 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[2 * eax + ebx + 1]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 102 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + 1 + eax * 2]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 103 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + 1 + 2 * eax]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 104 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[eax * 2 + 1 + ebx]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 105 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[2 * eax + 1 + ebx]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 106 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[1 + ebx + eax * 2]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 107 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[1 + ebx + 2 * eax]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 108 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[1 + eax * 2 + ebx]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 109 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[1 + 2 * eax + ebx]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 110 ds:[]' );

is ( conv_intel_addr_to_att ('ds:[3 + eax * 2 + 1]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 111 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[3 + 2 * eax + 1]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 112 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[eax * 2 + 3 + 1]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 113 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[2 * eax + 3 + 1]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 114 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[3 + 1 + eax * 2]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 115 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[3 + 1 + 2 * eax]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 116 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[eax * 2 + 1 + 3]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 117 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[2 * eax + 1 + 3]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 118 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[1 + 3 + eax * 2]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 119 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[1 + 3 + 2 * eax]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 120 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[1 + eax * 2 + 3]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 121 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[1 + 2 * eax + 3]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 122 ds:[]' );

is ( conv_intel_addr_to_att ('ds:[ebx + 3 * 2]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 123 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 124 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[3 * 2 + ebx]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 125 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[2 * 3 + ebx]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 126 ds:[]' );

is ( conv_intel_addr_to_att ('ds:[ebx + 3 * 2 + 1]') =~
	/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 127 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + 2 * 3 + 1]') =~
	/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 128 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[3 * 2 + ebx + 1]') =~
	/^\s*%ds:\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 129 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[2 * 3 + ebx + 1]') =~
	/^\s*%ds:\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 130 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + 1 + 3 * 2]') =~
	/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 131 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + 1 + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 132 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[3 * 2 + 1 + ebx]') =~
	/^\s*%ds:\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 133 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[2 * 3 + 1 + ebx]') =~
	/^\s*%ds:\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 134 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[1 + ebx + 3 * 2]') =~
	/^\s*%ds:\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 135 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[1 + ebx + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 136 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[1 + 3 * 2 + ebx]') =~
	/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 137 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[1 + 2 * 3 + ebx]') =~
	/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 138 ds:[]' );

is ( conv_intel_addr_to_att ('ds:[ebx + 3 * 2 + ecx]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 139 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + 2 * 3 + ecx]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 140 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[3 * 2 + ebx + ecx]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 141 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[2 * 3 + ebx + ecx]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 142 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + ecx + 3 * 2]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 143 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ebx + ecx + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 144 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[3 * 2 + ecx + ebx]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 145 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[2 * 3 + ecx + ebx]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 146 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ecx + ebx + 3 * 2]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 147 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ecx + ebx + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 148 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ecx + 3 * 2 + ebx]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 149 ds:[]' );
is ( conv_intel_addr_to_att ('ds:[ecx + 2 * 3 + ebx]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 150 ds:[]' );

is ( conv_intel_addr_to_att ('[ds:ebx]') =~
	/^\s*%ds:\s*\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 151 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx-9]') =~
	/^\s*%ds:\s*\(\+*-9\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 152 [ds:]' );

is ( conv_intel_addr_to_att ('[ds:ebx + eax]') =~
	/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*(,\s*)?\)\s*$/io, 1, 'Intel->AT&T mem test 153 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + 2]') =~
	/^\s*%ds:\s*\(\+*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 154 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:2 + ebx]') =~
	/^\s*%ds:\s*\(\+*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 155 [ds:]' );

is ( conv_intel_addr_to_att ('[ds:ebx + eax + 1]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*(,\s*)?\)\s*$/io, 1, 'Intel->AT&T mem test 156 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + 1 + eax]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*(,\s*)?\)\s*$/io, 1, 'Intel->AT&T mem test 157 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:1 + ebx + eax]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%eax\s*,\s*%ebx\s*(,\s*)?\)\s*$/io, 1, 'Intel->AT&T mem test 158 [ds:]' );

is ( conv_intel_addr_to_att ('[ds:3 + eax + 1]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 159 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:3 + 1 + eax]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 160 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:eax + 1 + 3]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(\s*%eax\s*\)\s*$/io, 1, 'Intel->AT&T mem test 161 [ds:]' );

is ( conv_intel_addr_to_att ('[ds:ebx + eax * 2]') =~
	/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 162 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + 2 * eax]') =~
	/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 163 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:eax * 2 + ebx]') =~
	/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 164 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:2 * eax + ebx]') =~
	/^\s*%ds:\s*\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 165 [ds:]' );

is ( conv_intel_addr_to_att ('[ds:3 + eax * 2]') =~
	/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 166 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:3 + 2 * eax]') =~
	/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 167 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:eax * 2 + 3]') =~
	/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 168 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:2 * eax + 3]') =~
	/^\s*%ds:\s*\(\+*3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 169 [ds:]' );

is ( conv_intel_addr_to_att ('[ds:ebx + 3 * 2]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 170 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 171 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:3 * 2 + ebx]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 172 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:2 * 3 + ebx]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 173 [ds:]' );

is ( conv_intel_addr_to_att ('[ds:ebx + eax * 2 + 1]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 174 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + 2 * eax + 1]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 175 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:eax * 2 + ebx + 1]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 176 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:2 * eax + ebx + 1]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 177 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + 1 + eax * 2]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 178 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + 1 + 2 * eax]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 179 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:eax * 2 + 1 + ebx]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 180 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:2 * eax + 1 + ebx]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 181 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:1 + ebx + eax * 2]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 182 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:1 + ebx + 2 * eax]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 183 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:1 + eax * 2 + ebx]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 184 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:1 + 2 * eax + ebx]') =~
	/^\s*%ds:\s*\(\+*1\)\(\s*%ebx\s*,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 185 [ds:]' );

is ( conv_intel_addr_to_att ('[ds:3 + eax * 2 + 1]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 186 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:3 + 2 * eax + 1]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 187 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:eax * 2 + 3 + 1]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 188 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:2 * eax + 3 + 1]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 189 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:3 + 1 + eax * 2]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 190 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:3 + 1 + 2 * eax]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 191 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:eax * 2 + 1 + 3]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 192 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:2 * eax + 1 + 3]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 193 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:1 + 3 + eax * 2]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 194 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:1 + 3 + 2 * eax]') =~
	/^\s*%ds:\s*\(\+*1\++3\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 195 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:1 + eax * 2 + 3]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 196 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:1 + 2 * eax + 3]') =~
	/^\s*%ds:\s*\(\+*3\++1\)\(,\s*%eax\s*,\s*2\s*\)\s*$/io, 1, 'Intel->AT&T mem test 197 [ds:]' );

is ( conv_intel_addr_to_att ('[ds:ebx + 3 * 2]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 198 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 199 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:3 * 2 + ebx]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 200 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:2 * 3 + ebx]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 201 [ds:]' );

is ( conv_intel_addr_to_att ('[ds:ebx + 3 * 2 + 1]') =~
	/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 202 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + 2 * 3 + 1]') =~
	/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 203 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:3 * 2 + ebx + 1]') =~
	/^\s*%ds:\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 204 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:2 * 3 + ebx + 1]') =~
	/^\s*%ds:\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 205 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + 1 + 3 * 2]') =~
	/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 206 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + 1 + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 207 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:3 * 2 + 1 + ebx]') =~
	/^\s*%ds:\s*\(\+*3\*2\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 208 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:2 * 3 + 1 + ebx]') =~
	/^\s*%ds:\s*\(\+*2\*3\++1\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 209 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:1 + ebx + 3 * 2]') =~
	/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 210 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:1 + ebx + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 211 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:1 + 3 * 2 + ebx]') =~
	/^\s*%ds:\s*\(\+*1\++3\*2\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 212 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:1 + 2 * 3 + ebx]') =~
	/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 213 [ds:]' );

is ( conv_intel_addr_to_att ('[ds:ebx + 3 * 2 + ecx]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 214 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + 2 * 3 + ecx]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 215 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:3 * 2 + ebx + ecx]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 216 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:2 * 3 + ebx + ecx]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 217 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + ecx + 3 * 2]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 218 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ebx + ecx + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ebx\s*,\s*%ecx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 219 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:3 * 2 + ecx + ebx]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 220 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:2 * 3 + ecx + ebx]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 221 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ecx + ebx + 3 * 2]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 222 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ecx + ebx + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 223 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ecx + 3 * 2 + ebx]') =~
	/^\s*%ds:\s*\(\+*3\*2\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 224 [ds:]' );
is ( conv_intel_addr_to_att ('[ds:ecx + 2 * 3 + ebx]') =~
	/^\s*%ds:\s*\(\+*2\*3\)\(\s*%ecx\s*,\s*%ebx\s*\)\s*$/io, 1, 'Intel->AT&T mem test 225 [ds:]' );

is ( conv_intel_addr_to_att ('[ds:1 + 2 * 3 + 4]') =~
	/^\s*%ds:\s*\(\+*1\++2\*3\++4\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 226 [ds:] - ' . conv_intel_addr_to_att ('[ds:1 + 2 * 3 + 4]') );
is ( conv_intel_addr_to_att ('[ds:1 + 4 + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*1\++4\++2\*3\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 227 [ds:] - ' . conv_intel_addr_to_att ('[ds:1 + 4 + 2 * 3]') );
is ( conv_intel_addr_to_att ('[ds:2 * 3 + 1 + 4]') =~
	/^\s*%ds:\s*\(\+*2\*3\++1\++4\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 228 [ds:] - ' . conv_intel_addr_to_att ('[ds:2 * 3 + 1 + 4]') );
is ( conv_intel_addr_to_att ('[ds:1 + 2 * 3]') =~
	/^\s*%ds:\s*\(\+*1\++2\*3\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 229 [ds:] - ' . conv_intel_addr_to_att ('[ds:1 + 2 * 3]') );
is ( conv_intel_addr_to_att ('[ds:2 * 3 + 1]') =~
	/^\s*%ds:\s*\(\+*2\*3\++1\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 230 [ds:] - ' . conv_intel_addr_to_att ('[ds:2 * 3 + 1]') );
is ( conv_intel_addr_to_att ('[ds:1 + 2 + 3]') =~
	/^\s*%ds:\s*\(\+*1\++2\++3\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 231 [ds:] - ' . conv_intel_addr_to_att ('[ds:1 + 2 + 3]') );
is ( conv_intel_addr_to_att ('[ds:1 + 2]') =~
	/^\s*%ds:\s*\(\+*1\++2\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 232 [ds:] - ' . conv_intel_addr_to_att ('[ds:1 + 2]') );
is ( conv_intel_addr_to_att ('[ds:1]') =~
	/^\s*%ds:\s*\(?\+*1\)?\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 233 [ds:] - ' . conv_intel_addr_to_att ('[ds:1]') );

is ( conv_intel_addr_to_att ('[1 + 2 * 3 + 4]') =~
	/^\s*\(\+*1\++2\*3\++4\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 234 [] - ' . conv_intel_addr_to_att ('[1 + 2 * 3 + 4]') );
is ( conv_intel_addr_to_att ('[1 + 4 + 2 * 3]') =~
	/^\s*\(\+*1\++4\++2\*3\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 235 [] - ' . conv_intel_addr_to_att ('[1 + 4 + 2 * 3]') );
is ( conv_intel_addr_to_att ('[2 * 3 + 1 + 4]') =~
	/^\s*\(\+*2\*3\++1\++4\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 236 [] - ' . conv_intel_addr_to_att ('[2 * 3 + 1 + 4]') );
is ( conv_intel_addr_to_att ('[1 + 2 * 3]') =~
	/^\s*\(\+*1\++2\*3\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 237 [] - ' . conv_intel_addr_to_att ('[1 + 2 * 3]') );
is ( conv_intel_addr_to_att ('[2 * 3 + 1]') =~
	/^\s*\(\+*2\*3\++1\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 238 [] - ' . conv_intel_addr_to_att ('[2 * 3 + 1]') );
is ( conv_intel_addr_to_att ('[1 + 2 + 3]') =~
	/^\s*\(\+*1\++2\++3\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 239 [] - ' . conv_intel_addr_to_att ('[1 + 2 + 3]') );
is ( conv_intel_addr_to_att ('[1 + 2]') =~
	/^\s*\(\+*1\++2\)\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 239 [] - ' . conv_intel_addr_to_att ('[1 + 2]') );
is ( conv_intel_addr_to_att ('[1]') =~
	/^\s*\(?\+*1\)?\(\s*,1\s*\)\s*$/io, 1, 'Intel->AT&T mem test 240 [] - ' . conv_intel_addr_to_att ('[1]') );

is ( conv_att_instr_to_intel ('addl	%eax, %ebx') =~
	/^\s*add\s*(dword)?\s*ebx,\s*eax\s*$/io, 1, 'add test' );
is ( conv_att_instr_to_intel ('jmp	name') =~
	/^\s*jmp\s*(dword)?\s*name\s*$/io, 1, 'jmp test' );
is ( conv_att_instr_to_intel ('call	name') =~
	/^\s*call\s*(dword)?\s*name\s*$/io, 1, 'call test' );

is ( conv_att_instr_to_intel ('subb	(%esi), %bl') =~
	/^\s*sub\s*(byte)?\s*bl\s*,\s*\[esi\]\s*$/io, 1, 'sub test 1' );
is ( conv_att_instr_to_intel ('subb	(%esi), 2') =~
	/^\s*sub\s*(byte)?\s*2\s*,\s*\[esi\]\s*$/io, 1, 'sub test 2' );
is ( conv_att_instr_to_intel ('subb	(%esi), $2') =~
	/^\s*sub\s*(byte)?\s*2\s*,\s*\[esi\]\s*$/io, 1, 'sub test 3' );
is ( conv_att_instr_to_intel ('subb	(%esi), zz') =~
	/^\s*sub\s*(byte)?\s*zz\s*,\s*\[esi\]\s*$/io, 1, 'sub test 4' );
is ( conv_att_instr_to_intel ('subb	(%esi), _L1') =~
	/^\s*sub\s*(byte)?\s*_L1\s*,\s*\[esi\]\s*$/io, 1, 'sub test 5' );
is ( conv_att_instr_to_intel ('subb	%esi, %bl') =~
	/^\s*sub\s*(byte)?\s*bl\s*,\s*esi\s*$/io, 1, 'sub test 6' );
is ( conv_att_instr_to_intel ('subb	%esi, 2') =~
	/^\s*sub\s*(byte)?\s*2\s*,\s*esi\s*$/io, 1, 'sub test 7' );
is ( conv_att_instr_to_intel ('subb	%esi, $2') =~
	/^\s*sub\s*(byte)?\s*2\s*,\s*esi\s*$/io, 1, 'sub test 8' );
is ( conv_att_instr_to_intel ('subb	%esi, zz') =~
	/^\s*sub\s*(byte)?\s*\[zz\]\s*,\s*esi\s*$/io, 1, 'sub test 9' );
is ( conv_att_instr_to_intel ('subb	%esi, _L1') =~
	/^\s*sub\s*(byte)?\s*_L1\s*,\s*esi\s*$/io, 1, 'sub test 10' );
is ( conv_att_instr_to_intel ('subb	2, %bl') =~
	/^\s*sub\s*(byte)?\s*bl\s*,\s*2\s*$/io, 1, 'sub test 11' );
is ( conv_att_instr_to_intel ('subb	$2, %bl') =~
	/^\s*sub\s*(byte)?\s*bl\s*,\s*2\s*$/io, 1, 'sub test 12' );
is ( conv_att_instr_to_intel ('subb	zz, %bl') =~
	/^\s*sub\s*(byte)?\s*bl\s*,\s*\[zz\]\s*$/io, 1, 'sub test 13 - ' .conv_att_instr_to_intel ('subb	zz, %bl'));
is ( conv_att_instr_to_intel ('subb	_L1, %bl') =~
	/^\s*sub\s*(byte)?\s*bl\s*,\s*_L1\s*$/io, 1, 'sub test 14' );

is ( conv_att_instr_to_intel ('notb	%bl') =~
	/^\s*not\s*(byte)?\s*bl\s*$/io, 1, 'not test 1' );
is ( conv_att_instr_to_intel ('notb	2') =~
	/^\s*not\s*(byte)?\s*2\s*$/io, 1, 'not test 2' );
is ( conv_att_instr_to_intel ('notb	$2') =~
	/^\s*not\s*(byte)?\s*2\s*$/io, 1, 'not test 3' );
is ( conv_att_instr_to_intel ('notb	zz') =~
	/^\s*not\s*(byte)?\s*\[zz\]\s*$/io, 1, 'not test 4' );
is ( conv_att_instr_to_intel ('notb	_L1') =~
	/^\s*not\s*(byte)?\s*_L1\s*$/io, 1, 'not test 5' );

is ( conv_att_instr_to_intel ('imul	(%esi), %bl, 2') =~
	/^\s*imul\s*(dword)?\s*2,\s*bl\s*,\s*\[esi\]\s*$/io, 1, 'imul AT&T test 1' );
is ( conv_att_instr_to_intel ('imul	(%esi), %bl, $2') =~
	/^\s*imul\s*(dword)?\s*2,\s*bl\s*,\s*\[esi\]\s*$/io, 1, 'imul AT&T test 2' );
is ( conv_att_instr_to_intel ('imul	(%esi), %bl, zz') =~
	/^\s*imul\s*(dword)?\s*zz,\s*bl\s*,\s*\[esi\]\s*$/io, 1, 'imul AT&T test 3' );
is ( conv_att_instr_to_intel ('imul	(%esi), %bl, _L1') =~
	/^\s*imul\s*(dword)?\s*_L1,\s*bl\s*,\s*\[esi\]\s*$/io, 1, 'imul AT&T test 4' );
is ( conv_att_instr_to_intel ('imul	(%esi), 2, %bl') =~
	/^\s*imul\s*(dword)?\s*bl,\s*2\s*,\s*\[esi\]\s*$/io, 1, 'imul AT&T test 5' );
is ( conv_att_instr_to_intel ('imul	(%esi), $2, %bl') =~
	/^\s*imul\s*(dword)?\s*bl,\s*2\s*,\s*\[esi\]\s*$/io, 1, 'imul AT&T test 6' );
is ( conv_att_instr_to_intel ('imul	(%esi), zz, %bl') =~
	/^\s*imul\s*(dword)?\s*bl,\s*zz\s*,\s*\[esi\]\s*$/io, 1, 'imul AT&T test 7' );
is ( conv_att_instr_to_intel ('imul	(%esi), _L1, %bl') =~
	/^\s*imul\s*(dword)?\s*bl,\s*_L1\s*,\s*\[esi\]\s*$/io, 1, 'imul AT&T test 8' );
is ( conv_att_instr_to_intel ('imul	%esi, %bl, 2') =~
	/^\s*imul\s*(dword)?\s*2,\s*bl\s*,\s*esi\s*$/io, 1, 'imul AT&T test 9' );
is ( conv_att_instr_to_intel ('imul	%esi, %bl, $2') =~
	/^\s*imul\s*(dword)?\s*2,\s*bl\s*,\s*esi\s*$/io, 1, 'imul AT&T test 10' );
is ( conv_att_instr_to_intel ('imul	%esi, %bl, zz') =~
	/^\s*imul\s*(dword)?\s*\[zz\],\s*bl\s*,\s*esi\s*$/io, 1, 'imul AT&T test 11' );
is ( conv_att_instr_to_intel ('imul	%esi, %bl, _L1') =~
	/^\s*imul\s*(dword)?\s*_L1,\s*bl\s*,\s*esi\s*$/io, 1, 'imul AT&T test 12' );
is ( conv_att_instr_to_intel ('imul	%esi, 2, %bl') =~
	/^\s*imul\s*(dword)?\s*bl,\s*2\s*,\s*esi\s*$/io, 1, 'imul AT&T test 13' );
is ( conv_att_instr_to_intel ('imul	%esi, $2, %bl') =~
	/^\s*imul\s*(dword)?\s*bl,\s*2\s*,\s*esi\s*$/io, 1, 'imul AT&T test 14' );
is ( conv_att_instr_to_intel ('imul	%esi, zz, %bl') =~
	/^\s*imul\s*(dword)?\s*bl,\s*\[zz\]\s*,\s*esi\s*$/io, 1, 'imul AT&T test 15' );
is ( conv_att_instr_to_intel ('imul	%esi, _L1, %bl') =~
	/^\s*imul\s*(dword)?\s*bl,\s*_L1\s*,\s*esi\s*$/io, 1, 'imul AT&T test 16' );
is ( conv_att_instr_to_intel ('imul	2, %esi, %bl') =~
	/^\s*imul\s*(dword)?\s*bl,\s*esi\s*,\s*2\s*$/io, 1, 'imul AT&T test 17' );
is ( conv_att_instr_to_intel ('imul	$2, %esi, %bl') =~
	/^\s*imul\s*(dword)?\s*bl,\s*esi\s*,\s*2\s*$/io, 1, 'imul AT&T test 18' );
is ( conv_att_instr_to_intel ('imul	zz, %esi, %bl') =~
	/^\s*imul\s*(dword)?\s*bl,\s*esi\s*,\s*\[zz\]\s*$/io, 1, 'imul AT&T test 19' );
is ( conv_att_instr_to_intel ('imul	_L1, %esi, %bl') =~
	/^\s*imul\s*(dword)?\s*bl,\s*esi\s*,\s*_L1\s*$/io, 1, 'imul AT&T test 20' );

is ( conv_att_instr_to_intel ('zzzz	(%esi), %bl, 2') =~
	/^\s*zzzz\s*(dword)?\s*\[esi\]\s*,\s*bl\s*,\s*2\s*$/io, 1, 'zzzz test with 3 operands mem' );
is ( conv_att_instr_to_intel ('zzzz	(%esi), %bl') =~
	/^\s*zzzz\s*(dword)?\s*\[esi\]\s*,\s*bl\s*$/io, 1, 'zzzz test with 2 operands mem' );
is ( conv_att_instr_to_intel ('zzzz	(%esi)') =~
	/^\s*zzzz\s*(dword)?\s*\[esi\]\s*$/io, 1, 'zzzz test with 1 operand mem' );
is ( conv_att_instr_to_intel ('zzzz	%esi, %bl, 2') =~
	/^\s*zzzz\s*(dword)?\s*esi\s*,\s*bl\s*,\s*2\s*$/io, 1, 'zzzz test with 3 operands' );
is ( conv_att_instr_to_intel ('zzzz	%esi, %bl') =~
	/^\s*zzzz\s*(dword)?\s*esi\s*,\s*bl\s*$/io, 1, 'zzzz test with 2 operands' );
is ( conv_att_instr_to_intel ('zzzz	%esi') =~
	/^\s*zzzz\s*(dword)?\s*esi\s*$/io, 1, 'zzzz test with 1 operand' );

is ( conv_att_instr_to_intel ('fchs st(0)') =~
	/^\s*fchs\s*st\(0\)\s*$/io, 1, 'fchs test' );
is ( conv_att_instr_to_intel ('fmul st(0)') =~
	/^\s*fmul\s*st\(0\)\s*$/io, 1, 'fmul test' );
is ( conv_att_instr_to_intel ('fst st(0)') =~
	/^\s*fst\s*st\(0\)\s*$/io, 1, 'fst test' );

is ( conv_att_addr_to_intel ('-8(%esi,%ebp,4)') =~
	/^\s*\[\s*esi\s*\+\s*ebp\s*\*\s*4\s*\+*-8\s*\]\s*$/io, 1, 'AT&T->Intel mem test 1' );
is ( conv_att_addr_to_intel ('(,%ebp,8)') =~
	/^\s*\[\s*ebp\s*\*\s*8\s*]\s*$/io, 1, 'AT&T->Intel mem test 2' );
is ( conv_att_addr_to_intel ('st(0)') =~
	/^\s*st\(0\)\s*$/io, 1, 'AT&T->Intel mem test 3 - ' . conv_att_addr_to_intel ('st(0)') );

sub arr_contains {

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
