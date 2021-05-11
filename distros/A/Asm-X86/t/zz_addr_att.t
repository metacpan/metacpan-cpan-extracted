#!perl -T -w

use strict;
use warnings;

use Test::More tests => 1262; # (5*4*2 + 34) + (14*2 + 20) + (14*2 + 21) + 24;
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

is ( is_valid_16bit_addr_att ("zzz(\%bX)"), 1, "zzz(bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%sI)"), 1, "zzz(si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%Di)"), 1, "zzz(di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%Bp)"), 1, "zzz(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ('%cx(%Bp)'), 0, 'cx(bp) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ("zzz(\%bx,\%bx)"), 0, "zzz(bx,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%bx,\%Si)"), 1, "zzz(bx,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%bX,\%di)"), 1, "zzz(bx,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%bx,\%bp)"), 0, "zzz(bx,bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ('%cx(%bx, %si)'), 0, 'cx(bx,si) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ("zzz(\%sI,\%bx)"), 1, "zzz(si,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%si,\%si)"), 0, "zzz(si,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%si,\%dI)"), 0, "zzz(si,dI) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%si,\%bP)"), 1, "zzz(si,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("zzz(\%di,\%Bx)"), 1, "zzz(di,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%di,\%Si)"), 0, "zzz(di,Si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%di,\%di)"), 0, "zzz(di,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%Di,\%bp)"), 1, "zzz(di,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("zzz(\%bp,\%bX)"), 0, "zzz(bp,bX) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%bP,\%si)"), 1, "zzz(bp,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%bp,\%Di)"), 1, "zzz(bp,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%bp,\%bP)"), 0, "zzz(bp,bP) is a valid 16-bit addressing scheme" );

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

is ( is_valid_16bit_addr_att ("\%cs:zzz(\%bx)"), 1, "cs:zzz(bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%cs:zzz(\%si)"), 1, "cs:zzz(si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%cs:zzz(\%di)"), 1, "cs:zzz(di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%cs:zzz(\%bp)"), 1, "cs:zzz(bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ('%cs:%cx(%Bp)'), 0, 'cs:cx(bp) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ("\%ds:zzz(\%bx,\%bx)"), 0, "ds:zzz(bx,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ds:zzz(\%bx,\%si)"), 1, "ds:zzz(bx,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ds:zzz(\%bx,\%di)"), 1, "ds:zzz(bx,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ds:zzz(\%bx,\%bp)"), 0, "ds:zzz(bx,bp) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ('%ds:%cx(%bx, %si)'), 0, '%ds:cx(bx,si) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ("\%es:zzz(\%si,\%bx)"), 1, "es:zzz(si,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%es:zzz(\%si,\%si)"), 0, "es:zzz(si,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%es:zzz(\%si,\%dI)"), 0, "es:zzz(si,dI) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%es:zzz(\%si,\%bp)"), 1, "es:zzz(si,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("\%fs:zzz(\%di,\%bx)"), 1, "fs:zzz(di,bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%fs:zzz(\%di,\%Si)"), 0, "fs:zzz(di,Si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%gs:zzz(\%di,\%di)"), 0, "gs:zzz(di,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%gs:zzz(\%di,\%bp)"), 1, "gs:zzz(di,bp) is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_att ("\%ss:zzz(\%bp,\%bX)"), 0, "ss:zzz(bp,bX) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ss:zzz(\%bp,\%si)"), 1, "ss:zzz(bp,si) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ss:zzz(\%bp,\%di)"), 1, "ss:zzz(bp,di) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("\%ss:zzz(\%bp,\%bP)"), 0, "ss:zzz(bp,bP) is a valid 16-bit addressing scheme" );

# -----------

is ( is_valid_16bit_addr_att ("(\%ax)"), 0, "(ax) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(\%eax)"), 0, "(eax) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("(-\%bx)"), 0, "(-bx) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(\%eax)"), 0, "zzz(eax) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(-\%bx)"), 0, "zzz(-bx) is a valid 16-bit addressing scheme" );
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
is ( is_valid_16bit_addr_att ("zzz(yyy)"), 0, "zzz(yyy) is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_att ("zzz(-yyy)"), 0, "zzz(-yyy) is a valid 16-bit addressing scheme" );

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
is ( is_valid_16bit_addr_att ('%cx(,1)'), 0, 'cx(,1) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:zzz(,1)'), 1, '%fs:zzz(,1) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:%cx(,1)'), 0, '%fs:cx(,1) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%ax:%cx(,1)'), 0, '%ax:cx(,1) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%ax:zzz(,1)'), 0, '%ax:zzz(,1) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:zzz(,%cs)'), 0, '%fs:zzz(,%cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:zzz(,%cx)'), 0, '%fs:zzz(,%cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%ax:zzz(,%cx)'), 0, '%ax:zzz(,%cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:zzz(,-%cx)'), 0, '%fs:zzz(,-%cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:zzz(,%ecx)'), 0, '%fs:zzz(,%ecx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:zzz(1)'), 1, '%fs:zzz(1) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:zzz(%cs)'), 0, '%fs:zzz(%cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:zzz(%cx)'), 0, '%fs:zzz(%cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%ax:zzz(%cx)'), 0, '%ax:zzz(%cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:zzz(-%cx)'), 0, '%fs:zzz(-%cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:zzz(%ecx)'), 0, '%fs:zzz(%cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:zzz(%bx)'), 1, '%fs:zzz(%bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:zzz(%si)'), 1, '%fs:zzz(%si) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%fs:zzz(-%si)'), 0, '%fs:zzz(-%si) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ('(%cs)'), 0, '(cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%cs,%bx)'), 0, '(cs,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%cs,2)'), 0, '(cs,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%bx,%cs)'), 0, '(bx,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(2,%cs)'), 0, '(2,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%cs,%bx,2)'), 0, '(cs,bx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%bx,%cs,2)'), 0, '(bx,cs,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%cs,2,%bx)'), 0, '(cs,2,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%bx,2,%cs)'), 0, '(bx,2,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(2,%cs,%bx)'), 0, '(2,cs,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(2,%bx,%cs)'), 0, '(2,bx,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(,%bx,2)'), 0, '(,bx,2) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ('(%cx)'), 0, '(cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%cx,%bx)'), 0, '(cx,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%cx,2)'), 0, '(cx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%bx,%cx)'), 0, '(bx,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(2,%cx)'), 0, '(2,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%cx,%bx,2)'), 0, '(cx,bx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%bx,%cx,2)'), 0, '(bx,cx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%cx,2,%bx)'), 0, '(cx,2,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(%bx,2,%cx)'), 0, '(bx,2,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(2,%cx,%bx)'), 0, '(2,cx,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('(2,%bx,%cx)'), 0, '(2,bx,cx) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ('zzz(%cs)'), 0, '(cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%cs,%bx)'), 0, '(cs,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%cs,2)'), 0, '(cs,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%bx,%cs)'), 0, '(bx,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(2,%cs)'), 0, '(2,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%cs,%bx,2)'), 0, '(cs,bx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%bx,%cs,2)'), 0, '(bx,cs,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%cs,2,%bx)'), 0, '(cs,2,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%bx,2,%cs)'), 0, '(bx,2,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(2,%cs,%bx)'), 0, '(2,cs,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(2,%bx,%cs)'), 0, '(2,bx,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(,%bx,2)'), 0, 'zzz(,bx,2) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ('zzz(%cx)'), 0, '(cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%cx,%bx)'), 0, '(cx,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%cx,%si)'), 0, 'zzz(cx,si) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%cx,2)'), 0, '(cx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%bx,%cx)'), 0, '(bx,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%si,%cx)'), 0, 'zzz(si,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(2,%cx)'), 0, '(2,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%cx,%bx,2)'), 0, '(cx,bx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%bx,%cx,2)'), 0, '(bx,cx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%cx,2,%bx)'), 0, '(cx,2,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(%bx,2,%cx)'), 0, '(bx,2,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(2,%cx,%bx)'), 0, '(2,cx,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('zzz(2,%bx,%cx)'), 0, '(2,bx,cx) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ('%cs:(%cs)'), 0, '%cs:(cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%cs,%bx)'), 0, '%cs:(cs,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%cs,2)'), 0, '%cs:(cs,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%bx,%cs)'), 0, '%cs:(bx,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(2,%cs)'), 0, '%cs:(2,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%cs,%bx,2)'), 0, '%cs:(cs,bx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%bx,%cs,2)'), 0, '%cs:(bx,cs,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%cs,2,%bx)'), 0, '%cs:(cs,2,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%bx,2,%cs)'), 0, '%cs:(bx,2,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(2,%cs,%bx)'), 0, '%cs:(2,cs,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(2,%bx,%cs)'), 0, '%cs:(2,bx,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(-%bx)'), 0, '%cs:(-bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(ca)'), 1, '%cs:(ca) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%ecx)'), 0, '%cs:(ecx) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ('%cs:(%cx)'), 0, '%cs:(cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%cx,%bx)'), 0, '%cs:(cx,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%cx,2)'), 0, '%cs:(cx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%bx,%cx)'), 0, '%cs:(bx,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(2,%cx)'), 0, '%cs:(2,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%cx,%bx,2)'), 0, '%cs:(cx,bx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%cx,%si,2)'), 0, '%cs:(cx,si,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%bx,%cx,2)'), 0, '%cs:(bx,cx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%si,%cx,2)'), 0, '%cs:(si,cx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%cx,2,%bx)'), 0, '%cs:(cx,2,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%bx,2,%cx)'), 0, '%cs:(bx,2,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(2,%cx,%bx)'), 0, '%cs:(2,cx,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(2,%bx,%cx)'), 0, '%cs:(2,bx,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(-%cx)'), 0, '%cs:(-cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%ecx,%bx)'), 0, '%cs:(ecx,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(%cx,%ebx)'), 0, '%cs:(cx,ebx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:(,%bx,2)'), 0, '%cs:(,bx,2) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ('%cx:(%cs)'), 0, '%cx:(cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:(%cs,%bx)'), 0, '%cx:(cs,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:(%cs,2)'), 0, '%cx:(cs,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:(%bx,%cs)'), 0, '%cx:(bx,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:(2,%cs)'), 0, '%cx:(2,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:(%cs,%bx,2)'), 0, '%cx:(cs,bx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:(%bx,%cs,2)'), 0, '%cx:(bx,cs,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:(%cs,2,%bx)'), 0, '%cx:(cs,2,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:(%bx,2,%cs)'), 0, '%cx:(bx,2,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:(2,%cs,%bx)'), 0, '%cx:(2,cs,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:(2,%bx,%cs)'), 0, '%cx:(2,bx,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:(-%bx)'), 0, '%cx:(-bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:(ca)'), 0, '%cx:(ca) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ('%cs:zzz(%cs)'), 0, '%cs:zzz(cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%cs,%bx)'), 0, '%cs:zzz(cs,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%cs,2)'), 0, '%cs:zzz(cs,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%bx,%cs)'), 0, '%cs:zzz(bx,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(2,%cs)'), 0, '%cs:zzz(2,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%cs,%bx,2)'), 0, '%cs:zzz(cs,bx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%bx,%cs,2)'), 0, '%cs:zzz(bx,cs,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%cs,2,%bx)'), 0, '%cs:zzz(cs,2,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%bx,2,%cs)'), 0, '%cs:zzz(bx,2,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(2,%cs,%bx)'), 0, '%cs:zzz(2,cs,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(2,%bx,%cs)'), 0, '%cs:zzz(2,bx,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(-%bx)'), 0, '%cs:zzz(-bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(ca)'), 1, '%cs:zzz(ca) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%ecx)'), 0, '%cs:zzz(ecx) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ('%cs:zzz(%cx)'), 0, '%cs:zzz(cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%cx,%bx)'), 0, '%cs:zzz(cx,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%cx,%si)'), 0, '%cs:zzz(cx,si) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%cx,2)'), 0, '%cs:zzz(cx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%bx,%cx)'), 0, '%cs:zzz(bx,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%si,%cx)'), 0, '%cs:zzz(si,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(2,%cx)'), 0, '%cs:zzz(2,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%cx,%bx,2)'), 0, '%cs:zzz(cx,bx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%cx,%si,2)'), 0, '%cs:zzz(cx,si,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%bx,%cx,2)'), 0, '%cs:zzz(bx,cx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%si,%cx,2)'), 0, '%cs:zzz(si,cx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%cx,2,%bx)'), 0, '%cs:zzz(cx,2,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%bx,2,%cx)'), 0, '%cs:zzz(bx,2,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(2,%cx,%bx)'), 0, '%cs:zzz(2,cx,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(2,%bx,%cx)'), 0, '%cs:zzz(2,bx,cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(-%cx)'), 0, '%cs:zzz(-cx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%ecx,%bx)'), 0, '%cs:zzz(ecx,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(%cx,%ebx)'), 0, '%cs:zzz(cx,ebx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cs:zzz(,%bx,2)'), 0, '%cs:zzz(,bx,2) is a valid 16-bit addressing scheme' );

is ( is_valid_16bit_addr_att ('%cx:zzz(%cs)'), 0, '%cx:zzz(cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:zzz(%cs,%bx)'), 0, '%cx:zzz(cs,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:zzz(%cs,2)'), 0, '%cx:zzz(cs,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:zzz(%bx,%cs)'), 0, '%cx:zzz(bx,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:zzz(2,%cs)'), 0, '%cx:zzz(2,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:zzz(%cs,%bx,2)'), 0, '%cx:zzz(cs,bx,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:zzz(%bx,%cs,2)'), 0, '%cx:zzz(bx,cs,2) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:zzz(%cs,2,%bx)'), 0, '%cx:zzz(cs,2,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:zzz(%bx,2,%cs)'), 0, '%cx:zzz(bx,2,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:zzz(2,%cs,%bx)'), 0, '%cx:zzz(2,cs,bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:zzz(2,%bx,%cs)'), 0, '%cx:zzz(2,bx,cs) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:zzz(-%bx)'), 0, '%cx:zzz(-bx) is a valid 16-bit addressing scheme' );
is ( is_valid_16bit_addr_att ('%cx:zzz(ca)'), 0, '%cx:zzz(ca) is a valid 16-bit addressing scheme' );

