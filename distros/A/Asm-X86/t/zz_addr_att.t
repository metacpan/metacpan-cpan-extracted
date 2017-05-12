#!perl -T -w

use strict;
use warnings;

use Test::More tests => (5*4*2 + 34) + (14*2 + 20) + (14*2 + 21) + 24;
use Asm::X86 qw(is_valid_16bit_addr_att is_valid_32bit_addr_att
	is_valid_64bit_addr_att is_valid_addr_att);

# ----------- 16-bit

is ( is_valid_16bit_addr_att ("(\%bX)"), 1, "(bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%sI)"), 1, "(si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%Di)"), 1, "(di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%Bp)"), 1, "(bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("(\%bx,\%bx)"), 0, "(bx,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%bx,\%Si)"), 1, "(bx,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%bX,\%di)"), 1, "(bx,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%bx,\%bp)"), 0, "(bx,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("(\%sI,\%bx)"), 1, "(si,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%si,\%si)"), 0, "(si,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%si,\%dI)"), 0, "(si,dI) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%si,\%bP)"), 1, "(si,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("(\%di,\%Bx)"), 1, "(di,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%di,\%Si)"), 0, "(di,Si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%di,\%di)"), 0, "(di,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%Di,\%bp)"), 1, "(di,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("(\%bp,\%bX)"), 0, "(bp,bX) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%bP,\%si)"), 1, "(bp,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%bp,\%Di)"), 1, "(bp,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%bp,\%bP)"), 0, "(bp,bP) is a valid 16-bit addressing scheme" );

# -----------

is ( is_valid_16bit_addr_att ("\%cs:(\%bx)"), 1, "cs:(bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%cs:(\%si)"), 1, "cs:(si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%cs:(\%di)"), 1, "cs:(di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%cs:(\%bp)"), 1, "cs:(bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("\%ds:(\%bx,\%bx)"), 0, "ds:(bx,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ds:(\%bx,\%si)"), 1, "ds:(bx,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ds:(\%bx,\%di)"), 1, "ds:(bx,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ds:(\%bx,\%bp)"), 0, "ds:(bx,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("\%es:(\%si,\%bx)"), 1, "es:(si,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%es:(\%si,\%si)"), 0, "es:(si,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%es:(\%si,\%dI)"), 0, "es:(si,dI) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%es:(\%si,\%bp)"), 1, "es:(si,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("\%fs:(\%di,\%bx)"), 1, "fs:(di,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%fs:(\%di,\%Si)"), 0, "fs:(di,Si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%gs:(\%di,\%di)"), 0, "gs:(di,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%gs:(\%di,\%bp)"), 1, "gs:(di,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("\%ss:(\%bp,\%bX)"), 0, "ss:(bp,bX) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ss:(\%bp,\%si)"), 1, "ss:(bp,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ss:(\%bp,\%di)"), 1, "ss:(bp,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ss:(\%bp,\%bP)"), 0, "ss:(bp,bP) is a valid 16-bit addressing scheme" );


# -----------

is ( is_valid_16bit_addr_att ("(\%ax)"), 0, "(ax) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%bx,\%cx)"), 0, "(bx,cx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%cx,\%bx)"), 0, "(cx,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%bp,\%al)"), 0, "(bp,al) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%ch,\%si)"), 0, "(ch,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%bx-\%si)"), 0, "(bx-si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("-2(\%bp)"), 1, "-2(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("-varname(\%bp)"), 1, "-varname(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%si-\%ax)"), 0, "(si-ax) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("+-2(\%bp)"), 1, "+-2(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("-si(\%bp)"), 1, "-si(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ad:(\%bx)"), 0, "ad:(bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%sc:\%di)"), 0, "(sc:di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(2,\%bp)"), 0, "(2,bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("-3(\%si)"), 1, "-3(si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(,,-3,\%si)"), 0, "(,,-3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(3-\%si)"), 0, "(3-si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(--3,\%si)"), 0, "(--3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(-3-\%si)"), 0, "(-3-si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(3,5)"), 0, "(3,5) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(-3)"), 1, "(-3) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(-3,2)"), 0, "(-3,2) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(,2)"), 0, "(,2) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("\%(cs:--3,si)"), 0, "(cs:--3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%cs:(--3,si)"), 0, "cs:(--3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ds:(,2)"), 0, "ds:(,2) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%ds:,2)"), 0, "(ds:,2) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ss:(-3)"), 1, "ss:(-3) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%ss:-3,2)"), 0, "(ss:-3,2) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%es:2,bp)"), 0, "(es:2,bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%eS:(2,bp)"), 0, "es:(2,bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%fs:(,,-3,si)"), 0, "fs:(,,-3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%fs:,,-3,si)"), 0, "(fs:,,-3,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(,1)"), 1, "zzz(,1) is a valid 16-bit addressing scheme" );

# ----------- 32-bit

