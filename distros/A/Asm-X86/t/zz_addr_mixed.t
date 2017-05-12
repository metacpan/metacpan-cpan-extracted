#!perl -T -w

use strict;
use warnings;

use Test::More tests => 2*((5*4*2 + 34) + (14*2 + 20) + (14*2 + 21) + 24)
	+ 2*((5*4)*3 + 33 + (36*3 + 21)*2 + 3 + 21);
use Asm::X86 qw(
	is_valid_16bit_addr_att is_valid_32bit_addr_att
	is_valid_64bit_addr_att is_valid_addr_att
	is_valid_16bit_addr_intel is_valid_32bit_addr_intel
	is_valid_64bit_addr_intel is_valid_addr_intel
	is_valid_16bit_addr is_valid_32bit_addr
	is_valid_64bit_addr is_valid_addr
	);

# ----------- 16-bit

is ( is_valid_16bit_addr_intel ("(\%bX)"), 0, "(bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%sI)"), 0, "(si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%Di)"), 0, "(di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%Bp)"), 0, "(bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("(\%bx,\%bx)"), 0, "(bx,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%bx,\%Si)"), 0, "(bx,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%bX,\%di)"), 0, "(bx,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%bx,\%bp)"), 0, "(bx,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("(\%sI,\%bx)"), 0, "(si,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%si,\%si)"), 0, "(si,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%si,\%dI)"), 0, "(si,dI) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%si,\%bP)"), 0, "(si,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("(\%di,\%Bx)"), 0, "(di,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%di,\%Si)"), 0, "(di,Si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%di,\%di)"), 0, "(di,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%Di,\%bp)"), 0, "(di,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("(\%bp,\%bX)"), 0, "(bp,bX) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%bP,\%si)"), 0, "(bp,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%bp,\%Di)"), 0, "(bp,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%bp,\%bP)"), 0, "(bp,bP) is a valid 16-bit addressing scheme" );

# -----------

is ( is_valid_16bit_addr_intel ("\%cs:(\%bx)"), 0, "cs:(bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%cs:(\%si)"), 0, "cs:(si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%cs:(\%di)"), 0, "cs:(di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%cs:(\%bp)"), 0, "cs:(bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("\%ds:(\%bx,\%bx)"), 0, "ds:(bx,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%ds:(\%bx,\%si)"), 0, "ds:(bx,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%ds:(\%bx,\%di)"), 0, "ds:(bx,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%ds:(\%bx,\%bp)"), 0, "ds:(bx,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("\%es:(\%si,\%bx)"), 0, "es:(si,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%es:(\%si,\%si)"), 0, "es:(si,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%es:(\%si,\%dI)"), 0, "es:(si,dI) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%es:(\%si,\%bp)"), 0, "es:(si,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("\%fs:(\%di,\%bx)"), 0, "fs:(di,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%fs:(\%di,\%Si)"), 0, "fs:(di,Si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%gs:(\%di,\%di)"), 0, "gs:(di,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%gs:(\%di,\%bp)"), 0, "gs:(di,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("\%ss:(\%bp,\%bX)"), 0, "ss:(bp,bX) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%ss:(\%bp,\%si)"), 0, "ss:(bp,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%ss:(\%bp,\%di)"), 0, "ss:(bp,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%ss:(\%bp,\%bP)"), 0, "ss:(bp,bP) is a valid 16-bit addressing scheme" );


# -----------

is ( is_valid_16bit_addr_intel ("(\%ax)"), 0, "(ax) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%bx,\%cx)"), 0, "(bx,cx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%cx,\%bx)"), 0, "(cx,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%bp,\%al)"), 0, "(bp,al) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%ch,\%si)"), 0, "(ch,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%bx-\%si)"), 0, "(bx-si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("-2(\%bp)"), 0, "-2(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("-varname(\%bp)"), 0, "-varname(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%si-\%ax)"), 0, "(si-ax) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("+-2(\%bp)"), 0, "+-2(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("-si(\%bp)"), 0, "-si(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%ad:(\%bx)"), 0, "ad:(bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%sc:\%di)"), 0, "(sc:di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(2,\%bp)"), 0, "(2,bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("-3(\%si)"), 0, "-3(si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(,,-3,\%si)"), 0, "(,,-3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(3-\%si)"), 0, "(3-si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(--3,\%si)"), 0, "(--3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(-3-\%si)"), 0, "(-3-si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(3,5)"), 0, "(3,5) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(-3)"), 0, "(-3) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(-3,2)"), 0, "(-3,2) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(,2)"), 0, "(,2) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("\%(cs:--3,si)"), 0, "(cs:--3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%cs:(--3,si)"), 0, "cs:(--3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%ds:(,2)"), 0, "ds:(,2) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%ds:,2)"), 0, "(ds:,2) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%ss:(-3)"), 0, "ss:(-3) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%ss:-3,2)"), 0, "(ss:-3,2) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%es:2,bp)"), 0, "(es:2,bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%eS:(2,bp)"), 0, "es:(2,bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("\%fs:(,,-3,si)"), 0, "fs:(,,-3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("(\%fs:,,-3,si)"), 0, "(fs:,,-3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("zzz(,1)"), 0, "zzz(,1) is a valid 16-bit addressing scheme" );

# ----------- 32-bit

is ( is_valid_32bit_addr_intel ('zzz(,1)'), 0, 'zzz(,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%eax)'), 0, '(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('1(%eax)'), 0, '1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('-1(%eax)'), 0, '-1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%eax, %ebx)'), 0, '(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('2(%eax, %ebx)'), 0, '2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('-2(%eax, %ebx)'), 0, '-2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%eax, %ebx, 1)'), 0, '(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('3( %eax, %ebx, 2)'), 0, '3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('-9(%eax, %ebx, 4)'), 0, '-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(, %ebx, 8)'), 0, '(, %ebx, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('7(, %ecx, 4)'), 0, '7(, %ecx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('-7(, %edx, 2)'), 0, '-7(, %edx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('11(,1)'), 0, '11(,1) is a valid 32-bit addressing scheme' );

# -----------

is ( is_valid_32bit_addr_intel ('%cs:zzz(,1)'), 0, '%cs:zzz(,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%ds:(%eax)'), 0, '%ds:(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%es:1(%eax)'), 0, '%es:1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%fs:-1(%eax)'), 0, '-%fs:1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%gs:(%eax, %ebx)'), 0, '%gs:(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%ss:2(%eax, %ebx)'), 0, '%ss:2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%cs:-2(%eax, %ebx)'), 0, '%cs:-2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%ds:(%eax, %ebx, 1)'), 0, '%ds:(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%es:3( %eax, %ebx, 2)'), 0, '%es:3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%fs:-9(%eax, %ebx, 4)'), 0, '%fs:-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%gs:(, %ebx, 8)'), 0, '%gs:(, %ebx, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%ss:7(, %ecx, 4)'), 0, '%ss:7(, %ecx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%cs:-7(, %edx, 2)'), 0, '%cs:-7(, %edx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%ds:11(,1)'), 0, '%ds:11(,1) is a valid 32-bit addressing scheme' );

# -----------

is ( is_valid_32bit_addr_intel ('1(%cr0)'), 0, '1(%cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('1(%eax, %cr0)'), 0, '1(%eax, %cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('2(%cr0, %ebx, 2)'), 0, '2(%cr0, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('-1(%st7)'), 0, '-1(%st7) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('-2(%eax, %dr0)'), 0, '-2(%eax, %dr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%xmm3)'), 0, '(%xmm3) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%mm2)'), 0, '(%mm2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%eax, %xmm5)'), 0, '(%eax, %xmm5) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%ebx, %mm2)'), 0, '(%ebx, %mm2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('%eax(%ebx)'), 0, '%eax(%ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('-%eax(%ebx)'), 0, '-%eax(%ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('3(-%esi)'), 0, '3(-%esi) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%eax, %r12d)'), 0, '(%eax, %r12d) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%ebx, %r12d, 2)'), 0, '(%ebx, %r12d, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%eax, -%ebx)'), 0, '(%eax, -%ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%eax, -%ebx, 4)'), 0, '(%eax, -%ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(,%esp, 2)'), 0, '(,%esp, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%eax ,%esp, 2)'), 0, '(%eax ,%esp, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%eax -, %ebx)'), 0, '(%eax -, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_intel ('(%eax -, %ebx, 4)'), 0, '(%eax -, %ebx, 4) is a valid 32-bit addressing scheme' );


# ----------- 64-bit

is ( is_valid_64bit_addr_intel ('zzz(,1)'), 0, 'zzz(,1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%rax)'), 0, '(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('1(%rax)'), 0, '1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('-1(%rax)'), 0, '-1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%rax, %rbx)'), 0, '(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('2(%rax, %rbx)'), 0, '2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('-2(%rax, %rbx)'), 0, '-2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%rax, %rbx, 1)'), 0, '(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('3( %rax, %rbx, 2)'), 0, '3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('-9(%rax, %rbx, 4)'), 0, '-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(, %rbx, 8)'), 0, '(, %rbx, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('7(, %rcx, 4)'), 0, '7(, %rcx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('-7(, %rdx, 2)'), 0, '-7(, %rdx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('11(,1)'), 0, '11(,1) is a valid 64-bit addressing scheme' );

# -----------

is ( is_valid_64bit_addr_intel ('%cs:zzz(,1)'), 0, '%cs:zzz(,1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%ds:(%rax)'), 0, '%ds:(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%es:1(%rax)'), 0, '%es:1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%fs:-1(%rax)'), 0, '%fs:-1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%gs:(%rax, %rbx)'), 0, '%gs:(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%ss:2(%rax, %rbx)'), 0, '%ss:2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%cs:-2(%rax, %rbx)'), 0, '%cs:-2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%ds:(%rax, %rbx, 1)'), 0, '%ds:(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%es:3( %rax, %rbx, 2)'), 0, '%es:3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%fs:-9(%rax, %rbx, 4)'), 0, '%fs:-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%gs:(, %rbx, 8)'), 0, '%gs:(, %rbx, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%ss:7(, %rcx, 4)'), 0, '%ss:7(, %rcx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%cs:-7(, %rdx, 2)'), 0, '%cs:-7(, %rdx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%ds:11(,1)'), 0, '%ds:11(,1) is a valid 64-bit addressing scheme' );

# -----------

