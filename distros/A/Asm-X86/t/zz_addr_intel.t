#!perl -T -w

use strict;
use warnings;

use Test::More tests => (5*4)*3 + 33 + (36*3 + 21)*2 + 3 + 21;
use Asm::X86 qw(is_valid_16bit_addr_intel is_valid_32bit_addr_intel
	is_valid_64bit_addr_intel is_valid_addr_intel);

# ----------- 16-bit

is ( is_valid_16bit_addr_intel ("[bX]"), 1, "[bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[sI]"), 1, "[si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[Di]"), 1, "[di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[Bp]"), 1, "[bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("[bx+bx]"), 0, "[bx+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[bx+Si]"), 1, "[bx+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[bX+di]"), 1, "[bx+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[bx+bp]"), 0, "[bx+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("[sI+bx]"), 1, "[si+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[si+si]"), 0, "[si+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[si+dI]"), 0, "[si+dI] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[si+bP]"), 1, "[si+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("[di+Bx]"), 1, "[di+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[di+Si]"), 0, "[di+Si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[di+di]"), 0, "[di+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[Di+bp]"), 1, "[di+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("[bp+bX]"), 0, "[bp+bX] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[bP+si]"), 1, "[bp+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[bp+Di]"), 1, "[bp+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[bp+bP]"), 0, "[bp+bP] is a valid 16-bit addressing scheme" );

# -----------

is ( is_valid_16bit_addr_intel ("cs:[bx]"), 1, "cs:[bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("cs:[si]"), 1, "cs:[si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("cs:[di]"), 1, "cs:[di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("cs:[bp]"), 1, "cs:[bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("ds:[bx+bx]"), 0, "ds:[bx+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("ds:[bx+si]"), 1, "ds:[bx+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("ds:[bx+di]"), 1, "ds:[bx+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("ds:[bx+bp]"), 0, "ds:[bx+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("es:[si+bx]"), 1, "es:[si+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("es:[si+si]"), 0, "es:[si+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("es:[si+dI]"), 0, "es:[si+dI] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("es:[si+bp]"), 1, "es:[si+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("fs:[di+bx]"), 1, "fs:[di+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("fs:[di+Si]"), 0, "fs:[di+Si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("gs:[di+di]"), 0, "gs:[di+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("gs:[di+bp]"), 1, "gs:[di+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("ss:[bp+bX]"), 0, "ss:[bp+bX] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("ss:[bp+si]"), 1, "ss:[bp+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("ss:[bp+di]"), 1, "ss:[bp+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("ss:[bp+bP]"), 0, "ss:[bp+bP] is a valid 16-bit addressing scheme" );

# -----------

is ( is_valid_16bit_addr_intel ("[cs:bx]"), 1, "[cs:bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[cs:si]"), 1, "[cs:si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[cs:di]"), 1, "[cs:di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[cs:bp]"), 1, "[cs:bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("[ds:bx+bx]"), 0, "[ds:bx+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[ds:bx+si]"), 1, "[ds:bx+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[ds:bx+di]"), 1, "[ds:bx+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[ds:bx+bp]"), 0, "[ds:bx+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("[es:si+bx]"), 1, "[es:si+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[es:si+si]"), 0, "[es:si+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[es:si+dI]"), 0, "[es:si+dI] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[es:si+bp]"), 1, "[es:si+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("[fs:di+bx]"), 1, "[fs:di+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[fs:di+Si]"), 0, "[fs:di+Si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[gs:di+di]"), 0, "[gs:di+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[gs:di+bp]"), 1, "[gs:di+bp] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("[ss:bp+bX]"), 0, "[ss:bp+bX] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[ss:bp+si]"), 1, "[ss:bp+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[ss:bp+di]"), 1, "[ss:bp+di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[ss:bp+bP]"), 0, "[ss:bp+bP] is a valid 16-bit addressing scheme" );

# -----------

is ( is_valid_16bit_addr_intel ("[ax]"), 0, "[ax] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[bx+cx]"), 0, "[bx+cx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[cx+bx]"), 0, "[cx+bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[bp+al]"), 0, "[bp+al] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[ch+si]"), 0, "[ch+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[bx-si]"), 0, "[bx-si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[bp-2]"), 1, "[bp-2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[bp-varname]"), 1, "[bp-2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[si-ax]"), 0, "[si-ax] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[bp+-2]"), 1, "[bp+-2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[bp+-si]"), 0, "[bp+-si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("ad:[bx]"), 0, "ad:[bx] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[sc:di]"), 0, "[sc:di] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[2+bp]"), 1, "[2+bp] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[-3+si]"), 1, "[-3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[++-3+si]"), 1, "[++-3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[3-si]"), 0, "[3-si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[--3+si]"), 1, "[--3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[-3-si]"), 0, "[-3-si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[3+5]"), 1, "[3+5] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[-3]"), 1, "[-3] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[-3+2]"), 1, "[-3+2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[+2]"), 1, "[+2] is a valid 16-bit addressing scheme" );

is ( is_valid_16bit_addr_intel ("[cs:--3+si]"), 1, "[cs:--3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("cs:[--3+si]"), 1, "cs:[--3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("ds:[+2]"), 1, "ds:[+2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[ds:+2]"), 1, "[ds:+2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("ss:[-3]"), 1, "ss:[-3] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[ss:-3+2]"), 1, "[ss:-3+2] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[es:2+bp]"), 1, "[es:2+bp] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("eS:[2+bp]"), 1, "es:[2+bp] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("fs:[++-3+si]"), 1, "fs:[++-3+si] is a valid 16-bit addressing scheme" );
is ( is_valid_16bit_addr_intel ("[fs:++-3+si]"), 1, "[fs:++-3+si] is a valid 16-bit addressing scheme" );

# ----------- 32-bit

is ( is_valid_32bit_addr_intel ("[eax]"), 1, "[eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[beax]"), 1, "[beax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[eaxd]"), 1, "[eaxd] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("[ebx+77]"), 1, "[ebx+77] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ebx+ecx]"), 1, "[ebx+ecx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ebx+ebx+99]"), 1, "[ebx+ebx+99] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ebx+edi-88]"), 1, "[ebx+edi-88] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ebx+edi+-88]"), 1, "[ebx+edi+-88] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("[ebx+eax*2]"), 1, "[ebx+eax*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ebx+esi*4+66]"), 1, "[ebx+esi*4+66] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ebx+ecx*8-55]"), 1, "[ebx+ecx*8-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ebx+ecx*8+-55]"), 1, "[ebx+ecx*8+-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ebx+ebp*1]"), 1, "[ebx+ebp*1] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("[ecx*2 + ebx]"), 1, "[ecx*2 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ecx*4 + ebx -1]"), 1, "[ecx*4 + ebx -1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ecx*4 + ebx +-1]"), 1, "[ecx*4 + ebx +-1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ecx*8 + ebx+ 44]"), 1, "[ecx*2 + ebx+ 44] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ecx*1 + esp]"), 1, "[ecx*1 + esp] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ecx*4 -1 + ebx]"), 1, "[ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ecx*4 +-1 + ebx]"), 1, "[ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ecx*8 +44 + ebx]"), 1, "[ecx*2 +44+ ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ecx*4 -1 + ebx]"), 1, "[ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ecx*4 +-1 + ebx]"), 1, "[ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("[ecx*2]"), 1, "[ecx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[esp*1]"), 1, "[esp*1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[esp*4]"), 0, "[esp*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ecx*2 + ebx*8]"), 0, "[ecx*2 + ebx*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ecx + esp*2]"), 0, "[ecx + esp*2] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("[1+eax]"), 1, "[1+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[-2+edx]"), 1, "[-2+edx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[3+ebx*2]"), 1, "[3+ebx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[-4+esi*4]"), 1, "[-4+esi*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[5+ecx+esi]"), 1, "[5+ecx+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[-6+ecx*2+edi]"), 1, "[-6+ecx*2+edi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[7+esp+ebp*8]"), 1, "[7+esp+ebp*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[-8+esp+ebp*8]"), 1, "[-8+esp+ebp*8] is a valid 32-bit addressing scheme" );

# -----------

is ( is_valid_32bit_addr_intel ("cs:[eax]"), 1, "cs:[eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("cs:[beax]"), 1, "cs:[beax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("cs:[eaxd]"), 1, "cs:[eaxd] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("ds:[ebx+77]"), 1, "ds:[ebx+77] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("ds:[ebx+ecx]"), 1, "ds:[ebx+ecx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("ds:[ebx+ebx+99]"), 1, "ds:[ebx+ebx+99] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("ds:[ebx+edi-88]"), 1, "ds:[ebx+edi-88] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("ds:[ebx+edi+-88]"), 1, "ds:[ebx+edi+-88] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("es:[ebx+eax*2]"), 1, "es:[ebx+eax*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("es:[ebx+esi*4+66]"), 1, "es:[ebx+esi*4+66] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("es:[ebx+ecx*8-55]"), 1, "es:[ebx+ecx*8-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("es:[ebx+ecx*8+-55]"), 1, "es:[ebx+ecx*8+-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("es:[ebx+ebp*1]"), 1, "es:[ebx+ebp*1] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("fs:[ecx*2 + ebx]"), 1, "fs:[ecx*2 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("fs:[ecx*4 + ebx -1]"), 1, "fs:[ecx*4 + ebx -1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("fs:[ecx*4 + ebx +-1]"), 1, "fs:[ecx*4 + ebx +-1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("fs:[ecx*8 + ebx+ 44]"), 1, "fs:[ecx*2 + ebx+ 44] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("fs:[ecx*1 + esp]"), 1, "fs:[ecx*1 + esp] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("fs:[ecx*4 -1 + ebx]"), 1, "fs:[ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("fs:[ecx*4 +-1 + ebx]"), 1, "fs:[ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("fs:[ecx*8 +44 + ebx]"), 1, "fs:[ecx*2 +44+ ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("fs:[ecx*4 -1 + ebx]"), 1, "fs:[ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("fs:[ecx*4 +-1 + ebx]"), 1, "fs:[ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("gs:[ecx*2]"), 1, "gs:[ecx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("gs:[esp*1]"), 1, "gs:[esp*1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("gs:[esp*4]"), 0, "gs:[esp*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("gs:[ecx*2 + ebx*8]"), 0, "gs:[ecx*2 + ebx*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("gs:[ecx + esp*2]"), 0, "gs:[ecx + esp*2] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("ss:[1+eax]"), 1, "ss:[1+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("ss:[-2+edx]"), 1, "ss:[-2+edx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("ss:[3+ebx*2]"), 1, "ss:[3+ebx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("ss:[-4+esi*4]"), 1, "ss:[-4+esi*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("ss:[5+ecx+esi]"), 1, "ss:[5+ecx+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("ss:[-6+ecx*2+edi]"), 1, "ss:[-6+ecx*2+edi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("ss:[7+esp+ebp*8]"), 1, "ss:[7+esp+ebp*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("ss:[-8+esp+ebp*8]"), 1, "ss:[-8+esp+ebp*8] is a valid 32-bit addressing scheme" );

# -----------

is ( is_valid_32bit_addr_intel ("[ss:eax]"), 1, "[ss:eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ss:beax]"), 1, "[ss:beax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ss:eaxd]"), 1, "[ss:eaxd] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("[gs:ebx+77]"), 1, "[gs:ebx+77] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[gs:ebx+ecx]"), 1, "[gs:ebx+ecx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[gs:ebx+ebx+99]"), 1, "[gs:ebx+ebx+99] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[gs:ebx+edi-88]"), 1, "[gs:ebx+edi-88] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[gs:ebx+edi+-88]"), 1, "[gs:ebx+edi+-88] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("[fs:ebx+eax*2]"), 1, "[fs:ebx+eax*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[fs:ebx+esi*4+66]"), 1, "[fs:ebx+esi*4+66] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[fs:ebx+ecx*8-55]"), 1, "[fs:ebx+ecx*8-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[fs:ebx+ecx*8+-55]"), 1, "[fs:ebx+ecx*8+-55] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[fs:ebx+ebp*1]"), 1, "[fs:ebx+ebp*1] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("[es:ecx*2 + ebx]"), 1, "[es:ecx*2 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[es:ecx*4 + ebx -1]"), 1, "[es:ecx*4 + ebx -1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[es:ecx*4 + ebx +-1]"), 1, "[es:ecx*4 + ebx +-1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[es:ecx*8 + ebx+ 44]"), 1, "[es:ecx*2 + ebx+ 44] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[es:ecx*1 + esp]"), 1, "[es:ecx*1 + esp] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[es:ecx*4 -1 + ebx]"), 1, "[es:ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[es:ecx*4 +-1 + ebx]"), 1, "[es:ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[es:ecx*8 +44 + ebx]"), 1, "[es:ecx*2 +44+ ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[es:ecx*4 -1 + ebx]"), 1, "[es:ecx*4 -1 + ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[es:ecx*4 +-1 + ebx]"), 1, "[es:ecx*4 +-1 + ebx] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("[ds:ecx*2]"), 1, "[ds:ecx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ds:esp*1]"), 1, "[ds:esp*1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ds:esp*4]"), 0, "[ds:esp*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ds:ecx*2 + ebx*8]"), 0, "[ds:ecx*2 + ebx*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ds:ecx + esp*2]"), 0, "[ds:ecx + esp*2] is a valid 32-bit addressing scheme" );

is ( is_valid_32bit_addr_intel ("[cs:1+eax]"), 1, "[cs:1+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[cs:-2+edx]"), 1, "[cs:-2+edx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[cs:3+ebx*2]"), 1, "[cs:3+ebx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[cs:-4+esi*4]"), 1, "[cs:-4+esi*4] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[cs:5+ecx+esi]"), 1, "[cs:5+ecx+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[cs:-6+ecx*2+edi]"), 1, "[cs:-6+ecx*2+edi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[cs:7+esp+ebp*8]"), 1, "[cs:7+esp+ebp*8] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[cs:-8+esp+ebp*8]"), 1, "[cs:-8+esp+ebp*8] is a valid 32-bit addressing scheme" );

# -----------

is ( is_valid_32bit_addr_intel ("[cr0+1]"), 0, "[cr0+1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[eax+cr0+1]"), 0, "[eax+cr0+1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[cr0+ebx*2+2]"), 0, "[cr0+ebx*2+2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[st7-1]"), 0, "[st7-1] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[dr2-2+eax]"), 0, "[dr2-2+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[xmm3]"), 0, "[xmm3] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[mm2]"), 0, "[mm2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[eax+xmm3]"), 0, "[eax+xmm3] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[eax+mm2]"), 0, "[eax+mm2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[eax+ebx*2+xmm3]"), 0, "[eax+ebx*2+xmm3] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[eax+ebx*2+mm2]"), 0, "[eax+ebx*2+mm2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[eax-ebx]"), 0, "[eax-ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[eax-ebx*2]"), 0, "[eax-ebx*2] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[eax+3-ecx]"), 0, "[eax+3-ecx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[eax+6*2+esp]"), 1, "[eax+6*2+esp] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[eax+2*ebx]"), 1, "[eax+2*ebx] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[4*eax+esi]"), 1, "[4*eax+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[-1+4*eax+esi]"), 1, "[-1+4*eax+esi] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[r12d+eax]"), 0, "[r12d+eax] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[ebx+2*r8d]"), 0, "[ebx+2*r8d] is a valid 32-bit addressing scheme" );
is ( is_valid_32bit_addr_intel ("[edx+8*r9d+1]"), 0, "[edx+8*r9d+1] is a valid 32-bit addressing scheme" );