is ( is_valid_32bit_addr_att ('zzz(,1)'), 1, 'zzz(,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax)'), 1, '(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('1(%eax)'), 1, '1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-1(%eax)'), 1, '-1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax, %ebx)'), 1, '(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('2(%eax, %ebx)'), 1, '2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-2(%eax, %ebx)'), 1, '-2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax, %ebx, 1)'), 1, '(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('3( %eax, %ebx, 2)'), 1, '3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-9(%eax, %ebx, 4)'), 1, '-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(, %ebx, 8)'), 1, '(, %ebx, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('7(, %ecx, 4)'), 1, '7(, %ecx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-7(, %edx, 2)'), 1, '-7(, %edx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('11(,1)'), 1, '11(,1) is a valid 32-bit addressing scheme' );

# -----------

is ( is_valid_32bit_addr_att ('%cs:zzz(,1)'), 1, '%cs:zzz(,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:(%eax)'), 1, '%ds:(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%es:1(%eax)'), 1, '%es:1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%fs:-1(%eax)'), 1, '-%fs:1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%gs:(%eax, %ebx)'), 1, '%gs:(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ss:2(%eax, %ebx)'), 1, '%ss:2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:-2(%eax, %ebx)'), 1, '%cs:-2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:(%eax, %ebx, 1)'), 1, '%ds:(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%es:3( %eax, %ebx, 2)'), 1, '%es:3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%fs:-9(%eax, %ebx, 4)'), 1, '%fs:-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%gs:(, %ebx, 8)'), 1, '%gs:(, %ebx, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ss:7(, %ecx, 4)'), 1, '%ss:7(, %ecx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:-7(, %edx, 2)'), 1, '%cs:-7(, %edx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:11(,1)'), 1, '%ds:11(,1) is a valid 32-bit addressing scheme' );

# -----------

is ( is_valid_32bit_addr_att ('1(%cr0)'), 0, '1(%cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('1(%eax, %cr0)'), 0, '1(%eax, %cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('2(%cr0, %ebx, 2)'), 0, '2(%cr0, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-1(%st7)'), 0, '-1(%st7) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-2(%eax, %dr0)'), 0, '-2(%eax, %dr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%xmm3)'), 0, '(%xmm3) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%mm2)'), 0, '(%mm2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax, %xmm5)'), 0, '(%eax, %xmm5) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%ebx, %mm2)'), 0, '(%ebx, %mm2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%eax(%ebx)'), 0, '%eax(%ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-%eax(%ebx)'), 0, '-%eax(%ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('3(-%esi)'), 0, '3(-%esi) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax, %r12d)'), 0, '(%eax, %r12d) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%ebx, %r12d, 2)'), 0, '(%ebx, %r12d, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax, -%ebx)'), 0, '(%eax, -%ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax, -%ebx, 4)'), 0, '(%eax, -%ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(,%esp, 2)'), 0, '(,%esp, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax ,%esp, 2)'), 0, '(%eax ,%esp, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax -, %ebx)'), 0, '(%eax -, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax -, %ebx, 4)'), 0, '(%eax -, %ebx, 4) is a valid 32-bit addressing scheme' );


# ----------- 64-bit

is ( is_valid_64bit_addr_att ('zzz(,1)'), 1, 'zzz(,1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax)'), 1, '(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax)'), 1, '1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-1(%rax)'), 1, '-1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, %rbx)'), 1, '(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%rax, %rbx)'), 1, '2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-2(%rax, %rbx)'), 1, '-2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, %rbx, 1)'), 1, '(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('3( %rax, %rbx, 2)'), 1, '3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-9(%rax, %rbx, 4)'), 1, '-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, %rbx, 8)'), 1, '(, %rbx, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('7(, %rcx, 4)'), 1, '7(, %rcx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-7(, %rdx, 2)'), 1, '-7(, %rdx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('11(,1)'), 1, '11(,1) is a valid 64-bit addressing scheme' );

# -----------

is ( is_valid_64bit_addr_att ('%cs:zzz(,1)'), 1, '%cs:zzz(,1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax)'), 1, '%ds:(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%es:1(%rax)'), 1, '%es:1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%fs:-1(%rax)'), 1, '%fs:-1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%gs:(%rax, %rbx)'), 1, '%gs:(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ss:2(%rax, %rbx)'), 1, '%ss:2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:-2(%rax, %rbx)'), 1, '%cs:-2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %rbx, 1)'), 1, '%ds:(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%es:3( %rax, %rbx, 2)'), 1, '%es:3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%fs:-9(%rax, %rbx, 4)'), 1, '%fs:-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%gs:(, %rbx, 8)'), 1, '%gs:(, %rbx, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ss:7(, %rcx, 4)'), 1, '%ss:7(, %rcx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:-7(, %rdx, 2)'), 1, '%cs:-7(, %rdx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:11(,1)'), 1, '%ds:11(,1) is a valid 64-bit addressing scheme' );