is ( is_valid_64bit_addr_intel ('1(%cr0)'), 0, '1(%cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('1(%rax, %cr0)'), 0, '1(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('2(%cr0, %rbx, 2)'), 0, '2(%cr0, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('-1(%st7)'), 0, '-1(%st7) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('-2(%rax, %dr0)'), 0, '-2(%rax, %dr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%xmm3)'), 0, '(%xmm3) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%mm2)'), 0, '(%mm2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%rax, %xmm5)'), 0, '(%rax, %xmm5) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%rbx, %mm2)'), 0, '(%rbx, %mm2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('%rax(%rbx)'), 0, '%rax(%rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('-%rax(%rbx)'), 0, '-%rax(%rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('3(-%rsi)'), 0, '3(-%rsi) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%rax, %r12d)'), 0, '(%rax, %r12d) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%rbx, %r12d, 2)'), 0, '(%rbx, %r12d, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%rax, -%rbx)'), 0, '(%rax, -%rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%rax, -%rbx, 4)'), 0, '(%rax, -%rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(,%rsp, 2)'), 0, '(,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%rax ,%rsp, 2)'), 0, '(%rax ,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%rax ,%rip, 2)'), 0, '(%rax ,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%rax -, %rbx)'), 0, '(%rax -, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_intel ('(%rax -, %rbx, 4)'), 0, '(%rax -, %rbx, 4) is a valid 64-bit addressing scheme' );

# ----------- mixed

is ( is_valid_addr_intel ('(%ebx, %ax)'), 0, '(%ebx, %ax) is a valid addressing scheme' );
is ( is_valid_addr_intel ('(%si, %eax)'), 0, '(%si, %eax) is a valid addressing scheme' );
is ( is_valid_addr_intel ('2(%ebx,%ax)'), 0, '2(%ebx,%ax) is a valid addressing scheme' );
is ( is_valid_addr_intel ('(-%cx,%ebx,2)'), 0, '(-%cx,%ebx,2) is a valid addressing scheme' );
is ( is_valid_addr_intel ('(%si,%esi,8)'), 0, '(%si,%esi,8) is a valid addressing scheme' );
is ( is_valid_addr_intel ('(%edi,%sp)'), 0, '(%edi,%sp) is a valid addressing scheme' );

is ( is_valid_addr_intel ('(%rax,%ebx)'), 0, '(%rax,%ebx) is a valid addressing scheme' );
is ( is_valid_addr_intel ('(%rbx,%r8d)'), 0, '(%rbx,%r8d) is a valid addressing scheme' );
is ( is_valid_addr_intel ('(%ecx,%rsi)'), 0, '(%ecx,%rsi) is a valid addressing scheme' );
is ( is_valid_addr_intel ('(%rsi,%ecx,2)'), 0, '(%rsi,%ecx,2) is a valid addressing scheme' );
is ( is_valid_addr_intel ('+-1(%ecx,%edx)'), 0, '+-1(%ecx,%edx) is a valid addressing scheme' );
is ( is_valid_addr_intel ('+-1(%ecx,%rdx)'), 0, '+-1(%ecx,%rdx) is a valid addressing scheme' );
is ( is_valid_addr_intel ('+-1(%rdx,%ecx,8)'), 0, '+-1(%edx,%ecx,8) is a valid addressing scheme' );
is ( is_valid_addr_intel ('+-1(%rdx,%ecx,8)'), 0, '+-1(%rdx,%rcx,8) is a valid addressing scheme' );
is ( is_valid_addr_intel ('-1(%esi,%rax)'), 0, '-1(%esi,%rax) is a valid addressing scheme' );
is ( is_valid_addr_intel ('-%rcx(%esi)'), 0, '-%rcx(%esi) is a valid addressing scheme' );
is ( is_valid_addr_intel ('(-%rcx, %esi)'), 0, '(-%rcx, %esi) is a valid addressing scheme' );
is ( is_valid_addr_intel ('(%esi, -%rcx)'), 0, '(%esi, -%rcx) is a valid addressing scheme' );
is ( is_valid_addr_intel ('-%rcx(,1)'), 0, '-%rcx(,1) is a valid addressing scheme' );
is ( is_valid_addr_intel ('-1(-%rcx)'), 0, '-1(-%rcx) is a valid addressing scheme' );
is ( is_valid_addr_intel ('1(-%rcx)'), 0, '1(-%rcx) is a valid addressing scheme' );
is ( is_valid_addr_intel ('12(%rax,%rsp)'), 0, '12(%rax,%rsp) is a valid addressing scheme' );
is ( is_valid_addr_intel ('%cs:5(%ecx,%esi)'), 0, '%cs:5(%ecx,%esi) is a valid addressing scheme' );
is ( is_valid_addr_intel ('%ss:(%bp,%si)'), 0, '%ss:(%bp,%si) is a valid addressing scheme' );

#is ( is_valid_64bit_addr_intel ('()'), 0, ' is a valid 64-bit addressing scheme' );

# ----------- 16-bit

is ( is_valid_16bit_addr_att ("[bX]"), 0, "[bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[sI]"), 0, "[si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[Di]"), 0, "[di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[Bp]"), 0, "[bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("[bx+bx]"), 0, "[bx+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[bx+Si]"), 0, "[bx+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[bX+di]"), 0, "[bx+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[bx+bp]"), 0, "[bx+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("[sI+bx]"), 0, "[si+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[si+si]"), 0, "[si+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[si+dI]"), 0, "[si+dI] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[si+bP]"), 0, "[si+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("[di+Bx]"), 0, "[di+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[di+Si]"), 0, "[di+Si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[di+di]"), 0, "[di+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[Di+bp]"), 0, "[di+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("[bp+bX]"), 0, "[bp+bX] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[bP+si]"), 0, "[bp+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[bp+Di]"), 0, "[bp+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[bp+bP]"), 0, "[bp+bP] is a valid 16-bit addressing scheme" );

# -----------

is ( is_valid_16bit_addr_att ("cs:[bx]"), 0, "cs:[bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("cs:[si]"), 0, "cs:[si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("cs:[di]"), 0, "cs:[di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("cs:[bp]"), 0, "cs:[bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("ds:[bx+bx]"), 0, "ds:[bx+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("ds:[bx+si]"), 0, "ds:[bx+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("ds:[bx+di]"), 0, "ds:[bx+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("ds:[bx+bp]"), 0, "ds:[bx+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("es:[si+bx]"), 0, "es:[si+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("es:[si+si]"), 0, "es:[si+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("es:[si+dI]"), 0, "es:[si+dI] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("es:[si+bp]"), 0, "es:[si+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("fs:[di+bx]"), 0, "fs:[di+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("fs:[di+Si]"), 0, "fs:[di+Si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("gs:[di+di]"), 0, "gs:[di+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("gs:[di+bp]"), 0, "gs:[di+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("ss:[bp+bX]"), 0, "ss:[bp+bX] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("ss:[bp+si]"), 0, "ss:[bp+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("ss:[bp+di]"), 0, "ss:[bp+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("ss:[bp+bP]"), 0, "ss:[bp+bP] is a valid 16-bit addressing scheme" );

# -----------

is ( is_valid_16bit_addr_att ("[cs:bx]"), 0, "[cs:bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[cs:si]"), 0, "[cs:si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[cs:di]"), 0, "[cs:di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[cs:bp]"), 0, "[cs:bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("[ds:bx+bx]"), 0, "[ds:bx+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[ds:bx+si]"), 0, "[ds:bx+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[ds:bx+di]"), 0, "[ds:bx+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[ds:bx+bp]"), 0, "[ds:bx+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("[es:si+bx]"), 0, "[es:si+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[es:si+si]"), 0, "[es:si+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[es:si+dI]"), 0, "[es:si+dI] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[es:si+bp]"), 0, "[es:si+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("[fs:di+bx]"), 0, "[fs:di+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[fs:di+Si]"), 0, "[fs:di+Si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[gs:di+di]"), 0, "[gs:di+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[gs:di+bp]"), 0, "[gs:di+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("[ss:bp+bX]"), 0, "[ss:bp+bX] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[ss:bp+si]"), 0, "[ss:bp+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[ss:bp+di]"), 0, "[ss:bp+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[ss:bp+bP]"), 0, "[ss:bp+bP] is a valid 16-bit addressing scheme" );

# -----------

is ( is_valid_16bit_addr_att ("[ax]"), 0, "[ax] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[bx+cx]"), 0, "[bx+cx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[cx+bx]"), 0, "[cx+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[bp+al]"), 0, "[bp+al] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[ch+si]"), 0, "[ch+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[bx-si]"), 0, "[bx-si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[bp-2]"), 0, "[bp-2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[bp-varname]"), 0, "[bp-2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[si-ax]"), 0, "[si-ax] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[bp+-2]"), 0, "[bp+-2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[bp+-si]"), 0, "[bp+-si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("ad:[bx]"), 0, "ad:[bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[sc:di]"), 0, "[sc:di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[2+bp]"), 0, "[2+bp] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[-3+si]"), 0, "[-3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[++-3+si]"), 0, "[++-3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[3-si]"), 0, "[3-si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[--3+si]"), 0, "[--3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[-3-si]"), 0, "[-3-si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[3+5]"), 0, "[3+5] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[-3]"), 0, "[-3] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[-3+2]"), 0, "[-3+2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[+2]"), 0, "[+2] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("[cs:--3+si]"), 0, "[cs:--3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("cs:[--3+si]"), 0, "cs:[--3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("ds:[+2]"), 0, "ds:[+2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[ds:+2]"), 0, "[ds:+2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("ss:[-3]"), 0, "ss:[-3] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[ss:-3+2]"), 0, "[ss:-3+2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[es:2+bp]"), 0, "[es:2+bp] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("eS:[2+bp]"), 0, "es:[2+bp] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("fs:[++-3+si]"), 0, "fs:[++-3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("[fs:++-3+si]"), 0, "[fs:++-3+si] is a valid 16-bit addressing scheme" );

# ----------- 32-bit

is ( is_valid_32bit_addr_att ("[eax]"), 0, "[eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[beax]"), 0, "[beax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[eaxd]"), 0, "[eaxd] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("[ebx+77]"), 0, "[ebx+77] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ebx+ecx]"), 0, "[ebx+ecx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ebx+ebx+99]"), 0, "[ebx+ebx+99] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ebx+edi-88]"), 0, "[ebx+edi-88] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ebx+edi+-88]"), 0, "[ebx+edi+-88] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("[ebx+eax*2]"), 0, "[ebx+eax*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ebx+esi*4+66]"), 0, "[ebx+esi*4+66] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ebx+ecx*8-55]"), 0, "[ebx+ecx*8-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ebx+ecx*8+-55]"), 0, "[ebx+ecx*8+-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ebx+ebp*1]"), 0, "[ebx+ebp*1] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("[ecx*2 + ebx]"), 0, "[ecx*2 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ecx*4 + ebx -1]"), 0, "[ecx*4 + ebx -1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ecx*4 + ebx +-1]"), 0, "[ecx*4 + ebx +-1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ecx*8 + ebx+ 44]"), 0, "[ecx*2 + ebx+ 44] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ecx*1 + esp]"), 0, "[ecx*1 + esp] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ecx*4 -1 + ebx]"), 0, "[ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ecx*4 +-1 + ebx]"), 0, "[ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ecx*8 +44 + ebx]"), 0, "[ecx*2 +44+ ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ecx*4 -1 + ebx]"), 0, "[ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ecx*4 +-1 + ebx]"), 0, "[ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("[ecx*2]"), 0, "[ecx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[esp*1]"), 0, "[esp*1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[esp*4]"), 0, "[esp*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ecx*2 + ebx*8]"), 0, "[ecx*2 + ebx*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ecx + esp*2]"), 0, "[ecx + esp*2] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("[1+eax]"), 0, "[1+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[-2+edx]"), 0, "[-2+edx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[3+ebx*2]"), 0, "[3+ebx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[-4+esi*4]"), 0, "[-4+esi*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[5+ecx+esi]"), 0, "[5+ecx+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[-6+ecx*2+edi]"), 0, "[-6+ecx*2+edi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[7+esp+ebp*8]"), 0, "[7+esp+ebp*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[-8+esp+ebp*8]"), 0, "[-8+esp+ebp*8] is a valid 32-bit addressing scheme" );

# -----------

is ( is_valid_32bit_addr_att ("cs:[eax]"), 0, "cs:[eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("cs:[beax]"), 0, "cs:[beax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("cs:[eaxd]"), 0, "cs:[eaxd] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("ds:[ebx+77]"), 0, "ds:[ebx+77] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("ds:[ebx+ecx]"), 0, "ds:[ebx+ecx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("ds:[ebx+ebx+99]"), 0, "ds:[ebx+ebx+99] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("ds:[ebx+edi-88]"), 0, "ds:[ebx+edi-88] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("ds:[ebx+edi+-88]"), 0, "ds:[ebx+edi+-88] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("es:[ebx+eax*2]"), 0, "es:[ebx+eax*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("es:[ebx+esi*4+66]"), 0, "es:[ebx+esi*4+66] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("es:[ebx+ecx*8-55]"), 0, "es:[ebx+ecx*8-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("es:[ebx+ecx*8+-55]"), 0, "es:[ebx+ecx*8+-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("es:[ebx+ebp*1]"), 0, "es:[ebx+ebp*1] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("fs:[ecx*2 + ebx]"), 0, "fs:[ecx*2 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("fs:[ecx*4 + ebx -1]"), 0, "fs:[ecx*4 + ebx -1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("fs:[ecx*4 + ebx +-1]"), 0, "fs:[ecx*4 + ebx +-1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("fs:[ecx*8 + ebx+ 44]"), 0, "fs:[ecx*2 + ebx+ 44] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("fs:[ecx*1 + esp]"), 0, "fs:[ecx*1 + esp] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("fs:[ecx*4 -1 + ebx]"), 0, "fs:[ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("fs:[ecx*4 +-1 + ebx]"), 0, "fs:[ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("fs:[ecx*8 +44 + ebx]"), 0, "fs:[ecx*2 +44+ ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("fs:[ecx*4 -1 + ebx]"), 0, "fs:[ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("fs:[ecx*4 +-1 + ebx]"), 0, "fs:[ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("gs:[ecx*2]"), 0, "gs:[ecx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("gs:[esp*1]"), 0, "gs:[esp*1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("gs:[esp*4]"), 0, "gs:[esp*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("gs:[ecx*2 + ebx*8]"), 0, "gs:[ecx*2 + ebx*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("gs:[ecx + esp*2]"), 0, "gs:[ecx + esp*2] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("ss:[1+eax]"), 0, "ss:[1+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("ss:[-2+edx]"), 0, "ss:[-2+edx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("ss:[3+ebx*2]"), 0, "ss:[3+ebx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("ss:[-4+esi*4]"), 0, "ss:[-4+esi*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("ss:[5+ecx+esi]"), 0, "ss:[5+ecx+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("ss:[-6+ecx*2+edi]"), 0, "ss:[-6+ecx*2+edi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("ss:[7+esp+ebp*8]"), 0, "ss:[7+esp+ebp*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("ss:[-8+esp+ebp*8]"), 0, "ss:[-8+esp+ebp*8] is a valid 32-bit addressing scheme" );

# -----------

is ( is_valid_32bit_addr_att ("[ss:eax]"), 0, "[ss:eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ss:beax]"), 0, "[ss:beax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ss:eaxd]"), 0, "[ss:eaxd] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("[gs:ebx+77]"), 0, "[gs:ebx+77] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[gs:ebx+ecx]"), 0, "[gs:ebx+ecx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[gs:ebx+ebx+99]"), 0, "[gs:ebx+ebx+99] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[gs:ebx+edi-88]"), 0, "[gs:ebx+edi-88] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[gs:ebx+edi+-88]"), 0, "[gs:ebx+edi+-88] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("[fs:ebx+eax*2]"), 0, "[fs:ebx+eax*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[fs:ebx+esi*4+66]"), 0, "[fs:ebx+esi*4+66] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[fs:ebx+ecx*8-55]"), 0, "[fs:ebx+ecx*8-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[fs:ebx+ecx*8+-55]"), 0, "[fs:ebx+ecx*8+-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[fs:ebx+ebp*1]"), 0, "[fs:ebx+ebp*1] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("[es:ecx*2 + ebx]"), 0, "[es:ecx*2 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[es:ecx*4 + ebx -1]"), 0, "[es:ecx*4 + ebx -1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[es:ecx*4 + ebx +-1]"), 0, "[es:ecx*4 + ebx +-1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[es:ecx*8 + ebx+ 44]"), 0, "[es:ecx*2 + ebx+ 44] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[es:ecx*1 + esp]"), 0, "[es:ecx*1 + esp] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[es:ecx*4 -1 + ebx]"), 0, "[es:ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[es:ecx*4 +-1 + ebx]"), 0, "[es:ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[es:ecx*8 +44 + ebx]"), 0, "[es:ecx*2 +44+ ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[es:ecx*4 -1 + ebx]"), 0, "[es:ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[es:ecx*4 +-1 + ebx]"), 0, "[es:ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("[ds:ecx*2]"), 0, "[ds:ecx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ds:esp*1]"), 0, "[ds:esp*1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ds:esp*4]"), 0, "[ds:esp*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ds:ecx*2 + ebx*8]"), 0, "[ds:ecx*2 + ebx*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ds:ecx + esp*2]"), 0, "[ds:ecx + esp*2] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_att ("[cs:1+eax]"), 0, "[cs:1+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[cs:-2+edx]"), 0, "[cs:-2+edx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[cs:3+ebx*2]"), 0, "[cs:3+ebx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[cs:-4+esi*4]"), 0, "[cs:-4+esi*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[cs:5+ecx+esi]"), 0, "[cs:5+ecx+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[cs:-6+ecx*2+edi]"), 0, "[cs:-6+ecx*2+edi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[cs:7+esp+ebp*8]"), 0, "[cs:7+esp+ebp*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[cs:-8+esp+ebp*8]"), 0, "[cs:-8+esp+ebp*8] is a valid 32-bit addressing scheme" );

# -----------

is ( is_valid_32bit_addr_att ("[cr0+1]"), 0, "[cr0+1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[eax+cr0+1]"), 0, "[eax+cr0+1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[cr0+ebx*2+2]"), 0, "[cr0+ebx*2+2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[st7-1]"), 0, "[st7-1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[dr2-2+eax]"), 0, "[dr2-2+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[xmm3]"), 0, "[xmm3] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[mm2]"), 0, "[mm2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[eax+xmm3]"), 0, "[eax+xmm3] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[eax+mm2]"), 0, "[eax+mm2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[eax+ebx*2+xmm3]"), 0, "[eax+ebx*2+xmm3] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[eax+ebx*2+mm2]"), 0, "[eax+ebx*2+mm2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[eax-ebx]"), 0, "[eax-ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[eax-ebx*2]"), 0, "[eax-ebx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[eax+3-ecx]"), 0, "[eax+3-ecx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[eax+6*2+esp]"), 0, "[eax+6*2+esp] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[eax+2*ebx]"), 0, "[eax+2*ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[4*eax+esi]"), 0, "[4*eax+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[-1+4*eax+esi]"), 0, "[-1+4*eax+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[r12d+eax]"), 0, "[r12d+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[ebx+2*r8d]"), 0, "[ebx+2*r8d] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_att ("[edx+8*r9d+1]"), 0, "[edx+8*r9d+1] is a valid 32-bit addressing scheme" );

# ----------- 64-bit

is ( is_valid_64bit_addr_att ("[rax]"), 0, "[rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[brax]"), 0, "[brax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[raxd]"), 0, "[raxd] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("[rbx+77]"), 0, "[rbx+77] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rbx+rcx]"), 0, "[rbx+rcx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rbx+rbx+99]"), 0, "[rbx+rbx+99] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rbx+rdi-88]"), 0, "[rbx+rdi-88] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rbx+rdi+-88]"), 0, "[rbx+rdi+-88] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("[rbx+rax*2]"), 0, "[rbx+rax*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rbx+rsi*4+66]"), 0, "[rbx+rsi*4+66] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rbx+rcx*8-55]"), 0, "[rbx+rcx*8-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rbx+rcx*8+-55]"), 0, "[rbx+rcx*8+-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rbx+rbp*1]"), 0, "[rbx+rbp*1] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("[rcx*2 + rbx]"), 0, "[rcx*2 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rcx*4 + rbx -1]"), 0, "[rcx*4 + rbx -1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rcx*4 + rbx +-1]"), 0, "[rcx*4 + rbx +-1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rcx*8 + rbx+ 44]"), 0, "[rcx*2 + rbx+ 44] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rcx*1 + rsp]"), 0, "[rcx*1 + rsp] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rcx*4 -1 + rbx]"), 0, "[rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rcx*4 +-1 + rbx]"), 0, "[rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rcx*8 +44 + rbx]"), 0, "[rcx*2 +44+ rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rcx*4 -1 + rbx]"), 0, "[rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rcx*4 +-1 + rbx]"), 0, "[rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("[rcx*2]"), 0, "[rcx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rsp*1]"), 0, "[rsp*1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rsp*4]"), 0, "[rsp*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rcx*2 + rbx*8]"), 0, "[rcx*2 + rbx*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rcx + rsp*2]"), 0, "[rcx + rsp*2] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("[1+rax]"), 0, "[1+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[-2+rdx]"), 0, "[-2+rdx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[3+rbx*2]"), 0, "[3+rbx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[-4+rsi*4]"), 0, "[-4+rsi*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[5+rcx+rsi]"), 0, "[5+rcx+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[-6+rcx*2+rdi]"), 0, "[-6+rcx*2+rdi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[7+rsp+rbp*8]"), 0, "[7+rsp+rbp*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[-8+rsp+rbp*8]"), 0, "[-8+rsp+rbp*8] is a valid 64-bit addressing scheme" );

# -----------

is ( is_valid_64bit_addr_att ("cs:[rax]"), 0, "cs:[rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("cs:[brax]"), 0, "cs:[brax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("cs:[raxd]"), 0, "cs:[raxd] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("ds:[rbx+77]"), 0, "ds:[rbx+77] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("ds:[rbx+rcx]"), 0, "ds:[rbx+rcx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("ds:[rbx+rbx+99]"), 0, "ds:[rbx+rbx+99] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("ds:[rbx+rdi-88]"), 0, "ds:[rbx+rdi-88] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("ds:[rbx+rdi+-88]"), 0, "ds:[rbx+rdi+-88] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("es:[rbx+rax*2]"), 0, "es:[rbx+rax*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("es:[rbx+rsi*4+66]"), 0, "es:[rbx+rsi*4+66] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("es:[rbx+rcx*8-55]"), 0, "es:[rbx+rcx*8-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("es:[rbx+rcx*8+-55]"), 0, "es:[rbx+rcx*8+-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("es:[rbx+rbp*1]"), 0, "es:[rbx+rbp*1] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("fs:[rcx*2 + rbx]"), 0, "fs:[rcx*2 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("fs:[rcx*4 + rbx -1]"), 0, "fs:[rcx*4 + rbx -1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("fs:[rcx*4 + rbx +-1]"), 0, "fs:[rcx*4 + rbx +-1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("fs:[rcx*8 + rbx+ 44]"), 0, "fs:[rcx*2 + rbx+ 44] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("fs:[rcx*1 + rsp]"), 0, "fs:[rcx*1 + rsp] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("fs:[rcx*4 -1 + rbx]"), 0, "fs:[rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("fs:[rcx*4 +-1 + rbx]"), 0, "fs:[rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("fs:[rcx*8 +44 + rbx]"), 0, "fs:[rcx*2 +44+ rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("fs:[rcx*4 -1 + rbx]"), 0, "fs:[rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("fs:[rcx*4 +-1 + rbx]"), 0, "fs:[rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("gs:[rcx*2]"), 0, "gs:[rcx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("gs:[rsp*1]"), 0, "gs:[rsp*1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("gs:[rsp*4]"), 0, "gs:[rsp*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("gs:[rcx*2 + rbx*8]"), 0, "gs:[rcx*2 + rbx*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("gs:[rcx + rsp*2]"), 0, "gs:[rcx + rsp*2] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("ss:[1+rax]"), 0, "ss:[1+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("ss:[-2+rdx]"), 0, "ss:[-2+rdx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("ss:[3+rbx*2]"), 0, "ss:[3+rbx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("ss:[-4+rsi*4]"), 0, "ss:[-4+rsi*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("ss:[5+rcx+rsi]"), 0, "ss:[5+rcx+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("ss:[-6+rcx*2+rdi]"), 0, "ss:[-6+rcx*2+rdi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("ss:[7+rsp+rbp*8]"), 0, "ss:[7+rsp+rbp*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("ss:[-8+rsp+rbp*8]"), 0, "ss:[-8+rsp+rbp*8] is a valid 64-bit addressing scheme" );

# -----------

is ( is_valid_64bit_addr_att ("[ss:rax]"), 0, "[ss:rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[ss:brax]"), 0, "[ss:brax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[ss:raxd]"), 0, "[ss:raxd] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("[gs:rbx+77]"), 0, "[gs:rbx+77] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[gs:rbx+rcx]"), 0, "[gs:rbx+rcx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[gs:rbx+rbx+99]"), 0, "[gs:rbx+rbx+99] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[gs:rbx+rdi-88]"), 0, "[gs:rbx+rdi-88] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[gs:rbx+rdi+-88]"), 0, "[gs:rbx+rdi+-88] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("[fs:rbx+rax*2]"), 0, "[fs:rbx+rax*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[fs:rbx+rsi*4+66]"), 0, "[fs:rbx+rsi*4+66] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[fs:rbx+rcx*8-55]"), 0, "[fs:rbx+rcx*8-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[fs:rbx+rcx*8+-55]"), 0, "[fs:rbx+rcx*8+-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[fs:rbx+rbp*1]"), 0, "[fs:rbx+rbp*1] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("[es:rcx*2 + rbx]"), 0, "[es:rcx*2 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[es:rcx*4 + rbx -1]"), 0, "[es:rcx*4 + rbx -1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[es:rcx*4 + rbx +-1]"), 0, "[es:rcx*4 + rbx +-1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[es:rcx*8 + rbx+ 44]"), 0, "[es:rcx*2 + rbx+ 44] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[es:rcx*1 + rsp]"), 0, "[es:rcx*1 + rsp] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[es:rcx*4 -1 + rbx]"), 0, "[es:rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[es:rcx*4 +-1 + rbx]"), 0, "[es:rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[es:rcx*8 +44 + rbx]"), 0, "[es:rcx*2 +44+ rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[es:rcx*4 -1 + rbx]"), 0, "[es:rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[es:rcx*4 +-1 + rbx]"), 0, "[es:rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("[ds:rcx*2]"), 0, "[ds:rcx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[ds:rsp*1]"), 0, "[ds:rsp*1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[ds:rsp*4]"), 0, "[ds:rsp*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[ds:rcx*2 + rbx*8]"), 0, "[ds:rcx*2 + rbx*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[ds:rcx + rsp*2]"), 0, "[ds:rcx + rsp*2] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_att ("[cs:1+rax]"), 0, "[cs:1+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[cs:-2+rdx]"), 0, "[cs:-2+rdx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[cs:3+rbx*2]"), 0, "[cs:3+rbx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[cs:-4+rsi*4]"), 0, "[cs:-4+rsi*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[cs:5+rcx+rsi]"), 0, "[cs:5+rcx+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[cs:-6+rcx*2+rdi]"), 0, "[cs:-6+rcx*2+rdi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[cs:7+rsp+rbp*8]"), 0, "[cs:7+rsp+rbp*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[cs:-8+rsp+rbp*8]"), 0, "[cs:-8+rsp+rbp*8] is a valid 64-bit addressing scheme" );

# -----------

is ( is_valid_64bit_addr_att ("[cr0+1]"), 0, "[cr0+1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rax+cr0+1]"), 0, "[rax+cr0+1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[cr0+rbx*2+2]"), 0, "[cr0+rbx*2+2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[st7-1]"), 0, "[st7-1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[dr2-2+rax]"), 0, "[dr2-2+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[xmm3]"), 0, "[xmm3] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[mm2]"), 0, "[mm2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rax+xmm3]"), 0, "[rax+xmm3] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rax+mm2]"), 0, "[rax+mm2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rax+rbx*2+xmm3]"), 0, "[rax+rbx*2+xmm3] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rax+rbx*2+mm2]"), 0, "[rax+rbx*2+mm2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rax-rbx]"), 0, "[rax-rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rax-rbx*2]"), 0, "[rax-rbx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rax+3-rcx]"), 0, "[rax+3-rcx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rax+6*2+rsp]"), 0, "[rax+6*2+rsp] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rax+2*rbx]"), 0, "[rax+2*rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[4*rax+rsi]"), 0, "[4*rax+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[-1+4*rax+rsi]"), 0, "[-1+4*rax+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[r12d+rax]"), 0, "[r12d+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rbx+2*r8d]"), 0, "[rbx+2*r8d] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[rdx+8*r9d+1]"), 0, "[rdx+8*r9d+1] is a valid 64-bit addressing scheme" );
# the extra 3:
is ( is_valid_64bit_addr_att ("[ebx+r10d]"), 0, "[ebx+r10d] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[ebx+2*r8d]"), 0, "[ebx+2*r8d] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_att ("[edx+8*r9d+1]"), 0, "[edx+8*r9d+1] is a valid 64-bit addressing scheme" );

# ----------- mixed

is ( is_valid_addr_att ("[ebx+ax]"), 0, "[ebx+ax] is a valid addressing scheme" );
is ( is_valid_addr_att ("[si+eax]"), 0, "[si+eax] is a valid addressing scheme" );
is ( is_valid_addr_att ("[ebx+2+ax]"), 0, "[ebx+2+ax] is a valid addressing scheme" );
is ( is_valid_addr_att ("[2*ebx-cx]"), 0, "[2*ebx-cx] is a valid addressing scheme" );
is ( is_valid_addr_att ("[esi*8+si]"), 0, "[esi*8+si] is a valid addressing scheme" );
is ( is_valid_addr_att ("[edi+sp]"), 0, "[edi+sp] is a valid addressing scheme" );

is ( is_valid_addr_att ("[rax+ebx]"), 0, "[rax+ebx] is a valid addressing scheme" );
is ( is_valid_addr_att ("[rbx+r8d]"), 0, "[rbx+r8d] is a valid addressing scheme" );
is ( is_valid_addr_att ("[ecx+rsi]"), 0, "[ecx+rsi] is a valid addressing scheme" );
is ( is_valid_addr_att ("[ecx*2+rsi]"), 0, "[ecx*2+rsi] is a valid addressing scheme" );
is ( is_valid_addr_att ("[+-1+ecx+edx]"), 0, "[+-1+ecx+edx] is a valid addressing scheme" );
is ( is_valid_addr_att ("[+-1+ecx+rdx]"), 0, "[+-1+ecx+rdx] is a valid addressing scheme" );
is ( is_valid_addr_att ("[+-1+ecx*8+rdx]"), 0, "[+-1+ecx*8+rdx] is a valid addressing scheme" );
is ( is_valid_addr_att ("[+-1+rdx+ecx*8]"), 0, "[+-1+rdx+ecx*8] is a valid  addressing scheme" );
is ( is_valid_addr_att ("[esi+-1+rax]"), 0, "[esi+-1+rax] is a valid  addressing scheme" );
is ( is_valid_addr_att ("[esi-rcx]"), 0, "[esi-rcx] is a valid  addressing scheme" );
is ( is_valid_addr_att ("[+1-rcx]"), 0, "[+1-rcx] is a valid  addressing scheme" );
is ( is_valid_addr_att ("[-1-rcx]"), 0, "[-1-rcx] is a valid  addressing scheme" );

is ( is_valid_addr_att ("[rax+6*2+rsp]"), 0, "[rax+6*2+rsp] is a valid addressing scheme" );
is ( is_valid_addr_att ("[cs:5+ecx+esi]"), 0, "[cs:5+ecx+esi] is a valid addressing scheme" );
is ( is_valid_addr_att ("[ss:bp+si]"), 0, "[ss:bp+si] is a valid addressing scheme" );

#is ( is_valid_addr_att ("[]"), 0, "[] is a valid addressing scheme" );

#####################################################################################

# ----------- 16-bit

is ( is_valid_16bit_addr ("(\%bX)"), 1, "(bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%sI)"), 1, "(si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%Di)"), 1, "(di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%Bp)"), 1, "(bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("(\%bx,\%bx)"), 0, "(bx,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%bx,\%Si)"), 1, "(bx,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%bX,\%di)"), 1, "(bx,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%bx,\%bp)"), 0, "(bx,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("(\%sI,\%bx)"), 1, "(si,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%si,\%si)"), 0, "(si,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%si,\%dI)"), 0, "(si,dI) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%si,\%bP)"), 1, "(si,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("(\%di,\%Bx)"), 1, "(di,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%di,\%Si)"), 0, "(di,Si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%di,\%di)"), 0, "(di,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%Di,\%bp)"), 1, "(di,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("(\%bp,\%bX)"), 0, "(bp,bX) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%bP,\%si)"), 1, "(bp,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%bp,\%Di)"), 1, "(bp,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%bp,\%bP)"), 0, "(bp,bP) is a valid 16-bit addressing scheme" );