# ----------- 64-bit

is ( is_valid_64bit_addr_intel ("[rax]"), 1, "[rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[brax]"), 1, "[brax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[raxd]"), 1, "[raxd] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("[rbx+77]"), 1, "[rbx+77] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rbx+rcx]"), 1, "[rbx+rcx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rbx+rbx+99]"), 1, "[rbx+rbx+99] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rbx+rdi-88]"), 1, "[rbx+rdi-88] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rbx+rdi+-88]"), 1, "[rbx+rdi+-88] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("[rbx+rax*2]"), 1, "[rbx+rax*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rbx+rsi*4+66]"), 1, "[rbx+rsi*4+66] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rbx+rcx*8-55]"), 1, "[rbx+rcx*8-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rbx+rcx*8+-55]"), 1, "[rbx+rcx*8+-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rbx+rbp*1]"), 1, "[rbx+rbp*1] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("[rcx*2 + rbx]"), 1, "[rcx*2 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rcx*4 + rbx -1]"), 1, "[rcx*4 + rbx -1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rcx*4 + rbx +-1]"), 1, "[rcx*4 + rbx +-1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rcx*8 + rbx+ 44]"), 1, "[rcx*2 + rbx+ 44] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rcx*1 + rsp]"), 1, "[rcx*1 + rsp] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rcx*4 -1 + rbx]"), 1, "[rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rcx*4 +-1 + rbx]"), 1, "[rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rcx*8 +44 + rbx]"), 1, "[rcx*2 +44+ rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rcx*4 -1 + rbx]"), 1, "[rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rcx*4 +-1 + rbx]"), 1, "[rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("[rcx*2]"), 1, "[rcx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rsp*1]"), 1, "[rsp*1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rsp*4]"), 0, "[rsp*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rcx*2 + rbx*8]"), 0, "[rcx*2 + rbx*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rcx + rsp*2]"), 0, "[rcx + rsp*2] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("[1+rax]"), 1, "[1+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[-2+rdx]"), 1, "[-2+rdx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[3+rbx*2]"), 1, "[3+rbx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[-4+rsi*4]"), 1, "[-4+rsi*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[5+rcx+rsi]"), 1, "[5+rcx+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[-6+rcx*2+rdi]"), 1, "[-6+rcx*2+rdi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[7+rsp+rbp*8]"), 1, "[7+rsp+rbp*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[-8+rsp+rbp*8]"), 1, "[-8+rsp+rbp*8] is a valid 64-bit addressing scheme" );

# -----------

is ( is_valid_64bit_addr_intel ("cs:[rax]"), 1, "cs:[rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("cs:[brax]"), 1, "cs:[brax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("cs:[raxd]"), 1, "cs:[raxd] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("ds:[rbx+77]"), 1, "ds:[rbx+77] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("ds:[rbx+rcx]"), 1, "ds:[rbx+rcx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("ds:[rbx+rbx+99]"), 1, "ds:[rbx+rbx+99] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("ds:[rbx+rdi-88]"), 1, "ds:[rbx+rdi-88] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("ds:[rbx+rdi+-88]"), 1, "ds:[rbx+rdi+-88] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("es:[rbx+rax*2]"), 1, "es:[rbx+rax*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("es:[rbx+rsi*4+66]"), 1, "es:[rbx+rsi*4+66] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("es:[rbx+rcx*8-55]"), 1, "es:[rbx+rcx*8-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("es:[rbx+rcx*8+-55]"), 1, "es:[rbx+rcx*8+-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("es:[rbx+rbp*1]"), 1, "es:[rbx+rbp*1] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("fs:[rcx*2 + rbx]"), 1, "fs:[rcx*2 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("fs:[rcx*4 + rbx -1]"), 1, "fs:[rcx*4 + rbx -1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("fs:[rcx*4 + rbx +-1]"), 1, "fs:[rcx*4 + rbx +-1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("fs:[rcx*8 + rbx+ 44]"), 1, "fs:[rcx*2 + rbx+ 44] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("fs:[rcx*1 + rsp]"), 1, "fs:[rcx*1 + rsp] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("fs:[rcx*4 -1 + rbx]"), 1, "fs:[rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("fs:[rcx*4 +-1 + rbx]"), 1, "fs:[rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("fs:[rcx*8 +44 + rbx]"), 1, "fs:[rcx*2 +44+ rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("fs:[rcx*4 -1 + rbx]"), 1, "fs:[rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("fs:[rcx*4 +-1 + rbx]"), 1, "fs:[rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("gs:[rcx*2]"), 1, "gs:[rcx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("gs:[rsp*1]"), 1, "gs:[rsp*1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("gs:[rsp*4]"), 0, "gs:[rsp*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("gs:[rcx*2 + rbx*8]"), 0, "gs:[rcx*2 + rbx*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("gs:[rcx + rsp*2]"), 0, "gs:[rcx + rsp*2] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("ss:[1+rax]"), 1, "ss:[1+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("ss:[-2+rdx]"), 1, "ss:[-2+rdx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("ss:[3+rbx*2]"), 1, "ss:[3+rbx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("ss:[-4+rsi*4]"), 1, "ss:[-4+rsi*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("ss:[5+rcx+rsi]"), 1, "ss:[5+rcx+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("ss:[-6+rcx*2+rdi]"), 1, "ss:[-6+rcx*2+rdi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("ss:[7+rsp+rbp*8]"), 1, "ss:[7+rsp+rbp*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("ss:[-8+rsp+rbp*8]"), 1, "ss:[-8+rsp+rbp*8] is a valid 64-bit addressing scheme" );

# -----------

is ( is_valid_64bit_addr_intel ("[ss:rax]"), 1, "[ss:rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[ss:brax]"), 1, "[ss:brax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[ss:raxd]"), 1, "[ss:raxd] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("[gs:rbx+77]"), 1, "[gs:rbx+77] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[gs:rbx+rcx]"), 1, "[gs:rbx+rcx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[gs:rbx+rbx+99]"), 1, "[gs:rbx+rbx+99] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[gs:rbx+rdi-88]"), 1, "[gs:rbx+rdi-88] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[gs:rbx+rdi+-88]"), 1, "[gs:rbx+rdi+-88] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("[fs:rbx+rax*2]"), 1, "[fs:rbx+rax*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[fs:rbx+rsi*4+66]"), 1, "[fs:rbx+rsi*4+66] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[fs:rbx+rcx*8-55]"), 1, "[fs:rbx+rcx*8-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[fs:rbx+rcx*8+-55]"), 1, "[fs:rbx+rcx*8+-55] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[fs:rbx+rbp*1]"), 1, "[fs:rbx+rbp*1] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("[es:rcx*2 + rbx]"), 1, "[es:rcx*2 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[es:rcx*4 + rbx -1]"), 1, "[es:rcx*4 + rbx -1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[es:rcx*4 + rbx +-1]"), 1, "[es:rcx*4 + rbx +-1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[es:rcx*8 + rbx+ 44]"), 1, "[es:rcx*2 + rbx+ 44] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[es:rcx*1 + rsp]"), 1, "[es:rcx*1 + rsp] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[es:rcx*4 -1 + rbx]"), 1, "[es:rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[es:rcx*4 +-1 + rbx]"), 1, "[es:rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[es:rcx*8 +44 + rbx]"), 1, "[es:rcx*2 +44+ rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[es:rcx*4 -1 + rbx]"), 1, "[es:rcx*4 -1 + rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[es:rcx*4 +-1 + rbx]"), 1, "[es:rcx*4 +-1 + rbx] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("[ds:rcx*2]"), 1, "[ds:rcx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[ds:rsp*1]"), 1, "[ds:rsp*1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[ds:rsp*4]"), 0, "[ds:rsp*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[ds:rcx*2 + rbx*8]"), 0, "[ds:rcx*2 + rbx*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[ds:rcx + rsp*2]"), 0, "[ds:rcx + rsp*2] is a valid 64-bit addressing scheme" );

is ( is_valid_64bit_addr_intel ("[cs:1+rax]"), 1, "[cs:1+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[cs:-2+rdx]"), 1, "[cs:-2+rdx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[cs:3+rbx*2]"), 1, "[cs:3+rbx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[cs:-4+rsi*4]"), 1, "[cs:-4+rsi*4] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[cs:5+rcx+rsi]"), 1, "[cs:5+rcx+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[cs:-6+rcx*2+rdi]"), 1, "[cs:-6+rcx*2+rdi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[cs:7+rsp+rbp*8]"), 1, "[cs:7+rsp+rbp*8] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[cs:-8+rsp+rbp*8]"), 1, "[cs:-8+rsp+rbp*8] is a valid 64-bit addressing scheme" );

# -----------

is ( is_valid_64bit_addr_intel ("[cr0+1]"), 0, "[cr0+1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rax+cr0+1]"), 0, "[rax+cr0+1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[cr0+rbx*2+2]"), 0, "[cr0+rbx*2+2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[st7-1]"), 0, "[st7-1] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[dr2-2+rax]"), 0, "[dr2-2+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[xmm3]"), 0, "[xmm3] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[mm2]"), 0, "[mm2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rax+xmm3]"), 0, "[rax+xmm3] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rax+mm2]"), 0, "[rax+mm2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rax+rbx*2+xmm3]"), 0, "[rax+rbx*2+xmm3] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rax+rbx*2+mm2]"), 0, "[rax+rbx*2+mm2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rax-rbx]"), 0, "[rax-rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rax-rbx*2]"), 0, "[rax-rbx*2] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rax+3-rcx]"), 0, "[rax+3-rcx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rax+6*2+rsp]"), 1, "[rax+6*2+rsp] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rax+2*rbx]"), 1, "[rax+2*rbx] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[4*rax+rsi]"), 1, "[4*rax+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[-1+4*rax+rsi]"), 1, "[-1+4*rax+rsi] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[r12d+rax]"), 0, "[r12d+rax] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rbx+2*r8d]"), 0, "[rbx+2*r8d] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[rdx+8*r9d+1]"), 0, "[rdx+8*r9d+1] is a valid 64-bit addressing scheme" );
# the extra 3:
is ( is_valid_64bit_addr_intel ("[ebx+r10d]"), 1, "[ebx+r10d] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[ebx+2*r8d]"), 1, "[ebx+2*r8d] is a valid 64-bit addressing scheme" );
is ( is_valid_64bit_addr_intel ("[edx+8*r9d+1]"), 1, "[edx+8*r9d+1] is a valid 64-bit addressing scheme" );