# -----------

is ( is_valid_64bit_addr_att ('1(%cr0)'), 0, '1(%cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax, %cr0)'), 0, '1(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%cr0, %rbx, 2)'), 0, '2(%cr0, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-1(%st7)'), 0, '-1(%st7) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-2(%rax, %dr0)'), 0, '-2(%rax, %dr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%xmm3)'), 0, '(%xmm3) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%mm2)'), 0, '(%mm2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, %xmm5)'), 0, '(%rax, %xmm5) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rbx, %mm2)'), 0, '(%rbx, %mm2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%rax(%rbx)'), 0, '%rax(%rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-%rax(%rbx)'), 0, '-%rax(%rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('3(-%rsi)'), 0, '3(-%rsi) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, %r12d)'), 0, '(%rax, %r12d) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rbx, %r12d, 2)'), 0, '(%rbx, %r12d, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, -%rbx)'), 0, '(%rax, -%rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, -%rbx, 4)'), 0, '(%rax, -%rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(,%rsp, 2)'), 0, '(,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax ,%rsp, 2)'), 0, '(%rax ,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax ,%rip, 2)'), 0, '(%rax ,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax -, %rbx)'), 0, '(%rax -, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax -, %rbx, 4)'), 0, '(%rax -, %rbx, 4) is a valid 64-bit addressing scheme' );

# ----------- mixed

is ( is_valid_addr_att ('(%ebx, %ax)'), 0, '(%ebx, %ax) is a valid addressing scheme' );
is ( is_valid_addr_att ('(%si, %eax)'), 0, '(%si, %eax) is a valid addressing scheme' );
is ( is_valid_addr_att ('2(%ebx,%ax)'), 0, '2(%ebx,%ax) is a valid addressing scheme' );
is ( is_valid_addr_att ('(-%cx,%ebx,2)'), 0, '(-%cx,%ebx,2) is a valid addressing scheme' );
is ( is_valid_addr_att ('(%si,%esi,8)'), 0, '(%si,%esi,8) is a valid addressing scheme' );
is ( is_valid_addr_att ('(%edi,%sp)'), 0, '(%edi,%sp) is a valid addressing scheme' );

is ( is_valid_addr_att ('(%rax,%ebx)'), 0, '(%rax,%ebx) is a valid addressing scheme' );
is ( is_valid_addr_att ('(%rbx,%r8d)'), 0, '(%rbx,%r8d) is a valid addressing scheme' );
is ( is_valid_addr_att ('(%ecx,%rsi)'), 0, '(%ecx,%rsi) is a valid addressing scheme' );
is ( is_valid_addr_att ('(%rsi,%ecx,2)'), 0, '(%rsi,%ecx,2) is a valid addressing scheme' );
is ( is_valid_addr_att ('+-1(%ecx,%edx)'), 1, '+-1(%ecx,%edx) is a valid addressing scheme' );
is ( is_valid_addr_att ('+-1(%ecx,%rdx)'), 0, '+-1(%ecx,%rdx) is a valid addressing scheme' );
is ( is_valid_addr_att ('+-1(%rdx,%ecx,8)'), 0, '+-1(%edx,%ecx,8) is a valid addressing scheme' );
is ( is_valid_addr_att ('+-1(%rdx,%ecx,8)'), 0, '+-1(%rdx,%rcx,8) is a valid addressing scheme' );
is ( is_valid_addr_att ('-1(%esi,%rax)'), 0, '-1(%esi,%rax) is a valid addressing scheme' );
is ( is_valid_addr_att ('-%rcx(%esi)'), 0, '-%rcx(%esi) is a valid addressing scheme' );
is ( is_valid_addr_att ('(-%rcx, %esi)'), 0, '(-%rcx, %esi) is a valid addressing scheme' );
is ( is_valid_addr_att ('(%esi, -%rcx)'), 0, '(%esi, -%rcx) is a valid addressing scheme' );
is ( is_valid_addr_att ('-%rcx(,1)'), 0, '-%rcx(,1) is a valid addressing scheme' );
is ( is_valid_addr_att ('-1(-%rcx)'), 0, '-1(-%rcx) is a valid addressing scheme' );
is ( is_valid_addr_att ('1(-%rcx)'), 0, '1(-%rcx) is a valid addressing scheme' );
is ( is_valid_addr_att ('12(%rax,%rsp)'), 1, '12(%rax,%rsp) is a valid addressing scheme' );
is ( is_valid_addr_att ('%cs:5(%ecx,%esi)'), 1, '%cs:5(%ecx,%esi) is a valid addressing scheme' );
is ( is_valid_addr_att ('%ss:(%bp,%si)'), 1, '%ss:(%bp,%si) is a valid addressing scheme' );

#is ( is_valid_64bit_addr_att ('()'), 0, ' is a valid 64-bit addressing scheme' );