# -----------

is ( is_valid_16bit_addr ("\%cs:(\%bx)"), 1, "cs:(bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%cs:(\%si)"), 1, "cs:(si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%cs:(\%di)"), 1, "cs:(di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%cs:(\%bp)"), 1, "cs:(bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("\%ds:(\%bx,\%bx)"), 0, "ds:(bx,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%ds:(\%bx,\%si)"), 1, "ds:(bx,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%ds:(\%bx,\%di)"), 1, "ds:(bx,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%ds:(\%bx,\%bp)"), 0, "ds:(bx,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("\%es:(\%si,\%bx)"), 1, "es:(si,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%es:(\%si,\%si)"), 0, "es:(si,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%es:(\%si,\%dI)"), 0, "es:(si,dI) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%es:(\%si,\%bp)"), 1, "es:(si,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("\%fs:(\%di,\%bx)"), 1, "fs:(di,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%fs:(\%di,\%Si)"), 0, "fs:(di,Si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%gs:(\%di,\%di)"), 0, "gs:(di,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%gs:(\%di,\%bp)"), 1, "gs:(di,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("\%ss:(\%bp,\%bX)"), 0, "ss:(bp,bX) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%ss:(\%bp,\%si)"), 1, "ss:(bp,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%ss:(\%bp,\%di)"), 1, "ss:(bp,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%ss:(\%bp,\%bP)"), 0, "ss:(bp,bP) is a valid 16-bit addressing scheme" );


# -----------

is ( is_valid_16bit_addr ("(\%ax)"), 0, "(ax) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%bx,\%cx)"), 0, "(bx,cx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%cx,\%bx)"), 0, "(cx,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%bp,\%al)"), 0, "(bp,al) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%ch,\%si)"), 0, "(ch,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%bx-\%si)"), 0, "(bx-si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("-2(\%bp)"), 1, "-2(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("-varname(\%bp)"), 1, "-varname(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%si-\%ax)"), 0, "(si-ax) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("+-2(\%bp)"), 1, "+-2(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("-si(\%bp)"), 1, "-si(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%ad:(\%bx)"), 0, "ad:(bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%sc:\%di)"), 0, "(sc:di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(2,\%bp)"), 0, "(2,bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("-3(\%si)"), 1, "-3(si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(,,-3,\%si)"), 0, "(,,-3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(3-\%si)"), 0, "(3-si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(--3,\%si)"), 0, "(--3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(-3-\%si)"), 0, "(-3-si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(3,5)"), 0, "(3,5) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(-3)"), 1, "(-3) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(-3,2)"), 0, "(-3,2) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(,2)"), 0, "(,2) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("\%(cs:--3,si)"), 0, "(cs:--3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%cs:(--3,si)"), 0, "cs:(--3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%ds:(,2)"), 0, "ds:(,2) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%ds:,2)"), 0, "(ds:,2) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%ss:(-3)"), 1, "ss:(-3) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%ss:-3,2)"), 0, "(ss:-3,2) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%es:2,bp)"), 0, "(es:2,bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%eS:(2,bp)"), 0, "es:(2,bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("\%fs:(,,-3,si)"), 0, "fs:(,,-3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("(\%fs:,,-3,si)"), 0, "(fs:,,-3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("zzz(,1)"), 1, "zzz(,1) is a valid 16-bit addressing scheme" );

# ----------- 32-bit

is ( is_valid_32bit_addr ('zzz(,1)'), 1, 'zzz(,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%eax)'), 1, '(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('1(%eax)'), 1, '1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('-1(%eax)'), 1, '-1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%eax, %ebx)'), 1, '(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('2(%eax, %ebx)'), 1, '2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('-2(%eax, %ebx)'), 1, '-2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%eax, %ebx, 1)'), 1, '(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('3( %eax, %ebx, 2)'), 1, '3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('-9(%eax, %ebx, 4)'), 1, '-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(, %ebx, 8)'), 1, '(, %ebx, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('7(, %ecx, 4)'), 1, '7(, %ecx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('-7(, %edx, 2)'), 1, '-7(, %edx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('11(,1)'), 1, '11(,1) is a valid 32-bit addressing scheme' );

# -----------

is ( is_valid_32bit_addr ('%cs:zzz(,1)'), 1, '%cs:zzz(,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%ds:(%eax)'), 1, '%ds:(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%es:1(%eax)'), 1, '%es:1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%fs:-1(%eax)'), 1, '-%fs:1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%gs:(%eax, %ebx)'), 1, '%gs:(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%ss:2(%eax, %ebx)'), 1, '%ss:2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%cs:-2(%eax, %ebx)'), 1, '%cs:-2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%ds:(%eax, %ebx, 1)'), 1, '%ds:(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%es:3( %eax, %ebx, 2)'), 1, '%es:3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%fs:-9(%eax, %ebx, 4)'), 1, '%fs:-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%gs:(, %ebx, 8)'), 1, '%gs:(, %ebx, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%ss:7(, %ecx, 4)'), 1, '%ss:7(, %ecx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%cs:-7(, %edx, 2)'), 1, '%cs:-7(, %edx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%ds:11(,1)'), 1, '%ds:11(,1) is a valid 32-bit addressing scheme' );