# ----------- mixed

is ( is_valid_addr_intel ("[ebx+ax]"), 0, "[ebx+ax] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[si+eax]"), 0, "[si+eax] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[ebx+2+ax]"), 0, "[ebx+2+ax] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[2*ebx-cx]"), 0, "[2*ebx-cx] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[esi*8+si]"), 0, "[esi*8+si] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[edi+sp]"), 0, "[edi+sp] is a valid addressing scheme" );

is ( is_valid_addr_intel ("[rax+ebx]"), 0, "[rax+ebx] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[rbx+r8d]"), 0, "[rbx+r8d] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[ecx+rsi]"), 0, "[ecx+rsi] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[ecx*2+rsi]"), 0, "[ecx*2+rsi] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[+-1+ecx+edx]"), 1, "[+-1+ecx+edx] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[+-1+ecx+rdx]"), 0, "[+-1+ecx+rdx] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[+-1+ecx*8+rdx]"), 0, "[+-1+ecx*8+rdx] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[+-1+rdx+ecx*8]"), 0, "[+-1+rdx+ecx*8] is a valid  addressing scheme" );
is ( is_valid_addr_intel ("[esi+-1+rax]"), 0, "[esi+-1+rax] is a valid  addressing scheme" );
is ( is_valid_addr_intel ("[esi-rcx]"), 0, "[esi-rcx] is a valid  addressing scheme" );
is ( is_valid_addr_intel ("[+1-rcx]"), 0, "[+1-rcx] is a valid  addressing scheme" );
is ( is_valid_addr_intel ("[-1-rcx]"), 0, "[-1-rcx] is a valid  addressing scheme" );

is ( is_valid_addr_intel ("[rax+6*2+rsp]"), 1, "[rax+6*2+rsp] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[cs:5+ecx+esi]"), 1, "[cs:5+ecx+esi] is a valid addressing scheme" );
is ( is_valid_addr_intel ("[ss:bp+si]"), 1, "[ss:bp+si] is a valid addressing scheme" );

#is ( is_valid_addr_intel ("[]"), 0, "[] is a valid addressing scheme" );