# ----------- 32-bit

is ( is_valid_32bit_addr_att ('zzz(,1)'), 1, 'zzz(,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax)'), 1, '(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('1(%eax)'), 1, '1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-1(%eax)'), 1, '-1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('7(, %ecx, 4)'), 1, '7(, %ecx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-7(, %edx, 2)'), 1, '-7(, %edx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('11(,1)'), 1, '11(,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx(,1)'), 0, 'cx(,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx(%eax)'), 0, '%cx(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx(%eax, %ebx)'), 0, '%cx(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx(%eax, %ebx, 2)'), 0, '%cx(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%dx(, %ecx, 4)'), 0, '%dx(, %ecx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(zzz)'), 0, 'zzz(zzz) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%eax, %ebx)'), 1, 'zzz(%eax, %ebx) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%cs:(, %ebx, 1)'), 1, '%cs:(, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(, %ebx, 2)'), 1, '%cs:(, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(, %ebx, 4)'), 1, '%cs:(, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(, %ebx, 8)'), 1, '%cs:(, %ebx, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(, %ebx, 5)'), 0, '%cs:(, %ebx, 5) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ax:(, %ebx, 8)'), 0, '%ax:(, %ebx, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(, %ds, 8)'), 0, '%cs:(, %ds, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(, %cr0, 8)'), 0, '%cs:(, %cr0, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(, %esp, 8)'), 0, '%cs:(, %esp, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:%cx(,1)'), 0, '%cs:cx(,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:%cx(%eax)'), 0, '%cs:%cx(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:%cx(%eax, %ebx)'), 0, '%ds:%cx(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:%cx(%eax, %ebx, 2)'), 0, '%ds:%cx(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:%dx(, %ecx, 4)'), 0, '%cs:%dx(, %ecx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:zzz(zzz)'), 0, '%ds:zzz(zzz) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:zzz(%eax, %ebx)'), 1, '%ds:zzz(%eax, %ebx) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('(, %ebx, 1)'), 1, '(, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(, %ebx, 2)'), 1, '(, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(, %ebx, 4)'), 1, '(, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(, %ebx, 8)'), 1, '(, %ebx, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(, %ebx, 5)'), 0, '(, %ebx, 5) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(, %ds, 8)'), 0, '(, %ds, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(, %cr0, 8)'), 0, '(, %cr0, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(, %esp, 8)'), 0, '(, %esp, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(, zzz, 8)'), 0, '(, zzz, 8) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%cs:1(, %ebx, 1)'), 1, '%cs:1(, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:2(, %ebx, 2)'), 1, '%cs:2(, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:3(, %ebx, 4)'), 1, '%cs:3(, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:4(, %ebx, 8)'), 1, '%cs:4(, %ebx, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:5(, %ebx, 5)'), 0, '%cs:5(, %ebx, 5) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ax:6(, %ebx, 8)'), 0, '%ax:6(, %ebx, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:7(, %ds, 8)'), 0, '%cs:7(, %ds, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:8(, %cr0, 8)'), 0, '%cs:8(, %cr0, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:7(, %esp, 8)'), 0, '%cs:7(, %esp, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(, zzz, 8)'), 0, '%cs:(, zzz, 8) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('1(, %ebx, 1)'), 1, '1(, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('2(, %ebx, 2)'), 1, '2(, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('3(, %ebx, 4)'), 1, '3(, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('4(, %ebx, 8)'), 1, '4(, %ebx, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('5(, %ebx, 5)'), 0, '5(, %ebx, 5) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('6(, %ds, 8)'), 0, '6(, %ds, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('7(, %cr0, 8)'), 0, '7(, %cr0, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('6(, %esp, 8)'), 0, '6(, %esp, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('5(, zzz, 8)'), 0, '5(, zzz, 8) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('(%eax, %ebx, 1)'), 1, '(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('3( %eax, %ebx, 2)'), 1, '3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-9(%eax, %ebx, 4)'), 1, '-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax, %cr0, 1)'), 0, '(%eax, %cr0, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('3( %eax, %cr0, 2)'), 0, '3( %eax, %cr0, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-9(%eax, %cr0, 4)'), 0, '-9(%eax, %cr0, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%cr0, %ebx, 1)'), 0, '(%cr0, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('3( %cr0, %ebx, 2)'), 0, '3( %cr0, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-9(%cr0, %ebx, 4)'), 0, '-9(%cr0, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(, zzz, 8)'), 0, 'zzz(, zzz, 8) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('(%eax, %ebx, 2)'), 1, '(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax, %ebx, 4)'), 1, '(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax, %ebx, 8)'), 1, '(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('3( %eax, %ebx, 1)'), 1, '3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-9(%eax, %ebx, 1)'), 1, '-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax, %ebx, 4)'), 1, '(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('3( %eax, %ebx, 4)'), 1, '3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-9(%eax, %ebx, 4)'), 1, '-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax, %ebx, 8)'), 1, '(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('3( %eax, %ebx, 8)'), 1, '3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-9(%eax, %ebx, 8)'), 1, '-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('(%eax, %ebx, 5)'), 0, '(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('3( %eax, %ebx, 5)'), 0, '3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-9(%eax, %ebx, 5)'), 0, '-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('(%eax, %ebx)'), 1, '(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('2(%eax, %ebx)'), 1, '2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-2(%eax, %ebx)'), 1, '-2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%eax, %cr0)'), 0, '(%eax, %cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('2(%eax, %cr0)'), 0, '2(%eax, %cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-2(%eax, %cr0)'), 0, '-2(%eax, %cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%cr0, %ebx)'), 0, '(%cr0, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('2(%cr0, %ebx)'), 0, '2(%cr0, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('-2(%cr0, %ebx)'), 0, '-2(%cr0, %ebx) is a valid 32-bit addressing scheme' );