# -----------

is ( is_valid_32bit_addr ('1(%cr0)'), 0, '1(%cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('1(%eax, %cr0)'), 0, '1(%eax, %cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('2(%cr0, %ebx, 2)'), 0, '2(%cr0, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('-1(%st7)'), 0, '-1(%st7) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('-2(%eax, %dr0)'), 0, '-2(%eax, %dr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%xmm3)'), 0, '(%xmm3) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%mm2)'), 0, '(%mm2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%eax, %xmm5)'), 0, '(%eax, %xmm5) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%ebx, %mm2)'), 0, '(%ebx, %mm2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('%eax(%ebx)'), 0, '%eax(%ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('-%eax(%ebx)'), 0, '-%eax(%ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('3(-%esi)'), 0, '3(-%esi) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%eax, %r12d)'), 0, '(%eax, %r12d) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%ebx, %r12d, 2)'), 0, '(%ebx, %r12d, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%eax, -%ebx)'), 0, '(%eax, -%ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%eax, -%ebx, 4)'), 0, '(%eax, -%ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(,%esp, 2)'), 0, '(,%esp, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%eax ,%esp, 2)'), 0, '(%eax ,%esp, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%eax -, %ebx)'), 0, '(%eax -, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr ('(%eax -, %ebx, 4)'), 0, '(%eax -, %ebx, 4) is a valid 32-bit addressing scheme' );


# ----------- 64-bit

is ( is_valid_64bit_addr ('zzz(,1)'), 1, 'zzz(,1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%rax)'), 1, '(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('1(%rax)'), 1, '1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('-1(%rax)'), 1, '-1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%rax, %rbx)'), 1, '(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('2(%rax, %rbx)'), 1, '2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('-2(%rax, %rbx)'), 1, '-2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%rax, %rbx, 1)'), 1, '(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('3( %rax, %rbx, 2)'), 1, '3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('-9(%rax, %rbx, 4)'), 1, '-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(, %rbx, 8)'), 1, '(, %rbx, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('7(, %rcx, 4)'), 1, '7(, %rcx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('-7(, %rdx, 2)'), 1, '-7(, %rdx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('11(,1)'), 1, '11(,1) is a valid 64-bit addressing scheme' );

# -----------

is ( is_valid_64bit_addr ('%cs:zzz(,1)'), 1, '%cs:zzz(,1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%ds:(%rax)'), 1, '%ds:(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%es:1(%rax)'), 1, '%es:1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%fs:-1(%rax)'), 1, '%fs:-1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%gs:(%rax, %rbx)'), 1, '%gs:(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%ss:2(%rax, %rbx)'), 1, '%ss:2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%cs:-2(%rax, %rbx)'), 1, '%cs:-2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%ds:(%rax, %rbx, 1)'), 1, '%ds:(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%es:3( %rax, %rbx, 2)'), 1, '%es:3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%fs:-9(%rax, %rbx, 4)'), 1, '%fs:-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%gs:(, %rbx, 8)'), 1, '%gs:(, %rbx, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%ss:7(, %rcx, 4)'), 1, '%ss:7(, %rcx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%cs:-7(, %rdx, 2)'), 1, '%cs:-7(, %rdx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%ds:11(,1)'), 1, '%ds:11(,1) is a valid 64-bit addressing scheme' );