# -----------

is ( is_valid_32bit_addr_att ('%cs:zzz(,1)'), 1, '%cs:zzz(,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:(%eax)'), 1, '%ds:(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%es:1(%eax)'), 1, '%es:1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%fs:-1(%eax)'), 1, '-%fs:1(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%gs:(, %ebx, 8)'), 1, '%gs:(, %ebx, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ss:7(, %ecx, 4)'), 1, '%ss:7(, %ecx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:-7(, %edx, 2)'), 1, '%cs:-7(, %edx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:11(,1)'), 1, '%ds:11(,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:%cx(,1)'), 0, '%ds:cx(,1) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%ds:(, zzz, 8)'), 0, '%ds:(, zzz, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%fs:5(, zzz, 8)'), 0, '%fs:5(, zzz, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%es:zzz(, zzz, 8)'), 0, '%es:zzz(, zzz, 8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:%cx(%eax)'), 0, '%ds:%cx(%eax) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:%cx(%eax, %ebx)'), 0, '%ds:%cx(%eax, %ebx) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%gs:(%eax, %ebx)'), 1, '%gs:(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ss:2(%eax, %ebx)'), 1, '%ss:2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:-2(%eax, %ebx)'), 1, '%cs:-2(%eax, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%gs:(%eax, %cr0)'), 0, '%gs:(%eax, %cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ss:2(%eax, %cr0)'), 0, '%ss:2(%eax, %cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:-2(%eax, %cr0)'), 0, '%cs:-2(%eax, %cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%gs:(%cr0, %ebx)'), 0, '%gs:(%cr0, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ss:2(%cr0, %ebx)'), 0, '%ss:2(%cr0, %ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:-2(%cr0, %ebx)'), 0, '%cs:-2(%cr0, %ebx) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%ds:(%eax, %ebx, 1)'), 1, '%ds:(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%es:3( %eax, %ebx, 2)'), 1, '%es:3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%fs:-9(%eax, %ebx, 4)'), 1, '%fs:-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:(%eax, %cr0, 1)'), 0, '%ds:(%eax, %cr0, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%es:3( %eax, %cr0, 2)'), 0, '%es:3( %eax, %cr0, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%fs:-9(%eax, %cr0, 4)'), 0, '%fs:-9(%eax, %cr0, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:(%cr0, %ebx, 1)'), 0, '%ds:(%cr0, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%es:3( %cr0, %ebx, 2)'), 0, '%es:3( %cr0, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%fs:-9(%cr0, %ebx, 4)'), 0, '%fs:-9(%cr0, %ebx, 4) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%ds:(%eax, %ebx, 2)'), 1, '%ds:(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:(%eax, %ebx, 4)'), 1, '%ds:(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:(%eax, %ebx, 8)'), 1, '%ds:(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%es:3( %eax, %ebx, 1)'), 1, '%es:3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%fs:-9(%eax, %ebx, 1)'), 1, '%fs:-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:(%eax, %ebx, 4)'), 1, '%ds:(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%es:3( %eax, %ebx, 4)'), 1, '%es:3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%fs:-9(%eax, %ebx, 4)'), 1, '%fs:-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ds:(%eax, %ebx, 8)'), 1, '%ds:(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%es:3( %eax, %ebx, 8)'), 1, '%es:3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%fs:-9(%eax, %ebx, 8)'), 1, '%fs:-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%ds:(%eax, %ebx, 5)'), 0, '%ds:(%eax, %ebx, 1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%es:3( %eax, %ebx, 5)'), 0, '%es:3( %eax, %ebx, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%fs:-9(%eax, %ebx, 5)'), 0, '%fs:-9(%eax, %ebx, 4) is a valid 32-bit addressing scheme' );

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

is ( is_valid_32bit_addr_att ('(%cs)'), 0, '(cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%cs,%ebx)'), 0, '(cs,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%cs,2)'), 0, '(cs,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%ebx,%cs)'), 0, '(ebx,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(2,%cs)'), 0, '(2,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%cs,%ebx,2)'), 0, '(cs,ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%ebx,%cs,2)'), 0, '(ebx,cs,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%cs,2,%ebx)'), 0, '(cs,2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%ebx,2,%cs)'), 0, '(ebx,2,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(2,%cs,%ebx)'), 0, '(2,cs,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(2,%ebx,%cs)'), 0, '(2,ebx,cs) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('(%cx)'), 0, '(cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(zzz)'), 1, '(zzz) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(-%ecx)'), 0, '(-ecx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%cx,%ebx)'), 0, '(cx,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%cx,2)'), 0, '(cx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%ebx,%cx)'), 0, '(ebx,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%ebx,2)'), 0, '(ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(2,%cx)'), 0, '(2,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(2,%ebx)'), 0, '(2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%cx,%ebx,2)'), 0, '(cx,ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%ebx,%cx,2)'), 0, '(ebx,cx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%cx,2,%ebx)'), 0, '(cx,2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(%ebx,2,%cx)'), 0, '(ebx,2,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(2,%cx,%ebx)'), 0, '(2,cx,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('(2,%ebx,%cx)'), 0, '(2,ebx,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx(%eax,%ebx,2)'), 0, '%cx(%eax,%ebx,2) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('zzz(%cs)'), 0, 'zzz(cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%cr0)'), 0, 'zzz(cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(-%ebx)'), 0, 'zzz(-ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(-%bx)'), 0, 'zzz(-bx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%cs,%ebx)'), 0, 'zzz(cs,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%cs,2)'), 0, 'zzz(cs,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%ebx,%cs)'), 0, 'zzz(ebx,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(2,%cs)'), 0, 'zzz(2,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%cs,%ebx,2)'), 0, 'zzz(cs,ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%ebx,%cs,2)'), 0, 'zzz(ebx,cs,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%cs,2,%ebx)'), 0, 'zzz(cs,2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%ebx,2,%cs)'), 0, 'zzz(ebx,2,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(2,%cs,%ebx)'), 0, 'zzz(2,cs,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(2,%ebx,%cs)'), 0, 'zzz(2,ebx,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%eax ,%esp, 2)'), 0, 'zzz(%eax ,%esp, 2) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('zzz(%cx)'), 0, 'zzz(cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%cx,%ebx)'), 0, 'zzz(cx,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%cx,%si)'), 0, 'zzz(cx,si) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%cx,2)'), 0, 'zzz(cx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%ebx,%cx)'), 0, 'zzz(ebx,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%ebx,2)'), 0, 'zzz(ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(2,%cx)'), 0, 'zzz(2,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(2,%ebx)'), 0, 'zzz(2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%cx,%ebx,2)'), 0, 'zzz(cx,ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%si,%cx)'), 0, 'zzz(si,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%cx,%ebx,2)'), 0, 'zzz(cx,ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%ebx,%cx,2)'), 0, 'zzz(ebx,cx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%cx,2,%ebx)'), 0, 'zzz(cx,2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(%ebx,2,%cx)'), 0, 'zzz(ebx,2,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(2,%cx,%ebx)'), 0, 'zzz(2,cx,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('zzz(2,%ebx,%cx)'), 0, 'zzz(2,ebx,cx) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%cs:(%cs)'), 0, '%cs:(cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%cr0)'), 0, '%cs:(cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(-%ebx)'), 0, '%cs:(-ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(-%bx)'), 0, '%cs:(-bx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(xxx)'), 1, '%cs:(xxx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%cs,%ebx)'), 0, '%cs:(cs,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%cs,2)'), 0, '%cs:(cs,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%ebx,%cs)'), 0, '%cs:(ebx,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(2,%cs)'), 0, '%cs:(2,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%cs,%ebx,2)'), 0, '%cs:(cs,ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%ebx,%cs,2)'), 0, '%cs:(ebx,cs,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%cs,2,%ebx)'), 0, '%cs:(cs,2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%ebx,2,%cs)'), 0, '%cs:(ebx,2,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(2,%cs,%ebx)'), 0, '%cs:(2,cs,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(2,%ebx,%cs)'), 0, '%cs:(2,ebx,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(-%ebx)'), 0, '%cs:(-ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(ca)'), 1, '%cs:(ca) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%ecx)'), 1, '%cs:(ecx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%eax ,%esp, 2)'), 0, '%cs:(%eax ,%esp, 2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:%cx(%eax,%ebx,2)'), 0, '%cs:%cx(%eax,%ebx,2) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%cs:(%cx)'), 0, '%cs:(cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%cx,%ebx)'), 0, '%cs:(cx,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%cx,2)'), 0, '%cs:(cx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%ebx,%cx)'), 0, '%cs:(ebx,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%ebx,2)'), 0, '%cs:(ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(2,%cx)'), 0, '%cs:(2,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(2,%ebx)'), 0, '%cs:(2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%cx,%ebx,2)'), 0, '%cs:(cx,ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%cx,%ebx,2)'), 0, '%cs:(cx,ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%cx,%si,2)'), 0, '%cs:(cx,si,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%ebx,%cx,2)'), 0, '%cs:(ebx,cx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%si,%cx,2)'), 0, '%cs:(si,cx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%cx,2,%ebx)'), 0, '%cs:(cx,2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%ebx,2,%cx)'), 0, '%cs:(ebx,2,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(2,%cx,%ebx)'), 0, '%cs:(2,cx,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(2,%ebx,%cx)'), 0, '%cs:(2,ebx,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(-%cx)'), 0, '%cs:(-cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%ecx,%ebx)'), 1, '%cs:(ecx,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%cx,%eebx)'), 0, '%cs:(cx,eebx) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%cs:(bsi,%cx,2)'), 0, '%cs:(bsi,cx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%si,bcx,2)'), 0, '%cs:(si,bcx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%esi,%ecx,1)'), 1, '%cs:(esi,ecx,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%esi,%ecx,2)'), 1, '%cs:(esi,ecx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%esi,%ecx,4)'), 1, '%cs:(esi,ecx,4) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%esi,%ecx,8)'), 1, '%cs:(esi,ecx,8) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:(%esi,%ecx,5)'), 0, '%cs:(esi,ecx,5) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%cx:(%cs)'), 0, '%cx:(cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:(%cs,%ebx)'), 0, '%cx:(cs,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:(%cs,2)'), 0, '%cx:(cs,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:(%ebx,%cs)'), 0, '%cx:(ebx,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:(2,%cs)'), 0, '%cx:(2,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:(%cs,%ebx,2)'), 0, '%cx:(cs,ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:(%ebx,%cs,2)'), 0, '%cx:(ebx,cs,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:(%cs,2,%ebx)'), 0, '%cx:(cs,2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:(%ebx,2,%cs)'), 0, '%cx:(ebx,2,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:(2,%cs,%ebx)'), 0, '%cx:(2,cs,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:(2,%ebx,%cs)'), 0, '%cx:(2,ebx,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:(-%ebx)'), 0, '%cx:(-ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:(ca)'), 0, '%cx:(ca) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%cs:zzz(%cs)'), 0, '%cs:zzz(cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%cr0)'), 0, '%cs:zzz(cr0) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(-%ebx)'), 0, '%cs:zzz(-ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(-%bx)'), 0, '%cs:zzz(-bx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(xxx)'), 0, '%cs:zzz(xxx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%cs,%ebx)'), 0, '%cs:zzz(cs,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%cs,2)'), 0, '%cs:zzz(cs,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%ebx,%cs)'), 0, '%cs:zzz(ebx,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(2,%cs)'), 0, '%cs:zzz(2,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%cs,%ebx,2)'), 0, '%cs:zzz(cs,ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%ebx,%cs,2)'), 0, '%cs:zzz(ebx,cs,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%cs,2,%ebx)'), 0, '%cs:zzz(cs,2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%ebx,2,%cs)'), 0, '%cs:zzz(ebx,2,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(2,%cs,%ebx)'), 0, '%cs:zzz(2,cs,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(2,%ebx,%cs)'), 0, '%cs:zzz(2,ebx,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(-%ebx)'), 0, '%cs:zzz(-ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(ca)'), 0, '%cs:zzz(ca) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%ecx)'), 1, '%cs:zzz(ecx) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%cs:zzz(%cx)'), 0, '%cs:zzz(cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%cx,%ebx)'), 0, '%cs:zzz(cx,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%cx,%si)'), 0, '%cs:zzz(cx,si) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%cx,2)'), 0, '%cs:zzz(cx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%ebx,%cx)'), 0, '%cs:zzz(ebx,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%ebx,2)'), 0, '%cs:zzz(ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(2,%cx)'), 0, '%cs:zzz(2,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(2,%ebx)'), 0, '%cs:zzz(2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%cx,%ebx,2)'), 0, '%cs:zzz(cx,ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%si,%cx)'), 0, '%cs:zzz(si,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%cx,%ebx,2)'), 0, '%cs:zzz(cx,ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%cx,%si,2)'), 0, '%cs:zzz(cx,si,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%ebx,%cx,2)'), 0, '%cs:zzz(ebx,cx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%si,%cx,2)'), 0, '%cs:zzz(si,cx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%cx,2,%ebx)'), 0, '%cs:zzz(cx,2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%ebx,2,%cx)'), 0, '%cs:zzz(ebx,2,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(2,%cx,%ebx)'), 0, '%cs:zzz(2,cx,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(2,%ebx,%cx)'), 0, '%cs:zzz(2,ebx,cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(-%cx)'), 0, '%cs:zzz(-cx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%ecx,%ebx)'), 1, '%cs:zzz(ecx,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%cx,%eebx)'), 0, '%cs:zzz(cx,eebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cs:zzz(%eax ,%esp, 2)'), 0, '%cs:zzz(%eax ,%esp, 2) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%cx:zzz(%cs)'), 0, '%cx:zzz(cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:zzz(%cs,%ebx)'), 0, '%cx:zzz(cs,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:zzz(%cs,2)'), 0, '%cx:zzz(cs,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:zzz(%ebx,%cs)'), 0, '%cx:zzz(ebx,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:zzz(2,%cs)'), 0, '%cx:zzz(2,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:zzz(%cs,%ebx,2)'), 0, '%cx:zzz(cs,ebx,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:zzz(%ebx,%cs,2)'), 0, '%cx:zzz(ebx,cs,2) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:zzz(%cs,2,%ebx)'), 0, '%cx:zzz(cs,2,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:zzz(%ebx,2,%cs)'), 0, '%cx:zzz(ebx,2,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:zzz(2,%cs,%ebx)'), 0, '%cx:zzz(2,cs,ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:zzz(2,%ebx,%cs)'), 0, '%cx:zzz(2,ebx,cs) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:zzz(-%ebx)'), 0, '%cx:zzz(-ebx) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%cx:zzz(ca)'), 0, '%cx:zzz(ca) is a valid 32-bit addressing scheme' );

is ( is_valid_32bit_addr_att ('%cs:%bx(,1)'), 0, '%cs:%bx(,1) is a valid 32-bit addressing scheme' );
is ( is_valid_32bit_addr_att ('%ax:zzz(,1)'), 0, '%ax:zzz(,1) is a valid 32-bit addressing scheme' );

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
is ( is_valid_64bit_addr_att ('(%ecx, %ebx)'), 1, '(%ecx, %ebx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%ecx, %ebx, 1)'), 1, '(%ecx, %ebx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx(,1)'), 0, 'cx(,1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx(%rax)'), 0, '%cx(%eax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx(%rax, %rbx)'), 0, '%cx(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx(%rax, %rbx, 2)'), 0, '%cx(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%dx(, %rcx, 4)'), 0, '%dx(, %rcx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(zzz)'), 0, 'zzz(zzz) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%rax, %rbx)'), 1, 'zzz(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(, zzz, 8)'), 0, 'zzz(, zzz, 8) is a valid 64-bit addressing scheme' );

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
is ( is_valid_64bit_addr_att ('2(%rbx, %cr0, 2)'), 0, '2(%rbx, %cr0, 2) is a valid 64-bit addressing scheme' );
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
is ( is_valid_64bit_addr_att ('(%r9d, %rax)'), 0, '(%r9d, %rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%r9d, %rbx, 2)'), 0, '(%r9d, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, -%rbx)'), 0, '(%rax, -%rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, -%rbx, 4)'), 0, '(%rax, -%rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax -, %rbx)'), 0, '(%rax -, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax -, %rbx, 4)'), 0, '(%rax -, %rbx, 4) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('(%rbx)'), 1, '(%rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%ds)'), 0, '(%ds) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%cr0)'), 0, '(%cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%mm0)'), 0, '(%mm0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%ax)'), 0, '(%ax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%dl)'), 0, '(%dl) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%eax)'), 1, '(%eax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%r9d)'), 1, '(%r9d) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('(,%rsp, 2)'), 0, '(,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(,%rip, 2)'), 0, '(,%rip, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax ,%rsp, 2)'), 0, '(%rax ,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax ,%rip, 2)'), 0, '(%rax ,%rip, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rsp, %rax ,2)'), 1, '(%rsp, %rax ,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rip, %rax ,2)'), 0, '(%rip, %rax ,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(zzz, %rax ,2)'), 0, '(zzz, %rax ,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, zzz ,2)'), 0, '(%rax, zzz ,2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ax:(%rbx)'), 0, '%ax:(%rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:(zzz)'), 0, '%ax:(zzz) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:(%rax, %cr0)'), 0, '%ax:(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:(%rax, %rcx)'), 0, '%ax:(%rax, %rcx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:(%cr0, %rbx, 2)'), 0, '%ax:(%cr0, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:(%rax, %rcx, 2)'), 0, '%ax:(%rax, %rcx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:(%rbx, %cr0, 2)'), 0, '%ax:(%rbx, %cr0, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:1(%rbx)'), 0, '%ax:1(%rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:1(zzz)'), 0, '%ax:1(zzz) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:1(%rax, %cr0)'), 0, '%ax:1(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:1(%rax, %rcx)'), 0, '%ax:1(%rax, %rcx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:1(%cr0, %rbx, 2)'), 0, '%ax:1(%cr0, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:1(%rax, %rcx, 2)'), 0, '%ax:1(%rax, %rcx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:1(%rbx, %cr0, 2)'), 0, '%ax:1(%rbx, %cr0, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%cs:(%ds)'), 0, '%cs:(%ds) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(zzz)'), 1, '%ds:(zzz) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(zzz)'), 0, '%ds:1(zzz) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(zzz)'), 0, '1(zzz) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(zzz, %rbx)'), 0, '(zzz, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(zzz, %rbx)'), 0, '1(zzz, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(-%rax)'), 0, '%ds:(-%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(zzz, %rbx)'), 0, '%ds:(zzz, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(zzz, %rbx)'), 0, '%ds:1(zzz, %rbx) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('1(%cr0)'), 0, '1(%cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax, %cr0)'), 0, '1(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%cr0, %rbx)'), 0, '2(%cr0, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%cr0, %rbx, 2)'), 0, '2(%cr0, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%rbx, %cr0, 2)'), 0, '2(%rbx, %cr0, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('1(%ecx)'), 1, '1(%ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%ecx, %ebx)'), 1, '1(%ecx, %ebx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%ecx, %ebx, 1)'), 1, '1(%ecx, %ebx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax, %ecx)'), 0, '1(%rax, %ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%ecx, %rbx)'), 0, '2(%ecx, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%ecx, %rbx, 2)'), 0, '2(%ecx, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%rbx, %ecx, 2)'), 0, '2(%rbx, %ecx, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('1(%mm0)'), 0, '1(%mm0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax, %mm0)'), 0, '1(%rax, %mm0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%mm0, %rbx)'), 0, '2(%mm0, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%mm0, %rbx, 2)'), 0, '2(%mm0, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%rbx, %mm0, 2)'), 0, '2(%rbx, %mm0, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('1(%dl)'), 0, '1(%dl) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax, %dl)'), 0, '1(%rax, %dl) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%dl, %rbx)'), 0, '2(%dl, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%dl, %rbx, 2)'), 0, '2(%dl, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%rbx, %dl, 2)'), 0, '2(%rbx, %dl, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('1(%ax)'), 0, '1(%ax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax, %ax)'), 0, '1(%rax, %ax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%ax, %rbx)'), 0, '2(%ax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%ax, %rbx, 2)'), 0, '2(%ax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%rbx, %ax, 2)'), 0, '2(%rbx, %ax, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('1(%st1)'), 0, '1(%st1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax, %st1)'), 0, '1(%rax, %st1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%st1, %rbx)'), 0, '2(%st1, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%st1, %rbx, 2)'), 0, '2(%st1, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%rbx, %st1, 2)'), 0, '2(%rbx, %st1, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('1(%cs)'), 0, '1(%cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax, %cs)'), 0, '1(%rax, %cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%cs, %rbx)'), 0, '2(%cs, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%cs, %rbx, 2)'), 0, '2(%cs, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%rbx, %cs, 2)'), 0, '2(%rbx, %cs, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('1(%ecx)'), 1, '1(%ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax, %ecx)'), 0, '1(%rax, %ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%ecx, %rbx)'), 0, '2(%ecx, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%ecx, %rbx, 2)'), 0, '2(%ecx, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%rbx, %ecx, 2)'), 0, '2(%rbx, %ecx, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('1(%r9d)'), 1, '1(%r9d) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax, %r9d)'), 0, '1(%rax, %r9d) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%r9d, %rbx)'), 0, '2(%r9d, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%r9d, %rbx, 2)'), 0, '2(%r9d, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%rbx, %r9d, 2)'), 0, '2(%rbx, %r9d, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('1(,%rsp, 2)'), 0, '1(,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(,%rip, 2)'), 0, '1(,%rip, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax ,%rsp, 2)'), 0, '1(%rax ,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax ,%rip, 2)'), 0, '1(%rax ,%rip, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rsp, %rax ,2)'), 1, '1(%rsp, %rax ,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rip, %rax ,2)'), 0, '1(%rip, %rax ,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(zzz, %rax ,2)'), 0, '1(zzz, %rax ,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(%rax, zzz ,2)'), 0, '1(%rax, zzz ,2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:1(%cr0)'), 0, '%ds:1(%cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rax, %cr0)'), 0, '%ds:1(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%cr0, %rbx)'), 0, '%ds:1(%cr0, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%cr0, %rbx, 2)'), 0, '%ds:1(%cr0, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rbx, %cr0, 2)'), 0, '%ds:1(%rbx, %cr0, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:1(%ecx)'), 1, '%ds:1(%ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%ecx, %ebx)'), 1, '%ds:1(%ecx, %ebx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%ecx, %ebx, 1)'), 1, '%ds:1(%ecx, %ebx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rax, %ecx)'), 0, '%ds:1(%rax, %ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%ecx, %rbx)'), 0, '%ds:1(%ecx, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%ecx, %rbx, 2)'), 0, '%ds:1(%ecx, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rbx, %ecx, 2)'), 0, '%ds:1(%rbx, %ecx, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:1(%mm0)'), 0, '%ds:1(%mm0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rax, %mm0)'), 0, '%ds:1(%rax, %mm0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%mm0, %rbx)'), 0, '%ds:1(%mm0, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%mm0, %rbx, 2)'), 0, '%ds:1(%mm0, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rbx, %mm0, 2)'), 0, '%ds:1(%rbx, %mm0, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:1(%dl)'), 0, '%ds:1(%dl) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rax, %dl)'), 0, '%ds:1(%rax, %dl) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%dl, %rbx)'), 0, '%ds:1(%dl, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%dl, %rbx, 2)'), 0, '%ds:1(%dl, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rbx, %dl, 2)'), 0, '%ds:1(%rbx, %dl, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:1(%ax)'), 0, '%ds:1(%ax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rax, %ax)'), 0, '%ds:1(%rax, %ax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%ax, %rbx)'), 0, '%ds:1(%ax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%ax, %rbx, 2)'), 0, '%ds:1(%ax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rbx, %ax, 2)'), 0, '%ds:1(%rbx, %ax, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:1(%st1)'), 0, '%ds:1(%st1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rax, %st1)'), 0, '%ds:1(%rax, %st1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%st1, %rbx)'), 0, '%ds:1(%st1, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%st1, %rbx, 2)'), 0, '%ds:1(%st1, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rbx, %st1, 2)'), 0, '%ds:1(%rbx, %st1, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:1(%cs)'), 0, '%ds:1(%cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rax, %cs)'), 0, '%ds:1(%rax, %cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%cs, %rbx)'), 0, '%ds:1(%cs, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%cs, %rbx, 2)'), 0, '%ds:1(%cs, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rbx, %cs, 2)'), 0, '%ds:1(%rbx, %cs, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:1(%ecx)'), 1, '%ds:1(%ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rax, %ecx)'), 0, '%ds:1(%rax, %ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%ecx, %rbx)'), 0, '%ds:1(%ecx, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%ecx, %rbx, 2)'), 0, '%ds:1(%ecx, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rbx, %ecx, 2)'), 0, '%ds:1(%rbx, %ecx, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:1(%r9d)'), 1, '%ds:1(%r9d) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rax, %r9d)'), 0, '%ds:1(%rax, %r9d) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%r9d, %rbx)'), 0, '%ds:1(%r9d, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%r9d, %rbx, 2)'), 0, '%ds:1(%r9d, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rbx, %r9d, 2)'), 0, '%ds:1(%rbx, %r9d, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:1(,%rsp, 2)'), 0, '%ds:1(,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(,%rip, 2)'), 0, '%ds:1(,%rip, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rax ,%rsp, 2)'), 0, '%ds:1(%rax ,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rax ,%rip, 2)'), 0, '%ds:1(%rax ,%rip, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rsp, %rax ,2)'), 1, '%ds:1(%rsp, %rax ,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rip, %rax ,2)'), 0, '%ds:1(%rip, %rax ,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(zzz, %rax ,2)'), 0, '%ds:1(zzz, %rax ,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:1(%rax, zzz ,2)'), 0, '%ds:1(%rax, zzz ,2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(%cr0)'), 0, '%ds:(%cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %cr0)'), 0, '%ds:(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%cr0, %rbx)'), 0, '%ds:(%cr0, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%cr0, %rbx, 2)'), 0, '%ds:(%cr0, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rbx, %cr0, 2)'), 0, '%ds:(%rbx, %cr0, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(%ecx)'), 1, '%ds:(%ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %ecx)'), 0, '%ds:(%rax, %ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%ecx, %rbx)'), 0, '%ds:(%ecx, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%ecx, %rbx, 2)'), 0, '%ds:(%ecx, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rbx, %ecx, 2)'), 0, '%ds:(%rbx, %ecx, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(%mm0)'), 0, '%ds:(%mm0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %mm0)'), 0, '%ds:(%rax, %mm0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%mm0, %rbx)'), 0, '%ds:(%mm0, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%mm0, %rbx, 2)'), 0, '%ds:(%mm0, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rbx, %mm0, 2)'), 0, '%ds:(%rbx, %mm0, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(%dl)'), 0, '%ds:(%dl) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %dl)'), 0, '%ds:(%rax, %dl) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%dl, %rbx)'), 0, '%ds:(%dl, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%dl, %rbx, 2)'), 0, '%ds:(%dl, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rbx, %dl, 2)'), 0, '%ds:(%rbx, %dl, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(%ax)'), 0, '%ds:(%ax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %ax)'), 0, '%ds:(%rax, %ax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%ax, %rbx)'), 0, '%ds:(%ax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%ax, %rbx, 2)'), 0, '%ds:(%ax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rbx, %ax, 2)'), 0, '%ds:(%rbx, %ax, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(%st1)'), 0, '%ds:(%st1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %st1)'), 0, '%ds:(%rax, %st1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%st1, %rbx)'), 0, '%ds:(%st1, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%st1, %rbx, 2)'), 0, '%ds:(%st1, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rbx, %st1, 2)'), 0, '%ds:(%rbx, %st1, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(%cs)'), 0, '%ds:(%cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %cs)'), 0, '%ds:(%rax, %cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%cs, %rbx)'), 0, '%ds:(%cs, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%cs, %rbx, 2)'), 0, '%ds:(%cs, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rbx, %cs, 2)'), 0, '%ds:(%rbx, %cs, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(%ecx)'), 1, '%ds:(%ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %ecx)'), 0, '%ds:(%rax, %ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%ecx, %rbx)'), 0, '%ds:(%ecx, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%ecx, %rbx, 2)'), 0, '%ds:(%ecx, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rbx, %ecx, 2)'), 0, '%ds:(%rbx, %ecx, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(%r9d)'), 1, '%ds:(%r9d) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %r9d)'), 0, '%ds:(%rax, %r9d) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%r9d, %rbx)'), 0, '%ds:(%r9d, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%r9d, %rbx, 2)'), 0, '%ds:(%r9d, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rbx, %r9d, 2)'), 0, '%ds:(%rbx, %r9d, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(,%rsp, 2)'), 0, '%ds:(,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(,%rip, 2)'), 0, '%ds:(,%rip, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax ,%rsp, 2)'), 0, '%ds:(%rax ,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax ,%rip, 2)'), 0, '%ds:(%rax ,%rip, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rsp, %rax ,2)'), 1, '%ds:(%rsp, %rax ,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rip, %rax ,2)'), 0, '%ds:(%rip, %rax ,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(zzz, %rax ,2)'), 0, '%ds:(zzz, %rax ,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, zzz ,2)'), 0, '%ds:(%rax, zzz ,2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%cs:(, %rbx, 1)'), 1, '%cs:(, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(, %rbx, 2)'), 1, '%cs:(, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(, %rbx, 4)'), 1, '%cs:(, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(, %rbx, 8)'), 1, '%cs:(, %rbx, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(, %rbx, 5)'), 0, '%cs:(, %rbx, 5) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:(, %rbx, 8)'), 0, '%ax:(, %rbx, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(, %ds, 8)'), 0, '%cs:(, %ds, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(, %cr0, 8)'), 0, '%cs:(, %cr0, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(, %mm0, 8)'), 0, '%cs:(, %mm0, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(, %ax, 8)'), 0, '%cs:(, %ax, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(, %dl, 8)'), 0, '%cs:(, %dl, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(, %eax, 8)'), 1, '%cs:(, %eax, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(, %r9d, 8)'), 1, '%cs:(, %r9d, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(, %rsp, 8)'), 0, '%cs:(, %rsp, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(, zzz, 8)'), 0, '%cs:(, zzz, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:%cx(,1)'), 0, '%cs:cx(,1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:%cx(%rax)'), 0, '%cs:%cx(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:%cx(%rax, %rbx)'), 0, '%ds:%cx(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:%cx(%rax, %rbx, 2)'), 0, '%ds:%cx(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:%dx(, %ecx, 4)'), 0, '%cs:%dx(, %rcx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:zzz(zzz)'), 0, '%ds:zzz(zzz) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:zzz(%rax, %rbx)'), 1, '%ds:zzz(%rax, %rbx) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('(, %rbx, 1)'), 1, '(, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, %rbx, 2)'), 1, '(, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, %rbx, 4)'), 1, '(, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, %rbx, 8)'), 1, '(, %rbx, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, %rbx, 5)'), 0, '(, %rbx, 5) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, %ds, 8)'), 0, '(, %ds, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, %cr0, 8)'), 0, '(, %cr0, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, %mm0, 8)'), 0, '(, %mm0, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, %ax, 8)'), 0, '(, %ax, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, %dl, 8)'), 0, '(, %dl, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, %eax, 8)'), 1, '(, %eax, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, %r9d, 8)'), 1, '(, %r9d, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, %rsp, 8)'), 0, '(, %rsp, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(, zzz, 8)'), 0, '(, zzz, 8) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%cs:1(, %rbx, 1)'), 1, '%cs:1(, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:2(, %rbx, 2)'), 1, '%cs:2(, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:3(, %rbx, 4)'), 1, '%cs:3(, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:4(, %rbx, 8)'), 1, '%cs:4(, %rbx, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:5(, %rbx, 5)'), 0, '%cs:5(, %rbx, 5) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:6(, %rbx, 8)'), 0, '%ax:6(, %rbx, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:7(, %ds, 8)'), 0, '%cs:7(, %ds, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:8(, %cr0, 8)'), 0, '%cs:8(, %cr0, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:1(, %mm0, 8)'), 0, '%cs:1(, %mm0, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:1(, %ax, 8)'), 0, '%cs:1(, %ax, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:1(, %dl, 8)'), 0, '%cs:1(, %dl, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:1(, %eax, 8)'), 1, '%cs:1(, %eax, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:1(, %r9d, 8)'), 1, '%cs:1(, %r9d, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:1(, %rsp, 8)'), 0, '%cs:1(, %rsp, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:1(, zzz, 8)'), 0, '%cs:1(, zzz, 8) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('1(, %rbx, 1)'), 1, '1(, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(, %rbx, 2)'), 1, '2(, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('3(, %rbx, 4)'), 1, '3(, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('4(, %rbx, 8)'), 1, '4(, %rbx, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('5(, %rbx, 5)'), 0, '5(, %rbx, 5) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('6(, %ds, 8)'), 0, '6(, %ds, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('7(, %cr0, 8)'), 0, '7(, %cr0, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(, %mm0, 8)'), 0, '1(, %mm0, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(, %ax, 8)'), 0, '1(, %ax, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(, %dl, 8)'), 0, '1(, %dl, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(, %eax, 8)'), 1, '1(, %eax, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(, %r9d, 8)'), 1, '1(, %r9d, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(, %rsp, 8)'), 0, '1(, %rsp, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('1(, zzz, 8)'), 0, '1(, zzz, 8) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:%cx(,1)'), 0, '%ds:cx(,1) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(, zzz, 8)'), 0, '%ds:(, zzz, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%fs:5(, zzz, 8)'), 0, '%fs:5(, zzz, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%es:zzz(, zzz, 8)'), 0, '%es:zzz(, zzz, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:%cx(%rax)'), 0, '%ds:%cx(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:%cx(%rax, %rbx)'), 0, '%ds:%cx(%rax, %rbx) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('(%rax, %rbx, 1)'), 1, '(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('3( %rax, %rbx, 2)'), 1, '3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-9(%rax, %rbx, 4)'), 1, '-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, %cr0, 1)'), 0, '(%rax, %cr0, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('3( %rax, %cr0, 2)'), 0, '3( %rax, %cr0, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-9(%rax, %cr0, 4)'), 0, '-9(%rax, %cr0, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%cr0, %rbx, 1)'), 0, '(%cr0, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('3( %cr0, %rbx, 2)'), 0, '3( %cr0, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-9(%cr0, %rbx, 4)'), 0, '-9(%cr0, %rbx, 4) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('(%rax, %ecx, 1)'), 0, '(%rax, %ecx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('3( %rax, %ecx, 2)'), 0, '3( %rax, %ecx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-9(%rax, %ecx, 4)'), 0, '-9(%rax, %ecx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%ecx, %rbx, 1)'), 0, '(%ecx, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('3( %ecx, %rbx, 2)'), 0, '3( %ecx, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-9(%ecx, %rbx, 4)'), 0, '-9(%ecx, %rbx, 4) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('(%rax, %rbx, 2)'), 1, '(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, %rbx, 4)'), 1, '(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, %rbx, 8)'), 1, '(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('3( %rax, %rbx, 1)'), 1, '3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-9(%rax, %rbx, 1)'), 1, '-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, %rbx, 4)'), 1, '(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('3( %rax, %rbx, 4)'), 1, '3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-9(%rax, %rbx, 4)'), 1, '-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, %rbx, 8)'), 1, '(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('3( %rax, %rbx, 8)'), 1, '3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-9(%rax, %rbx, 8)'), 1, '-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('(%rax, %rbx, 5)'), 0, '(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('3( %rax, %rbx, 5)'), 0, '3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-9(%rax, %rbx, 5)'), 0, '-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('(%rax, %rbx)'), 1, '(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%rax, %rbx)'), 1, '2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-2(%rax, %rbx)'), 1, '-2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax, %cr0)'), 0, '(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%rax, %cr0)'), 0, '2(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-2(%rax, %cr0)'), 0, '-2(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%cr0, %rbx)'), 0, '(%cr0, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%cr0, %rbx)'), 0, '2(%cr0, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-2(%cr0, %rbx)'), 0, '-2(%cr0, %rbx) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('(%rax, %ecx)'), 0, '(%rax, %ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%rax, %ecx)'), 0, '2(%rax, %ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-2(%rax, %ecx)'), 0, '-2(%rax, %ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%ecx, %rbx)'), 0, '(%ecx, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%ecx, %rbx)'), 0, '2(%ecx, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-2(%ecx, %rbx)'), 0, '-2(%ecx, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%ecx, %ebx)'), 1, '(%ecx, %ebx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('2(%ecx, %ebx)'), 1, '2(%ecx, %ebx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('-2(%ecx, %ebx)'), 1, '-2(%ecx, %ebx) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%cs:zzz(,1)'), 1, '%cs:zzz(,1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax)'), 1, '%ds:(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%es:1(%rax)'), 1, '%es:1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%fs:-1(%rax)'), 1, '-%fs:1(%rax) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%gs:(, %rbx, 8)'), 1, '%gs:(, %rbx, 8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ss:7(, %rcx, 4)'), 1, '%ss:7(, %rcx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:-7(, %rdx, 2)'), 1, '%cs:-7(, %rdx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:11(,1)'), 1, '%ds:11(,1) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%gs:(%rax, %rbx)'), 1, '%gs:(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ss:2(%rax, %rbx)'), 1, '%ss:2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:-2(%rax, %rbx)'), 1, '%cs:-2(%rax, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%gs:(%rax, %cr0)'), 0, '%gs:(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ss:2(%rax, %cr0)'), 0, '%ss:2(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:-2(%rax, %cr0)'), 0, '%cs:-2(%rax, %cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%gs:(%cr0, %rbx)'), 0, '%gs:(%cr0, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ss:2(%cr0, %rbx)'), 0, '%ss:2(%cr0, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:-2(%cr0, %rbx)'), 0, '%cs:-2(%cr0, %rbx) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%gs:(%rax, %ecx)'), 0, '%gs:(%rax, %ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ss:2(%rax, %ecx)'), 0, '%ss:2(%rax, %ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:-2(%rax, %ecx)'), 0, '%cs:-2(%rax, %ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%gs:(%ecx, %rbx)'), 0, '%gs:(%ecx, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ss:2(%ecx, %rbx)'), 0, '%ss:2(%ecx, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:-2(%ecx, %rbx)'), 0, '%cs:-2(%ecx, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%gs:(%eax, %ecx)'), 1, '%gs:(%eax, %ecx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ss:2(%ecx, %ebx)'), 1, '%ss:2(%ecx, %ebx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:-2(%ecx, %ebx)'), 1, '%cs:-2(%ecx, %ebx) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(%rax, %rbx, 1)'), 1, '%ds:(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%es:3( %rax, %rbx, 2)'), 1, '%es:3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%fs:-9(%rax, %rbx, 4)'), 1, '%fs:-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %cr0, 1)'), 0, '%ds:(%rax, %cr0, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%es:3( %rax, %cr0, 2)'), 0, '%es:3( %rax, %cr0, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%fs:-9(%rax, %cr0, 4)'), 0, '%fs:-9(%rax, %cr0, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%cr0, %rbx, 1)'), 0, '%ds:(%cr0, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%es:3( %cr0, %rbx, 2)'), 0, '%es:3( %cr0, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%fs:-9(%cr0, %rbx, 4)'), 0, '%fs:-9(%cr0, %rbx, 4) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(%rax, %ecx, 1)'), 0, '%ds:(%rax, %ecx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%es:3( %rax, %ecx, 2)'), 0, '%es:3( %rax, %ecx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%fs:-9(%rax, %ecx, 4)'), 0, '%fs:-9(%rax, %ecx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%ecx, %rbx, 1)'), 0, '%ds:(%ecx, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%es:3( %ecx, %rbx, 2)'), 0, '%es:3( %ecx, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%fs:-9(%ecx, %rbx, 4)'), 0, '%fs:-9(%ecx, %rbx, 4) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(%rax, %rbx, 2)'), 1, '%ds:(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %rbx, 4)'), 1, '%ds:(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %rbx, 8)'), 1, '%ds:(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%es:3( %rax, %rbx, 1)'), 1, '%es:3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%fs:-9(%rax, %rbx, 1)'), 1, '%fs:-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %rbx, 4)'), 1, '%ds:(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%es:3( %rax, %rbx, 4)'), 1, '%es:3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%fs:-9(%rax, %rbx, 4)'), 1, '%fs:-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ds:(%rax, %rbx, 8)'), 1, '%ds:(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%es:3( %rax, %rbx, 8)'), 1, '%es:3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%fs:-9(%rax, %rbx, 8)'), 1, '%fs:-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%ds:(%rax, %rbx, 5)'), 0, '%ds:(%rax, %rbx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%es:3( %rax, %rbx, 5)'), 0, '%es:3( %rax, %rbx, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%fs:-9(%rax, %rbx, 5)'), 0, '%fs:-9(%rax, %rbx, 4) is a valid 64-bit addressing scheme' );

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
is ( is_valid_64bit_addr_att ('(%rax -, %rbx)'), 0, '(%rax -, %rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rax -, %rbx, 4)'), 0, '(%rax -, %rbx, 4) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('(%cs)'), 0, '(cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%cs,%rbx)'), 0, '(cs,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%cs,2)'), 0, '(cs,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rbx,%cs)'), 0, '(rbx,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(2,%cs)'), 0, '(2,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%cs,%rbx,2)'), 0, '(cs,rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rbx,%cs,2)'), 0, '(rbx,cs,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%cs,2,%rbx)'), 0, '(cs,2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rbx,2,%cs)'), 0, '(rbx,2,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(2,%cs,%rbx)'), 0, '(2,cs,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(2,%rbx,%cs)'), 0, '(2,rbx,cs) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('(%cx)'), 0, '(cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(zzz)'), 1, '(zzz) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(-%rcx)'), 0, '(-rcx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%cx,%rbx)'), 0, '(cx,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%cx,2)'), 0, '(cx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rbx,%cx)'), 0, '(rbx,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rbx,2)'), 0, '(rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(2,%cx)'), 0, '(2,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(2,%rbx)'), 0, '(2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%cx,%rbx,2)'), 0, '(cx,rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rbx,%cx,2)'), 0, '(rbx,cx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%cx,2,%rbx)'), 0, '(cx,2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(%rbx,2,%cx)'), 0, '(rbx,2,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(2,%cx,%rbx)'), 0, '(2,cx,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('(2,%rbx,%cx)'), 0, '(2,rbx,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx(%rax,%rbx,2)'), 0, '%cx(%rax,%rbx,2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('zzz(%cs)'), 0, 'zzz(cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%cr0)'), 0, 'zzz(cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(-%rbx)'), 0, 'zzz(-rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(-%bx)'), 0, 'zzz(-bx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%cs,%rbx)'), 0, 'zzz(cs,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%cs,2)'), 0, 'zzz(cs,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%rbx,%cs)'), 0, 'zzz(rbx,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(2,%cs)'), 0, 'zzz(2,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%cs,%rbx,2)'), 0, 'zzz(cs,rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%rbx,%cs,2)'), 0, 'zzz(rbx,cs,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%cs,2,%rbx)'), 0, 'zzz(cs,2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%rbx,2,%cs)'), 0, 'zzz(rbx,2,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(2,%cs,%rbx)'), 0, 'zzz(2,cs,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(2,%rbx,%cs)'), 0, 'zzz(2,rbx,cs) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('zzz(%cx)'), 0, 'zzz(cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%cx,%rbx)'), 0, 'zzz(cx,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%cx,%si)'), 0, 'zzz(cx,si) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%cx,2)'), 0, 'zzz(cx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%rbx,%cx)'), 0, 'zzz(rbx,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%rbx,2)'), 0, 'zzz(rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(2,%cx)'), 0, 'zzz(2,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(2,%rbx)'), 0, 'zzz(2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%cx,%rbx,2)'), 0, 'zzz(cx,rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%si,%cx)'), 0, 'zzz(si,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%cx,%rbx,2)'), 0, 'zzz(cx,rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%rbx,%cx,2)'), 0, 'zzz(rbx,cx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%cx,2,%rbx)'), 0, 'zzz(cx,2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%rbx,2,%cx)'), 0, 'zzz(rbx,2,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(2,%cx,%rbx)'), 0, 'zzz(2,cx,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(2,%rbx,%cx)'), 0, 'zzz(2,rbx,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('zzz(%rax ,%rsp, 2)'), 0, 'zzz(%rax ,%rsp, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%cs:(%cs)'), 0, '%cs:(cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%cr0)'), 0, '%cs:(cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(-%rbx)'), 0, '%cs:(-rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(-%bx)'), 0, '%cs:(-bx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(xxx)'), 1, '%cs:(xxx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%cs,%rbx)'), 0, '%cs:(cs,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%cs,2)'), 0, '%cs:(cs,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rbx,%cs)'), 0, '%cs:(rbx,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(2,%cs)'), 0, '%cs:(2,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%cs,%rbx,2)'), 0, '%cs:(cs,rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rbx,%cs,2)'), 0, '%cs:(rbx,cs,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%cs,2,%rbx)'), 0, '%cs:(cs,2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rbx,2,%cs)'), 0, '%cs:(rbx,2,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(2,%cs,%rbx)'), 0, '%cs:(2,cs,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(2,%rbx,%cs)'), 0, '%cs:(2,rbx,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(-%rbx)'), 0, '%cs:(-rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(ca)'), 1, '%cs:(ca) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rcx)'), 1, '%cs:(rcx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%ecx, %ebx, 1)'), 1, '%cs:(%ecx, %ebx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:1(%ecx, %ebx, 1)'), 1, '%cs:1(%ecx, %ebx, 1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rax ,%rsp, 2)'), 0, '%cs:(%rax ,%rsp, 2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:%cx(%rax,%rbx,2)'), 0, '%cs:%cx(%rax,%rbx,2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%cs:(%cx)'), 0, '%cs:(cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%cx,%rbx)'), 0, '%cs:(cx,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%cx,2)'), 0, '%cs:(cx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rbx,%cx)'), 0, '%cs:(rbx,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rbx,2)'), 0, '%cs:(rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(2,%cx)'), 0, '%cs:(2,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(2,%rbx)'), 0, '%cs:(2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%cx,%rbx,2)'), 0, '%cs:(cx,rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%cx,%rbx,2)'), 0, '%cs:(cx,rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%cx,%si,2)'), 0, '%cs:(cx,si,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rbx,%cx,2)'), 0, '%cs:(rbx,cx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%si,%cx,2)'), 0, '%cs:(si,cx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%cx,2,%rbx)'), 0, '%cs:(cx,2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rbx,2,%cx)'), 0, '%cs:(rbx,2,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(2,%cx,%rbx)'), 0, '%cs:(2,cx,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(2,%rbx,%cx)'), 0, '%cs:(2,rbx,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(-%cx)'), 0, '%cs:(-cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rcx,%rbx)'), 1, '%cs:(rcx,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%cx,%erbx)'), 0, '%cs:(cx,erbx) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%cs:(bsi,%cx,2)'), 0, '%cs:(bsi,cx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%si,bcx,2)'), 0, '%cs:(si,bcx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rsi,%rcx,1)'), 1, '%cs:(rsi,rcx,1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rsi,%rcx,2)'), 1, '%cs:(rsi,rcx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rsi,%rcx,4)'), 1, '%cs:(rsi,rcx,4) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rsi,%rcx,8)'), 1, '%cs:(rsi,rcx,8) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:(%rsi,%rcx,5)'), 0, '%cs:(rsi,rcx,5) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%cx:(%cs)'), 0, '%cx:(cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:(%cs,%rbx)'), 0, '%cx:(cs,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:(%cs,2)'), 0, '%cx:(cs,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:(%rbx,%cs)'), 0, '%cx:(rbx,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:(2,%cs)'), 0, '%cx:(2,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:(%cs,%rbx,2)'), 0, '%cx:(cs,rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:(%rbx,%cs,2)'), 0, '%cx:(rbx,cs,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:(%cs,2,%rbx)'), 0, '%cx:(cs,2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:(%rbx,2,%cs)'), 0, '%cx:(rbx,2,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:(2,%cs,%rbx)'), 0, '%cx:(2,cs,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:(2,%rbx,%cs)'), 0, '%cx:(2,rbx,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:(-%rbx)'), 0, '%cx:(-rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:(ca)'), 0, '%cx:(ca) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%cs:zzz(%cs)'), 0, '%cs:zzz(cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%cr0)'), 0, '%cs:zzz(cr0) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(-%rbx)'), 0, '%cs:zzz(-rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(-%bx)'), 0, '%cs:zzz(-bx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(xxx)'), 0, '%cs:zzz(xxx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%cs,%rbx)'), 0, '%cs:zzz(cs,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%cs,2)'), 0, '%cs:zzz(cs,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%rbx,%cs)'), 0, '%cs:zzz(rbx,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(2,%cs)'), 0, '%cs:zzz(2,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%cs,%rbx,2)'), 0, '%cs:zzz(cs,rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%rbx,%cs,2)'), 0, '%cs:zzz(rbx,cs,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%cs,2,%rbx)'), 0, '%cs:zzz(cs,2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%rbx,2,%cs)'), 0, '%cs:zzz(rbx,2,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(2,%cs,%rbx)'), 0, '%cs:zzz(2,cs,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(2,%rbx,%cs)'), 0, '%cs:zzz(2,rbx,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(-%rbx)'), 0, '%cs:zzz(-rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(ca)'), 0, '%cs:zzz(ca) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%rcx)'), 1, '%cs:zzz(rcx) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%cs:zzz(%cx)'), 0, '%cs:zzz(cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%cx,%rbx)'), 0, '%cs:zzz(cx,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%cx,%si)'), 0, '%cs:zzz(cx,si) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%cx,2)'), 0, '%cs:zzz(cx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%rbx,%cx)'), 0, '%cs:zzz(rbx,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%rbx,2)'), 0, '%cs:zzz(rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(2,%cx)'), 0, '%cs:zzz(2,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(2,%rbx)'), 0, '%cs:zzz(2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%cx,%rbx,2)'), 0, '%cs:zzz(cx,rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%si,%cx)'), 0, '%cs:zzz(si,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%cx,%rbx,2)'), 0, '%cs:zzz(cx,rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%cx,%si,2)'), 0, '%cs:zzz(cx,si,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%rbx,%cx,2)'), 0, '%cs:zzz(rbx,cx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%si,%cx,2)'), 0, '%cs:zzz(si,cx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%cx,2,%rbx)'), 0, '%cs:zzz(cx,2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%rbx,2,%cx)'), 0, '%cs:zzz(rbx,2,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(2,%cx,%rbx)'), 0, '%cs:zzz(2,cx,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(2,%rbx,%cx)'), 0, '%cs:zzz(2,rbx,cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(-%cx)'), 0, '%cs:zzz(-cx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%rcx,%rbx)'), 1, '%cs:zzz(rcx,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%cx,%erbx)'), 0, '%cs:zzz(cx,erbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cs:zzz(%rax ,%rsp, 2)'), 0, '%cs:zzz(%rax ,%rsp, 2) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%cx:zzz(%cs)'), 0, '%cx:zzz(cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:zzz(%cs,%rbx)'), 0, '%cx:zzz(cs,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:zzz(%cs,2)'), 0, '%cx:zzz(cs,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:zzz(%rbx,%cs)'), 0, '%cx:zzz(rbx,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:zzz(2,%cs)'), 0, '%cx:zzz(2,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:zzz(%cs,%rbx,2)'), 0, '%cx:zzz(cs,rbx,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:zzz(%rbx,%cs,2)'), 0, '%cx:zzz(rbx,cs,2) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:zzz(%cs,2,%rbx)'), 0, '%cx:zzz(cs,2,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:zzz(%rbx,2,%cs)'), 0, '%cx:zzz(rbx,2,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:zzz(2,%cs,%rbx)'), 0, '%cx:zzz(2,cs,rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:zzz(2,%rbx,%cs)'), 0, '%cx:zzz(2,rbx,cs) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:zzz(-%rbx)'), 0, '%cx:zzz(-rbx) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%cx:zzz(ca)'), 0, '%cx:zzz(ca) is a valid 64-bit addressing scheme' );

is ( is_valid_64bit_addr_att ('%cs:%bx(,1)'), 0, '%cs:%bx(,1) is a valid 64-bit addressing scheme' );
is ( is_valid_64bit_addr_att ('%ax:zzz(,1)'), 0, '%ax:zzz(,1) is a valid 64-bit addressing scheme' );

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