# -----------

is ( is_valid_64bit_addr ('1(%cr0)'), 0, '1(%cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('1(%rax, %cr0)'), 0, '1(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('2(%cr0, %rbx, 2)'), 0, '2(%cr0, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('-1(%st7)'), 0, '-1(%st7) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('-2(%rax, %dr0)'), 0, '-2(%rax, %dr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%xmm3)'), 0, '(%xmm3) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%mm2)'), 0, '(%mm2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%rax, %xmm5)'), 0, '(%rax, %xmm5) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%rbx, %mm2)'), 0, '(%rbx, %mm2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('%rax(%rbx)'), 0, '%rax(%rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('-%rax(%rbx)'), 0, '-%rax(%rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('3(-%rsi)'), 0, '3(-%rsi) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%rax, %r12d)'), 0, '(%rax, %r12d) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%rbx, %r12d, 2)'), 0, '(%rbx, %r12d, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%rax, -%rbx)'), 0, '(%rax, -%rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%rax, -%rbx, 4)'), 0, '(%rax, -%rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(,%rsp, 2)'), 0, '(,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%rax ,%rsp, 2)'), 0, '(%rax ,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%rax ,%rip, 2)'), 0, '(%rax ,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%rax -, %rbx)'), 0, '(%rax -, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr ('(%rax -, %rbx, 4)'), 0, '(%rax -, %rbx, 4) is a valid 64-bit addressing scheme' );

# ----------- mixed

is ( is_valid_addr ('(%ebx, %ax)'), 0, '(%ebx, %ax) is a valid addressing scheme' );
is ( is_valid_addr ('(%si, %eax)'), 0, '(%si, %eax) is a valid addressing scheme' );
is ( is_valid_addr ('2(%ebx,%ax)'), 0, '2(%ebx,%ax) is a valid addressing scheme' );
is ( is_valid_addr ('(-%cx,%ebx,2)'), 0, '(-%cx,%ebx,2) is a valid addressing scheme' );
is ( is_valid_addr ('(%si,%esi,8)'), 0, '(%si,%esi,8) is a valid addressing scheme' );
is ( is_valid_addr ('(%edi,%sp)'), 0, '(%edi,%sp) is a valid addressing scheme' );

is ( is_valid_addr ('(%rax,%ebx)'), 0, '(%rax,%ebx) is a valid addressing scheme' );
is ( is_valid_addr ('(%rbx,%r8d)'), 0, '(%rbx,%r8d) is a valid addressing scheme' );
is ( is_valid_addr ('(%ecx,%rsi)'), 0, '(%ecx,%rsi) is a valid addressing scheme' );
is ( is_valid_addr ('(%rsi,%ecx,2)'), 0, '(%rsi,%ecx,2) is a valid addressing scheme' );
is ( is_valid_addr ('+-1(%ecx,%edx)'), 1, '+-1(%ecx,%edx) is a valid addressing scheme' );
is ( is_valid_addr ('+-1(%ecx,%rdx)'), 0, '+-1(%ecx,%rdx) is a valid addressing scheme' );
is ( is_valid_addr ('+-1(%rdx,%ecx,8)'), 0, '+-1(%edx,%ecx,8) is a valid addressing scheme' );
is ( is_valid_addr ('+-1(%rdx,%ecx,8)'), 0, '+-1(%rdx,%rcx,8) is a valid addressing scheme' );
is ( is_valid_addr ('-1(%esi,%rax)'), 0, '-1(%esi,%rax) is a valid addressing scheme' );
is ( is_valid_addr ('-%rcx(%esi)'), 0, '-%rcx(%esi) is a valid addressing scheme' );
is ( is_valid_addr ('(-%rcx, %esi)'), 0, '(-%rcx, %esi) is a valid addressing scheme' );
is ( is_valid_addr ('(%esi, -%rcx)'), 0, '(%esi, -%rcx) is a valid addressing scheme' );
is ( is_valid_addr ('-%rcx(,1)'), 0, '-%rcx(,1) is a valid addressing scheme' );
is ( is_valid_addr ('-1(-%rcx)'), 0, '-1(-%rcx) is a valid addressing scheme' );
is ( is_valid_addr ('1(-%rcx)'), 0, '1(-%rcx) is a valid addressing scheme' );
is ( is_valid_addr ('12(%rax,%rsp)'), 1, '12(%rax,%rsp) is a valid addressing scheme' );
is ( is_valid_addr ('%cs:5(%ecx,%esi)'), 1, '%cs:5(%ecx,%esi) is a valid addressing scheme' );
is ( is_valid_addr ('%ss:(%bp,%si)'), 1, '%ss:(%bp,%si) is a valid addressing scheme' );

#is ( is_valid_64bit_addr ('()'), 0, ' is a valid 64-bit addressing scheme' );
# ----------- 16-bit

is ( is_valid_16bit_addr ("[bX]"), 1, "[bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[sI]"), 1, "[si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[Di]"), 1, "[di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[Bp]"), 1, "[bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("[bx+bx]"), 0, "[bx+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[bx+Si]"), 1, "[bx+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[bX+di]"), 1, "[bx+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[bx+bp]"), 0, "[bx+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("[sI+bx]"), 1, "[si+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[si+si]"), 0, "[si+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[si+dI]"), 0, "[si+dI] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[si+bP]"), 1, "[si+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("[di+Bx]"), 1, "[di+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[di+Si]"), 0, "[di+Si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[di+di]"), 0, "[di+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[Di+bp]"), 1, "[di+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("[bp+bX]"), 0, "[bp+bX] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[bP+si]"), 1, "[bp+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[bp+Di]"), 1, "[bp+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[bp+bP]"), 0, "[bp+bP] is a valid 16-bit addressing scheme" );

# -----------

is ( is_valid_16bit_addr ("cs:[bx]"), 1, "cs:[bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("cs:[si]"), 1, "cs:[si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("cs:[di]"), 1, "cs:[di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("cs:[bp]"), 1, "cs:[bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("ds:[bx+bx]"), 0, "ds:[bx+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("ds:[bx+si]"), 1, "ds:[bx+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("ds:[bx+di]"), 1, "ds:[bx+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("ds:[bx+bp]"), 0, "ds:[bx+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("es:[si+bx]"), 1, "es:[si+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("es:[si+si]"), 0, "es:[si+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("es:[si+dI]"), 0, "es:[si+dI] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("es:[si+bp]"), 1, "es:[si+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("fs:[di+bx]"), 1, "fs:[di+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("fs:[di+Si]"), 0, "fs:[di+Si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("gs:[di+di]"), 0, "gs:[di+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("gs:[di+bp]"), 1, "gs:[di+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("ss:[bp+bX]"), 0, "ss:[bp+bX] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("ss:[bp+si]"), 1, "ss:[bp+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("ss:[bp+di]"), 1, "ss:[bp+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("ss:[bp+bP]"), 0, "ss:[bp+bP] is a valid 16-bit addressing scheme" );

# -----------

is ( is_valid_16bit_addr ("[cs:bx]"), 1, "[cs:bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[cs:si]"), 1, "[cs:si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[cs:di]"), 1, "[cs:di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[cs:bp]"), 1, "[cs:bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("[ds:bx+bx]"), 0, "[ds:bx+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[ds:bx+si]"), 1, "[ds:bx+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[ds:bx+di]"), 1, "[ds:bx+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[ds:bx+bp]"), 0, "[ds:bx+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("[es:si+bx]"), 1, "[es:si+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[es:si+si]"), 0, "[es:si+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[es:si+dI]"), 0, "[es:si+dI] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[es:si+bp]"), 1, "[es:si+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("[fs:di+bx]"), 1, "[fs:di+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[fs:di+Si]"), 0, "[fs:di+Si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[gs:di+di]"), 0, "[gs:di+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[gs:di+bp]"), 1, "[gs:di+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("[ss:bp+bX]"), 0, "[ss:bp+bX] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[ss:bp+si]"), 1, "[ss:bp+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[ss:bp+di]"), 1, "[ss:bp+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[ss:bp+bP]"), 0, "[ss:bp+bP] is a valid 16-bit addressing scheme" );

# -----------

is ( is_valid_16bit_addr ("[ax]"), 0, "[ax] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[bx+cx]"), 0, "[bx+cx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[cx+bx]"), 0, "[cx+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[bp+al]"), 0, "[bp+al] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[ch+si]"), 0, "[ch+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[bx-si]"), 0, "[bx-si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[bp-2]"), 1, "[bp-2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[bp-varname]"), 1, "[bp-2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[si-ax]"), 0, "[si-ax] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[bp+-2]"), 1, "[bp+-2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[bp+-si]"), 0, "[bp+-si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("ad:[bx]"), 0, "ad:[bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[sc:di]"), 0, "[sc:di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[2+bp]"), 1, "[2+bp] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[-3+si]"), 1, "[-3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[++-3+si]"), 1, "[++-3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[3-si]"), 0, "[3-si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[--3+si]"), 1, "[--3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[-3-si]"), 0, "[-3-si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[3+5]"), 1, "[3+5] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[-3]"), 1, "[-3] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[-3+2]"), 1, "[-3+2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[+2]"), 1, "[+2] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr ("[cs:--3+si]"), 1, "[cs:--3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("cs:[--3+si]"), 1, "cs:[--3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("ds:[+2]"), 1, "ds:[+2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[ds:+2]"), 1, "[ds:+2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("ss:[-3]"), 1, "ss:[-3] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[ss:-3+2]"), 1, "[ss:-3+2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[es:2+bp]"), 1, "[es:2+bp] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("eS:[2+bp]"), 1, "es:[2+bp] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("fs:[++-3+si]"), 1, "fs:[++-3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr ("[fs:++-3+si]"), 1, "[fs:++-3+si] is a valid 16-bit addressing scheme" );

# ----------- 32-bit

is ( is_valid_32bit_addr ("[eax]"), 1, "[eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[beax]"), 1, "[beax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[eaxd]"), 1, "[eaxd] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("[ebx+77]"), 1, "[ebx+77] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ebx+ecx]"), 1, "[ebx+ecx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ebx+ebx+99]"), 1, "[ebx+ebx+99] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ebx+edi-88]"), 1, "[ebx+edi-88] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ebx+edi+-88]"), 1, "[ebx+edi+-88] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("[ebx+eax*2]"), 1, "[ebx+eax*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ebx+esi*4+66]"), 1, "[ebx+esi*4+66] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ebx+ecx*8-55]"), 1, "[ebx+ecx*8-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ebx+ecx*8+-55]"), 1, "[ebx+ecx*8+-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ebx+ebp*1]"), 1, "[ebx+ebp*1] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("[ecx*2 + ebx]"), 1, "[ecx*2 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ecx*4 + ebx -1]"), 1, "[ecx*4 + ebx -1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ecx*4 + ebx +-1]"), 1, "[ecx*4 + ebx +-1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ecx*8 + ebx+ 44]"), 1, "[ecx*2 + ebx+ 44] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ecx*1 + esp]"), 1, "[ecx*1 + esp] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ecx*4 -1 + ebx]"), 1, "[ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ecx*4 +-1 + ebx]"), 1, "[ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ecx*8 +44 + ebx]"), 1, "[ecx*2 +44+ ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ecx*4 -1 + ebx]"), 1, "[ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ecx*4 +-1 + ebx]"), 1, "[ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("[ecx*2]"), 1, "[ecx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[esp*1]"), 1, "[esp*1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[esp*4]"), 0, "[esp*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ecx*2 + ebx*8]"), 0, "[ecx*2 + ebx*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ecx + esp*2]"), 0, "[ecx + esp*2] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("[1+eax]"), 1, "[1+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[-2+edx]"), 1, "[-2+edx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[3+ebx*2]"), 1, "[3+ebx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[-4+esi*4]"), 1, "[-4+esi*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[5+ecx+esi]"), 1, "[5+ecx+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[-6+ecx*2+edi]"), 1, "[-6+ecx*2+edi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[7+esp+ebp*8]"), 1, "[7+esp+ebp*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[-8+esp+ebp*8]"), 1, "[-8+esp+ebp*8] is a valid 32-bit addressing scheme" );

# -----------

is ( is_valid_32bit_addr ("cs:[eax]"), 1, "cs:[eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("cs:[beax]"), 1, "cs:[beax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("cs:[eaxd]"), 1, "cs:[eaxd] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("ds:[ebx+77]"), 1, "ds:[ebx+77] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("ds:[ebx+ecx]"), 1, "ds:[ebx+ecx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("ds:[ebx+ebx+99]"), 1, "ds:[ebx+ebx+99] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("ds:[ebx+edi-88]"), 1, "ds:[ebx+edi-88] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("ds:[ebx+edi+-88]"), 1, "ds:[ebx+edi+-88] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("es:[ebx+eax*2]"), 1, "es:[ebx+eax*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("es:[ebx+esi*4+66]"), 1, "es:[ebx+esi*4+66] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("es:[ebx+ecx*8-55]"), 1, "es:[ebx+ecx*8-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("es:[ebx+ecx*8+-55]"), 1, "es:[ebx+ecx*8+-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("es:[ebx+ebp*1]"), 1, "es:[ebx+ebp*1] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("fs:[ecx*2 + ebx]"), 1, "fs:[ecx*2 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("fs:[ecx*4 + ebx -1]"), 1, "fs:[ecx*4 + ebx -1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("fs:[ecx*4 + ebx +-1]"), 1, "fs:[ecx*4 + ebx +-1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("fs:[ecx*8 + ebx+ 44]"), 1, "fs:[ecx*2 + ebx+ 44] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("fs:[ecx*1 + esp]"), 1, "fs:[ecx*1 + esp] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("fs:[ecx*4 -1 + ebx]"), 1, "fs:[ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("fs:[ecx*4 +-1 + ebx]"), 1, "fs:[ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("fs:[ecx*8 +44 + ebx]"), 1, "fs:[ecx*2 +44+ ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("fs:[ecx*4 -1 + ebx]"), 1, "fs:[ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("fs:[ecx*4 +-1 + ebx]"), 1, "fs:[ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("gs:[ecx*2]"), 1, "gs:[ecx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("gs:[esp*1]"), 1, "gs:[esp*1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("gs:[esp*4]"), 0, "gs:[esp*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("gs:[ecx*2 + ebx*8]"), 0, "gs:[ecx*2 + ebx*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("gs:[ecx + esp*2]"), 0, "gs:[ecx + esp*2] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("ss:[1+eax]"), 1, "ss:[1+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("ss:[-2+edx]"), 1, "ss:[-2+edx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("ss:[3+ebx*2]"), 1, "ss:[3+ebx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("ss:[-4+esi*4]"), 1, "ss:[-4+esi*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("ss:[5+ecx+esi]"), 1, "ss:[5+ecx+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("ss:[-6+ecx*2+edi]"), 1, "ss:[-6+ecx*2+edi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("ss:[7+esp+ebp*8]"), 1, "ss:[7+esp+ebp*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("ss:[-8+esp+ebp*8]"), 1, "ss:[-8+esp+ebp*8] is a valid 32-bit addressing scheme" );

# -----------

is ( is_valid_32bit_addr ("[ss:eax]"), 1, "[ss:eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ss:beax]"), 1, "[ss:beax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ss:eaxd]"), 1, "[ss:eaxd] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("[gs:ebx+77]"), 1, "[gs:ebx+77] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[gs:ebx+ecx]"), 1, "[gs:ebx+ecx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[gs:ebx+ebx+99]"), 1, "[gs:ebx+ebx+99] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[gs:ebx+edi-88]"), 1, "[gs:ebx+edi-88] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[gs:ebx+edi+-88]"), 1, "[gs:ebx+edi+-88] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("[fs:ebx+eax*2]"), 1, "[fs:ebx+eax*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[fs:ebx+esi*4+66]"), 1, "[fs:ebx+esi*4+66] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[fs:ebx+ecx*8-55]"), 1, "[fs:ebx+ecx*8-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[fs:ebx+ecx*8+-55]"), 1, "[fs:ebx+ecx*8+-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[fs:ebx+ebp*1]"), 1, "[fs:ebx+ebp*1] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("[es:ecx*2 + ebx]"), 1, "[es:ecx*2 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[es:ecx*4 + ebx -1]"), 1, "[es:ecx*4 + ebx -1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[es:ecx*4 + ebx +-1]"), 1, "[es:ecx*4 + ebx +-1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[es:ecx*8 + ebx+ 44]"), 1, "[es:ecx*2 + ebx+ 44] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[es:ecx*1 + esp]"), 1, "[es:ecx*1 + esp] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[es:ecx*4 -1 + ebx]"), 1, "[es:ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[es:ecx*4 +-1 + ebx]"), 1, "[es:ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[es:ecx*8 +44 + ebx]"), 1, "[es:ecx*2 +44+ ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[es:ecx*4 -1 + ebx]"), 1, "[es:ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[es:ecx*4 +-1 + ebx]"), 1, "[es:ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("[ds:ecx*2]"), 1, "[ds:ecx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ds:esp*1]"), 1, "[ds:esp*1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ds:esp*4]"), 0, "[ds:esp*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ds:ecx*2 + ebx*8]"), 0, "[ds:ecx*2 + ebx*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ds:ecx + esp*2]"), 0, "[ds:ecx + esp*2] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr ("[cs:1+eax]"), 1, "[cs:1+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[cs:-2+edx]"), 1, "[cs:-2+edx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[cs:3+ebx*2]"), 1, "[cs:3+ebx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[cs:-4+esi*4]"), 1, "[cs:-4+esi*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[cs:5+ecx+esi]"), 1, "[cs:5+ecx+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[cs:-6+ecx*2+edi]"), 1, "[cs:-6+ecx*2+edi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[cs:7+esp+ebp*8]"), 1, "[cs:7+esp+ebp*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[cs:-8+esp+ebp*8]"), 1, "[cs:-8+esp+ebp*8] is a valid 32-bit addressing scheme" );

# -----------

is ( is_valid_32bit_addr ("[cr0+1]"), 0, "[cr0+1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[eax+cr0+1]"), 0, "[eax+cr0+1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[cr0+ebx*2+2]"), 0, "[cr0+ebx*2+2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[st7-1]"), 0, "[st7-1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[dr2-2+eax]"), 0, "[dr2-2+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[xmm3]"), 0, "[xmm3] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[mm2]"), 0, "[mm2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[eax+xmm3]"), 0, "[eax+xmm3] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[eax+mm2]"), 0, "[eax+mm2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[eax+ebx*2+xmm3]"), 0, "[eax+ebx*2+xmm3] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[eax+ebx*2+mm2]"), 0, "[eax+ebx*2+mm2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[eax-ebx]"), 0, "[eax-ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[eax-ebx*2]"), 0, "[eax-ebx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[eax+3-ecx]"), 0, "[eax+3-ecx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[eax+6*2+esp]"), 1, "[eax+6*2+esp] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[eax+2*ebx]"), 1, "[eax+2*ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[4*eax+esi]"), 1, "[4*eax+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[-1+4*eax+esi]"), 1, "[-1+4*eax+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[r12d+eax]"), 0, "[r12d+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[ebx+2*r8d]"), 0, "[ebx+2*r8d] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr ("[edx+8*r9d+1]"), 0, "[edx+8*r9d+1] is a valid 32-bit addressing scheme" );

# ----------- 64-bit

is ( is_valid_64bit_addr ("[rax]"), 1, "[rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[brax]"), 1, "[brax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[raxd]"), 1, "[raxd] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("[rbx+77]"), 1, "[rbx+77] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rbx+rcx]"), 1, "[rbx+rcx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rbx+rbx+99]"), 1, "[rbx+rbx+99] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rbx+rdi-88]"), 1, "[rbx+rdi-88] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rbx+rdi+-88]"), 1, "[rbx+rdi+-88] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("[rbx+rax*2]"), 1, "[rbx+rax*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rbx+rsi*4+66]"), 1, "[rbx+rsi*4+66] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rbx+rcx*8-55]"), 1, "[rbx+rcx*8-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rbx+rcx*8+-55]"), 1, "[rbx+rcx*8+-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rbx+rbp*1]"), 1, "[rbx+rbp*1] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("[rcx*2 + rbx]"), 1, "[rcx*2 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rcx*4 + rbx -1]"), 1, "[rcx*4 + rbx -1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rcx*4 + rbx +-1]"), 1, "[rcx*4 + rbx +-1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rcx*8 + rbx+ 44]"), 1, "[rcx*2 + rbx+ 44] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rcx*1 + rsp]"), 1, "[rcx*1 + rsp] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rcx*4 -1 + rbx]"), 1, "[rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rcx*4 +-1 + rbx]"), 1, "[rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rcx*8 +44 + rbx]"), 1, "[rcx*2 +44+ rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rcx*4 -1 + rbx]"), 1, "[rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rcx*4 +-1 + rbx]"), 1, "[rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("[rcx*2]"), 1, "[rcx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rsp*1]"), 1, "[rsp*1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rsp*4]"), 0, "[rsp*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rcx*2 + rbx*8]"), 0, "[rcx*2 + rbx*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rcx + rsp*2]"), 0, "[rcx + rsp*2] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("[1+rax]"), 1, "[1+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[-2+rdx]"), 1, "[-2+rdx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[3+rbx*2]"), 1, "[3+rbx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[-4+rsi*4]"), 1, "[-4+rsi*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[5+rcx+rsi]"), 1, "[5+rcx+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[-6+rcx*2+rdi]"), 1, "[-6+rcx*2+rdi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[7+rsp+rbp*8]"), 1, "[7+rsp+rbp*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[-8+rsp+rbp*8]"), 1, "[-8+rsp+rbp*8] is a valid 64-bit addressing scheme" );

# -----------

is ( is_valid_64bit_addr ("cs:[rax]"), 1, "cs:[rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("cs:[brax]"), 1, "cs:[brax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("cs:[raxd]"), 1, "cs:[raxd] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("ds:[rbx+77]"), 1, "ds:[rbx+77] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("ds:[rbx+rcx]"), 1, "ds:[rbx+rcx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("ds:[rbx+rbx+99]"), 1, "ds:[rbx+rbx+99] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("ds:[rbx+rdi-88]"), 1, "ds:[rbx+rdi-88] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("ds:[rbx+rdi+-88]"), 1, "ds:[rbx+rdi+-88] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("es:[rbx+rax*2]"), 1, "es:[rbx+rax*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("es:[rbx+rsi*4+66]"), 1, "es:[rbx+rsi*4+66] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("es:[rbx+rcx*8-55]"), 1, "es:[rbx+rcx*8-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("es:[rbx+rcx*8+-55]"), 1, "es:[rbx+rcx*8+-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("es:[rbx+rbp*1]"), 1, "es:[rbx+rbp*1] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("fs:[rcx*2 + rbx]"), 1, "fs:[rcx*2 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("fs:[rcx*4 + rbx -1]"), 1, "fs:[rcx*4 + rbx -1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("fs:[rcx*4 + rbx +-1]"), 1, "fs:[rcx*4 + rbx +-1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("fs:[rcx*8 + rbx+ 44]"), 1, "fs:[rcx*2 + rbx+ 44] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("fs:[rcx*1 + rsp]"), 1, "fs:[rcx*1 + rsp] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("fs:[rcx*4 -1 + rbx]"), 1, "fs:[rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("fs:[rcx*4 +-1 + rbx]"), 1, "fs:[rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("fs:[rcx*8 +44 + rbx]"), 1, "fs:[rcx*2 +44+ rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("fs:[rcx*4 -1 + rbx]"), 1, "fs:[rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("fs:[rcx*4 +-1 + rbx]"), 1, "fs:[rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("gs:[rcx*2]"), 1, "gs:[rcx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("gs:[rsp*1]"), 1, "gs:[rsp*1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("gs:[rsp*4]"), 0, "gs:[rsp*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("gs:[rcx*2 + rbx*8]"), 0, "gs:[rcx*2 + rbx*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("gs:[rcx + rsp*2]"), 0, "gs:[rcx + rsp*2] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("ss:[1+rax]"), 1, "ss:[1+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("ss:[-2+rdx]"), 1, "ss:[-2+rdx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("ss:[3+rbx*2]"), 1, "ss:[3+rbx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("ss:[-4+rsi*4]"), 1, "ss:[-4+rsi*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("ss:[5+rcx+rsi]"), 1, "ss:[5+rcx+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("ss:[-6+rcx*2+rdi]"), 1, "ss:[-6+rcx*2+rdi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("ss:[7+rsp+rbp*8]"), 1, "ss:[7+rsp+rbp*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("ss:[-8+rsp+rbp*8]"), 1, "ss:[-8+rsp+rbp*8] is a valid 64-bit addressing scheme" );

# -----------

is ( is_valid_64bit_addr ("[ss:rax]"), 1, "[ss:rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[ss:brax]"), 1, "[ss:brax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[ss:raxd]"), 1, "[ss:raxd] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("[gs:rbx+77]"), 1, "[gs:rbx+77] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[gs:rbx+rcx]"), 1, "[gs:rbx+rcx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[gs:rbx+rbx+99]"), 1, "[gs:rbx+rbx+99] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[gs:rbx+rdi-88]"), 1, "[gs:rbx+rdi-88] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[gs:rbx+rdi+-88]"), 1, "[gs:rbx+rdi+-88] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("[fs:rbx+rax*2]"), 1, "[fs:rbx+rax*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[fs:rbx+rsi*4+66]"), 1, "[fs:rbx+rsi*4+66] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[fs:rbx+rcx*8-55]"), 1, "[fs:rbx+rcx*8-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[fs:rbx+rcx*8+-55]"), 1, "[fs:rbx+rcx*8+-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[fs:rbx+rbp*1]"), 1, "[fs:rbx+rbp*1] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("[es:rcx*2 + rbx]"), 1, "[es:rcx*2 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[es:rcx*4 + rbx -1]"), 1, "[es:rcx*4 + rbx -1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[es:rcx*4 + rbx +-1]"), 1, "[es:rcx*4 + rbx +-1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[es:rcx*8 + rbx+ 44]"), 1, "[es:rcx*2 + rbx+ 44] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[es:rcx*1 + rsp]"), 1, "[es:rcx*1 + rsp] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[es:rcx*4 -1 + rbx]"), 1, "[es:rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[es:rcx*4 +-1 + rbx]"), 1, "[es:rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[es:rcx*8 +44 + rbx]"), 1, "[es:rcx*2 +44+ rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[es:rcx*4 -1 + rbx]"), 1, "[es:rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[es:rcx*4 +-1 + rbx]"), 1, "[es:rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("[ds:rcx*2]"), 1, "[ds:rcx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[ds:rsp*1]"), 1, "[ds:rsp*1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[ds:rsp*4]"), 0, "[ds:rsp*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[ds:rcx*2 + rbx*8]"), 0, "[ds:rcx*2 + rbx*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[ds:rcx + rsp*2]"), 0, "[ds:rcx + rsp*2] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr ("[cs:1+rax]"), 1, "[cs:1+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[cs:-2+rdx]"), 1, "[cs:-2+rdx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[cs:3+rbx*2]"), 1, "[cs:3+rbx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[cs:-4+rsi*4]"), 1, "[cs:-4+rsi*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[cs:5+rcx+rsi]"), 1, "[cs:5+rcx+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[cs:-6+rcx*2+rdi]"), 1, "[cs:-6+rcx*2+rdi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[cs:7+rsp+rbp*8]"), 1, "[cs:7+rsp+rbp*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[cs:-8+rsp+rbp*8]"), 1, "[cs:-8+rsp+rbp*8] is a valid 64-bit addressing scheme" );

# -----------

is ( is_valid_64bit_addr ("[cr0+1]"), 0, "[cr0+1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rax+cr0+1]"), 0, "[rax+cr0+1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[cr0+rbx*2+2]"), 0, "[cr0+rbx*2+2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[st7-1]"), 0, "[st7-1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[dr2-2+rax]"), 0, "[dr2-2+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[xmm3]"), 0, "[xmm3] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[mm2]"), 0, "[mm2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rax+xmm3]"), 0, "[rax+xmm3] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rax+mm2]"), 0, "[rax+mm2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rax+rbx*2+xmm3]"), 0, "[rax+rbx*2+xmm3] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rax+rbx*2+mm2]"), 0, "[rax+rbx*2+mm2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rax-rbx]"), 0, "[rax-rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rax-rbx*2]"), 0, "[rax-rbx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rax+3-rcx]"), 0, "[rax+3-rcx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rax+6*2+rsp]"), 1, "[rax+6*2+rsp] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rax+2*rbx]"), 1, "[rax+2*rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[4*rax+rsi]"), 1, "[4*rax+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[-1+4*rax+rsi]"), 1, "[-1+4*rax+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[r12d+rax]"), 0, "[r12d+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rbx+2*r8d]"), 0, "[rbx+2*r8d] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[rdx+8*r9d+1]"), 0, "[rdx+8*r9d+1] is a valid 64-bit addressing scheme" );
# the extra 3:
is ( is_valid_64bit_addr ("[ebx+r10d]"), 1, "[ebx+r10d] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[ebx+2*r8d]"), 1, "[ebx+2*r8d] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr ("[edx+8*r9d+1]"), 1, "[edx+8*r9d+1] is a valid 64-bit addressing scheme" );

# ----------- mixed

is ( is_valid_addr ("[ebx+ax]"), 0, "[ebx+ax] is a valid addressing scheme" );
is ( is_valid_addr ("[si+eax]"), 0, "[si+eax] is a valid addressing scheme" );
is ( is_valid_addr ("[ebx+2+ax]"), 0, "[ebx+2+ax] is a valid addressing scheme" );
is ( is_valid_addr ("[2*ebx-cx]"), 0, "[2*ebx-cx] is a valid addressing scheme" );
is ( is_valid_addr ("[esi*8+si]"), 0, "[esi*8+si] is a valid addressing scheme" );
is ( is_valid_addr ("[edi+sp]"), 0, "[edi+sp] is a valid addressing scheme" );

is ( is_valid_addr ("[rax+ebx]"), 0, "[rax+ebx] is a valid addressing scheme" );
is ( is_valid_addr ("[rbx+r8d]"), 0, "[rbx+r8d] is a valid addressing scheme" );
is ( is_valid_addr ("[ecx+rsi]"), 0, "[ecx+rsi] is a valid addressing scheme" );
is ( is_valid_addr ("[ecx*2+rsi]"), 0, "[ecx*2+rsi] is a valid addressing scheme" );
is ( is_valid_addr ("[+-1+ecx+edx]"), 1, "[+-1+ecx+edx] is a valid addressing scheme" );
is ( is_valid_addr ("[+-1+ecx+rdx]"), 0, "[+-1+ecx+rdx] is a valid addressing scheme" );
is ( is_valid_addr ("[+-1+ecx*8+rdx]"), 0, "[+-1+ecx*8+rdx] is a valid addressing scheme" );
is ( is_valid_addr ("[+-1+rdx+ecx*8]"), 0, "[+-1+rdx+ecx*8] is a valid  addressing scheme" );
is ( is_valid_addr ("[esi+-1+rax]"), 0, "[esi+-1+rax] is a valid  addressing scheme" );
is ( is_valid_addr ("[esi-rcx]"), 0, "[esi-rcx] is a valid  addressing scheme" );
is ( is_valid_addr ("[+1-rcx]"), 0, "[+1-rcx] is a valid  addressing scheme" );
is ( is_valid_addr ("[-1-rcx]"), 0, "[-1-rcx] is a valid  addressing scheme" );

is ( is_valid_addr ("[rax+6*2+rsp]"), 1, "[rax+6*2+rsp] is a valid addressing scheme" );
is ( is_valid_addr ("[cs:5+ecx+esi]"), 1, "[cs:5+ecx+esi] is a valid addressing scheme" );
is ( is_valid_addr ("[ss:bp+si]"), 1, "[ss:bp+si] is a valid addressing scheme" );

#is ( is_valid_addr ("[]"), 0, "[] is a valid addressing scheme" );
