#!perl -T -w

use strict;
use warnings;

use Test::More tests => 2*9 + (14*9 + 6 + 22) * 4;
use Asm::X86 qw(
	@regs8_intel @regs16_intel @segregs_intel @regs32_intel
		@regs64_intel @regs_mm_intel @regs_intel @regs_fpu_intel
		@regs_opmask_intel
	@regs8_att @regs16_att @segregs_att @regs32_att
		@regs64_att @regs_mm_att @regs_att @regs_fpu_att
		@regs_opmask_att
	is_reg_intel
	is_reg8_intel is_reg16_intel is_reg32_intel is_reg64_intel
	is_reg_mm_intel is_segreg_intel is_reg_fpu_intel is_reg_opmask_intel
	is_reg_att
	is_reg8_att is_reg16_att is_reg32_att is_reg64_att
	is_reg_mm_att is_segreg_att is_reg_fpu_att is_reg_opmask_att
	is_reg
	is_reg8 is_reg16 is_reg32 is_reg64
	is_reg_mm is_segreg is_reg_fpu is_reg_opmask
	);

cmp_ok ( $#regs8_intel,   '>', 0, "Non-empty 8-bit register list" );
cmp_ok ( $#regs16_intel,  '>', 0, "Non-empty 16-bit register list" );
cmp_ok ( $#segregs_intel, '>', 0, "Non-empty segment register list" );
cmp_ok ( $#regs32_intel,  '>', 0, "Non-empty 32-bit register list" );
cmp_ok ( $#regs64_intel,  '>', 0, "Non-empty 64-bit register list" );
cmp_ok ( $#regs_mm_intel, '>', 0, "Non-empty multimedia register list" );
cmp_ok ( $#regs_fpu_intel,'>', 0, "Non-empty FPU register list" );
cmp_ok ( $#regs_opmask_intel,'>', 0, "Non-empty opmask register list" );
cmp_ok ( $#regs_intel,    '>', 0, "Non-empty register list" );

cmp_ok ( $#regs8_att,   '>', 0, "Non-empty 8-bit register list" );
cmp_ok ( $#regs16_att,  '>', 0, "Non-empty 16-bit register list" );
cmp_ok ( $#segregs_att, '>', 0, "Non-empty segment register list" );
cmp_ok ( $#regs32_att,  '>', 0, "Non-empty 32-bit register list" );
cmp_ok ( $#regs64_att,  '>', 0, "Non-empty 64-bit register list" );
cmp_ok ( $#regs_mm_att, '>', 0, "Non-empty multimedia register list" );
cmp_ok ( $#regs_fpu_att,'>', 0, "Non-empty FPU register list" );
cmp_ok ( $#regs_opmask_att,'>', 0, "Non-empty opmask register list" );
cmp_ok ( $#regs_att,    '>', 0, "Non-empty register list" );

is ( is_reg_att   ("AL"), 0, "AL is a register" );
is ( is_reg8_att  ("AL"), 0, "AL is an 8-bit register" );
is ( is_reg16_att ("AL"), 0, "AL is a 16-bit register" );
is ( is_reg32_att ("AL"), 0, "AL is a 32-bit register" );
is ( is_reg64_att ("AL"), 0, "AL is a 64-bit register" );
is ( is_reg_mm_att("AL"), 0, "AL is a multimedia register" );
is ( is_segreg_att("AL"), 0, "AL is a segment register" );
is ( is_reg_fpu_att("AL"), 0, "AL is an FPU register" );
is ( is_reg_opmask_att("AL"), 0, "AL is an opmask register" );

is ( is_reg_att   ("r15b"), 0, "r15b is a register" );
is ( is_reg8_att  ("r15b"), 0, "r15b is an 8-bit register" );
is ( is_reg16_att ("r15b"), 0, "r15b is a 16-bit register" );
is ( is_reg32_att ("r15b"), 0, "r15b is a 32-bit register" );
is ( is_reg64_att ("r15b"), 0, "r15b is a 64-bit register" );
is ( is_reg_mm_att("r15b"), 0, "r15b is a multimedia register" );
is ( is_segreg_att("r15b"), 0, "r15b is a segment register" );
is ( is_reg_fpu_att("r15b"), 0, "r15b is an FPU register" );
is ( is_reg_opmask_att("r15b"), 0, "r15b is an opmask register" );

is ( is_reg_att   ("AX"), 0, "AX is a register" );
is ( is_reg8_att  ("AX"), 0, "AX is an 8-bit register" );
is ( is_reg16_att ("AX"), 0, "AX is a 16-bit register" );
is ( is_reg32_att ("AX"), 0, "AX is a 32-bit register" );
is ( is_reg64_att ("AX"), 0, "AX is a 64-bit register" );
is ( is_reg_mm_att("AX"), 0, "AX is a multimedia register" );
is ( is_segreg_att("AX"), 0, "AX is a segment register" );
is ( is_reg_fpu_att("AX"), 0, "AX is an FPU register" );
is ( is_reg_opmask_att("AX"), 0, "AX is an opmask register" );

is ( is_reg_att   ("r10w"), 0, "r10w is a register" );
is ( is_reg8_att  ("r10w"), 0, "r10w is an 8-bit register" );
is ( is_reg16_att ("r10w"), 0, "r10w is a 16-bit register" );
is ( is_reg32_att ("r10w"), 0, "r10w is a 32-bit register" );
is ( is_reg64_att ("r10w"), 0, "r10w is a 64-bit register" );
is ( is_reg_mm_att("r10w"), 0, "r10w is a multimedia register" );
is ( is_segreg_att("r10w"), 0, "r10w is a segment register" );
is ( is_reg_fpu_att("r10w"), 0, "r10w is an FPU register" );
is ( is_reg_opmask_att("r10w"), 0, "r10w is an opmask register" );

is ( is_reg_att   ("EBX"), 0, "EBX is a register" );
is ( is_reg8_att  ("EBX"), 0, "EBX is an 8-bit register" );
is ( is_reg16_att ("EBX"), 0, "EBX is a 16-bit register" );
is ( is_reg32_att ("EBX"), 0, "EBX is a 32-bit register" );
is ( is_reg64_att ("EBX"), 0, "EBX is a 64-bit register" );
is ( is_reg_mm_att("EBX"), 0, "EBX is a multimedia register" );
is ( is_segreg_att("EBX"), 0, "EBX is a segment register" );
is ( is_reg_fpu_att("EBX"), 0, "EBX is an FPU register" );
is ( is_reg_opmask_att("EBX"), 0, "AX is an opmask register" );

is ( is_reg_att   ("r8l"), 0, "r8l is a register" );
is ( is_reg8_att  ("r8l"), 0, "r8l EBX an 8-bit register" );
is ( is_reg16_att ("r8l"), 0, "r8l is a 16-bit register" );
is ( is_reg32_att ("r8l"), 0, "r8l is a 32-bit register" );
is ( is_reg64_att ("r8l"), 0, "r8l is a 64-bit register" );
is ( is_reg_mm_att("r8l"), 0, "r8l is a multimedia register" );
is ( is_segreg_att("r8l"), 0, "r8l is a segment register" );
is ( is_reg_fpu_att("r8l"), 0, "r8l is an FPU register" );
is ( is_reg_opmask_att("r8l"), 0, "r8l is an opmask register" );

is ( is_reg_att   ("rdi"), 0, "rdi is a register" );
is ( is_reg8_att  ("rdi"), 0, "rdi is an 8-bit register" );
is ( is_reg16_att ("rdi"), 0, "rdi is a 16-bit register" );
is ( is_reg32_att ("rdi"), 0, "rdi is a 32-bit register" );
is ( is_reg64_att ("rdi"), 0, "rdi is a 64-bit register" );
is ( is_reg_mm_att("rdi"), 0, "rdi is a multimedia register" );
is ( is_segreg_att("rdi"), 0, "rdi is a segment register" );
is ( is_reg_fpu_att("rdi"), 0, "rdi is an FPU register" );
is ( is_reg_opmask_att("rdi"), 0, "rdi is an opmask register" );

is ( is_reg_att   ("xmm9"), 0, "xmm9 is a register" );
is ( is_reg8_att  ("xmm9"), 0, "xmm9 is an 8-bit register" );
is ( is_reg16_att ("xmm9"), 0, "xmm9 is a 16-bit register" );
is ( is_reg32_att ("xmm9"), 0, "xmm9 is a 32-bit register" );
is ( is_reg64_att ("xmm9"), 0, "xmm9 is a 64-bit register" );
is ( is_reg_mm_att("xmm9"), 0, "xmm9 is a multimedia register" );
is ( is_segreg_att("xmm9"), 0, "xmm9 is a segment register" );
is ( is_reg_fpu_att("xmm9"), 0, "xmm9 is an FPU register" );
is ( is_reg_opmask_att("xmm9"), 0, "xmm9 is an opmask register" );

is ( is_reg_att   ("mm6"), 0, "mm6 is a register" );
is ( is_reg8_att  ("mm6"), 0, "mm6 is an 8-bit register" );
is ( is_reg16_att ("mm6"), 0, "mm6 is a 16-bit register" );
is ( is_reg32_att ("mm6"), 0, "mm6 is a 32-bit register" );
is ( is_reg64_att ("mm6"), 0, "mm6 is a 64-bit register" );
is ( is_reg_mm_att("mm6"), 0, "mm6 is a multimedia register" );
is ( is_segreg_att("mm6"), 0, "mm6 is a segment register" );
is ( is_reg_fpu_att("mm6"), 0, "mm6 is an FPU register" );
is ( is_reg_opmask_att("mm6"), 0, "mm6 is an opmask register" );

is ( is_reg_att   ("st0"), 0, "st0 is a register" );
is ( is_reg8_att  ("st0"), 0, "st0 is an 8-bit register" );
is ( is_reg16_att ("st0"), 0, "st0 is a 16-bit register" );
is ( is_reg32_att ("st0"), 0, "st0 is a 32-bit register" );
is ( is_reg64_att ("st0"), 0, "st0 is a 64-bit register" );
is ( is_reg_mm_att("st0"), 0, "st0 is a multimedia register" );
is ( is_segreg_att("st0"), 0, "st0 is a segment register" );
is ( is_reg_fpu_att("st0"), 0, "st0 is an FPU register" );
is ( is_reg_opmask_att("st0"), 0, "st0 is an opmask register" );

is ( is_reg_att   ("cs"), 0, "cs is a register" );
is ( is_reg8_att  ("ds"), 0, "ds is an 8-bit register" );
is ( is_reg16_att ("Es"), 0, "Es is a 16-bit register" );
is ( is_reg32_att ("ss"), 0, "ss is a 32-bit register" );
is ( is_reg64_att ("fS"), 0, "fS is a 64-bit register" );
is ( is_reg_mm_att("gs"), 0, "gs is a multimedia register" );
is ( is_segreg_att("cs"), 0, "cs is a segment register" );
is ( is_reg_fpu_att("ds"), 0, "ds is an FPU register" );
is ( is_reg_opmask_att("ds"), 0, "ds is an opmask register" );

is ( is_segreg_att("cs"), 0, "cs is a segment register" );
is ( is_segreg_att("ds"), 0, "ds is a segment register" );
is ( is_segreg_att("Es"), 0, "Es is a segment register" );
is ( is_segreg_att("ss"), 0, "ss is a segment register" );
is ( is_segreg_att("fS"), 0, "fS is a segment register" );
is ( is_segreg_att("gs"), 0, "gs is a segment register" );

is ( is_reg_att   ("ymm0"), 0, "ymm0 is a register" );
is ( is_reg8_att  ("ymm0"), 0, "ymm0 is an 8-bit register" );
is ( is_reg16_att ("ymm0"), 0, "ymm0 is a 16-bit register" );
is ( is_reg32_att ("ymm0"), 0, "ymm0 is a 32-bit register" );
is ( is_reg64_att ("ymm0"), 0, "ymm0 is a 64-bit register" );
is ( is_reg_mm_att("ymm0"), 0, "ymm0 is a multimedia register" );
is ( is_segreg_att("ymm0"), 0, "ymm0 is a segment register" );
is ( is_reg_fpu_att("ymm0"), 0, "ymm0 is an FPU register" );
is ( is_reg_opmask_att("ymm0"), 0, "ymm0 is an opmask register" );

is ( is_reg_att   ("zmm0"), 0, "zmm0 is a register" );
is ( is_reg8_att  ("zmm0"), 0, "zmm0 is an 8-bit register" );
is ( is_reg16_att ("zmm0"), 0, "zmm0 is a 16-bit register" );
is ( is_reg32_att ("zmm0"), 0, "zmm0 is a 32-bit register" );
is ( is_reg64_att ("zmm0"), 0, "zmm0 is a 64-bit register" );
is ( is_reg_mm_att("zmm0"), 0, "zmm0 is a multimedia register" );
is ( is_segreg_att("zmm0"), 0, "zmm0 is a segment register" );
is ( is_reg_fpu_att("zmm0"), 0, "zmm0 is an FPU register" );
is ( is_reg_opmask_att("zmm0"), 0, "zmm0 is an opmask register" );

is ( is_reg_att   ("k1"), 0, "k1 is a register" );
is ( is_reg8_att  ("k1"), 0, "k1 is an 8-bit register" );
is ( is_reg16_att ("k1"), 0, "k1 is a 16-bit register" );
is ( is_reg32_att ("k1"), 0, "k1 is a 32-bit register" );
is ( is_reg64_att ("k1"), 0, "k1 is a 64-bit register" );
is ( is_reg_mm_att("k1"), 0, "k1 is a multimedia register" );
is ( is_segreg_att("k1"), 0, "k1 is a segment register" );
is ( is_reg_fpu_att("k1"), 0, "k1 is an FPU register" );
is ( is_reg_opmask_att("k1"), 0, "k1 is an opmask register" );

is ( is_reg_att   ("axmm6"), 0, "axmm6 is a register" );
is ( is_reg_att   ("cax"), 0, "cax is a register" );
is ( is_reg_att   ("abx"), 0, "abx is a register" );
is ( is_reg_att   ("dal"), 0, "dal is a register" );
is ( is_reg_att   ("ald"), 0, "ald is a register" );
is ( is_reg_att   ("rsid"), 0, "rsid is a register" );
is ( is_reg_att   ("eabx"), 0, "eabx is a register" );
is ( is_reg_att   ("ceax"), 0, "ceax is a register" );
is ( is_reg_att   ("ebxc"), 0, "ebxc is a register" );
is ( is_reg_att   ("amm1"), 0, "amm1 is a register" );
is ( is_reg_att   ("mm30"), 0, "mm30 is a register" );
is ( is_reg_att   ("r15db"), 0, "r15db is a register" );
is ( is_reg_att   ("ar15d"), 0, "ar15d is a register" );
is ( is_segreg_att("ads"), 0, "ads is a segment register" );
is ( is_segreg_att("esx"), 0, "esx is a segment register" );
is ( is_reg_fpu_att("ast0"), 0, "ast0 is an FPU register" );
is ( is_reg_fpu_att("st5b"), 0, "st5b is an FPU register" );
is ( is_reg_att   ("ads"), 0, "ads is a register" );
is ( is_reg_att   ("esx"), 0, "esx is a register" );
is ( is_reg_att   ("ast0"), 0, "ast0 is a register" );
is ( is_reg_att   ("st5b"), 0, "st5b is a register" );
is ( is_reg_att   ("k02"), 0, "k02 is a register" );

# ---------------------------------------------------------------------

is ( is_reg_intel   ("\%AL"), 0, "AL is a register" );
is ( is_reg8_intel  ("\%AL"), 0, "AL is an 8-bit register" );
is ( is_reg16_intel ("\%AL"), 0, "AL is a 16-bit register" );
is ( is_reg32_intel ("\%AL"), 0, "AL is a 32-bit register" );
is ( is_reg64_intel ("\%AL"), 0, "AL is a 64-bit register" );
is ( is_reg_mm_intel("\%AL"), 0, "AL is a multimedia register" );
is ( is_segreg_intel("\%AL"), 0, "AL is a segment register" );
is ( is_reg_fpu_intel("\%AL"), 0, "AL is an FPU register" );
is ( is_reg_opmask_intel("\%AL"), 0, "AL is an opmask register" );

is ( is_reg_intel   ("\%r15b"), 0, "r15b is a register" );
is ( is_reg8_intel  ("\%r15b"), 0, "r15b is an 8-bit register" );
is ( is_reg16_intel ("\%r15b"), 0, "r15b is a 16-bit register" );
is ( is_reg32_intel ("\%r15b"), 0, "r15b is a 32-bit register" );
is ( is_reg64_intel ("\%r15b"), 0, "r15b is a 64-bit register" );
is ( is_reg_mm_intel("\%r15b"), 0, "r15b is a multimedia register" );
is ( is_segreg_intel("\%r15b"), 0, "r15b is a segment register" );
is ( is_reg_fpu_intel("\%r15b"), 0, "r15b is an FPU register" );
is ( is_reg_opmask_intel("\%r15b"), 0, "r15b is an opmask register" );

is ( is_reg_intel   ("\%AX"), 0, "AX is a register" );
is ( is_reg8_intel  ("\%AX"), 0, "AX is an 8-bit register" );
is ( is_reg16_intel ("\%AX"), 0, "AX is a 16-bit register" );
is ( is_reg32_intel ("\%AX"), 0, "AX is a 32-bit register" );
is ( is_reg64_intel ("\%AX"), 0, "AX is a 64-bit register" );
is ( is_reg_mm_intel("\%AX"), 0, "AX is a multimedia register" );
is ( is_segreg_intel("\%AX"), 0, "AX is a segment register" );
is ( is_reg_fpu_intel("\%AX"), 0, "AX is an FPU register" );
is ( is_reg_opmask_intel("\%AX"), 0, "AX is an opmask register" );

is ( is_reg_intel   ("\%r10w"), 0, "r10w is a register" );
is ( is_reg8_intel  ("\%r10w"), 0, "r10w is an 8-bit register" );
is ( is_reg16_intel ("\%r10w"), 0, "r10w is a 16-bit register" );
is ( is_reg32_intel ("\%r10w"), 0, "r10w is a 32-bit register" );
is ( is_reg64_intel ("\%r10w"), 0, "r10w is a 64-bit register" );
is ( is_reg_mm_intel("\%r10w"), 0, "r10w is a multimedia register" );
is ( is_segreg_intel("\%r10w"), 0, "r10w is a segment register" );
is ( is_reg_fpu_intel("\%r10w"), 0, "r10w is an FPU register" );
is ( is_reg_opmask_intel("\%r10w"), 0, "r10w is an opmask register" );

is ( is_reg_intel   ("\%EBX"), 0, "EBX is a register" );
is ( is_reg8_intel  ("\%EBX"), 0, "EBX is an 8-bit register" );
is ( is_reg16_intel ("\%EBX"), 0, "EBX is a 16-bit register" );
is ( is_reg32_intel ("\%EBX"), 0, "EBX is a 32-bit register" );
is ( is_reg64_intel ("\%EBX"), 0, "EBX is a 64-bit register" );
is ( is_reg_mm_intel("\%EBX"), 0, "EBX is a multimedia register" );
is ( is_segreg_intel("\%EBX"), 0, "EBX is a segment register" );
is ( is_reg_fpu_intel("\%EBX"), 0, "EBX is an FPU register" );
is ( is_reg_opmask_intel("\%EBX"), 0, "EBX is an opmask register" );

is ( is_reg_intel   ("\%r8l"), 0, "r8l is a register" );
is ( is_reg8_intel  ("\%r8l"), 0, "r8l is an 8-bit register" );
is ( is_reg16_intel ("\%r8l"), 0, "r8l is a 16-bit register" );
is ( is_reg32_intel ("\%r8l"), 0, "r8l is a 32-bit register" );
is ( is_reg64_intel ("\%r8l"), 0, "r8l is a 64-bit register" );
is ( is_reg_mm_intel("\%r8l"), 0, "r8l is a multimedia register" );
is ( is_segreg_intel("\%r8l"), 0, "r8l is a segment register" );
is ( is_reg_fpu_intel("\%r8l"), 0, "r8l is an FPU register" );
is ( is_reg_opmask_intel("\%r8l"), 0, "r8l is an opmask register" );

is ( is_reg_intel   ("\%rdi"), 0, "rdi is a register" );
is ( is_reg8_intel  ("\%rdi"), 0, "rdi is an 8-bit register" );
is ( is_reg16_intel ("\%rdi"), 0, "rdi is a 16-bit register" );
is ( is_reg32_intel ("\%rdi"), 0, "rdi is a 32-bit register" );
is ( is_reg64_intel ("\%rdi"), 0, "rdi is a 64-bit register" );
is ( is_reg_mm_intel("\%rdi"), 0, "rdi is a multimedia register" );
is ( is_segreg_intel("\%rdi"), 0, "rdi is a segment register" );
is ( is_reg_fpu_intel("\%rdi"), 0, "rdi is an FPU register" );
is ( is_reg_opmask_intel("\%rdi"), 0, "rdi is an opmask register" );

is ( is_reg_intel   ("\%xmm9"), 0, "xmm9 is a register" );
is ( is_reg8_intel  ("\%xmm9"), 0, "xmm9 is an 8-bit register" );
is ( is_reg16_intel ("\%xmm9"), 0, "xmm9 is a 16-bit register" );
is ( is_reg32_intel ("\%xmm9"), 0, "xmm9 is a 32-bit register" );
is ( is_reg64_intel ("\%xmm9"), 0, "xmm9 is a 64-bit register" );
is ( is_reg_mm_intel("\%xmm9"), 0, "xmm9 is a multimedia register" );
is ( is_segreg_intel("\%xmm9"), 0, "xmm9 is a segment register" );
is ( is_reg_fpu_intel("\%xmm9"), 0, "xmm9 is an FPU register" );
is ( is_reg_opmask_intel("\%xmm9"), 0, "xmm9 is an opmask register" );

is ( is_reg_intel   ("\%mm6"), 0, "mm6 is a register" );
is ( is_reg8_intel  ("\%mm6"), 0, "mm6 is an 8-bit register" );
is ( is_reg16_intel ("\%mm6"), 0, "mm6 is a 16-bit register" );
is ( is_reg32_intel ("\%mm6"), 0, "mm6 is a 32-bit register" );
is ( is_reg64_intel ("\%mm6"), 0, "mm6 is a 64-bit register" );
is ( is_reg_mm_intel("\%mm6"), 0, "mm6 is a multimedia register" );
is ( is_segreg_intel("\%mm6"), 0, "mm6 is a segment register" );
is ( is_reg_fpu_intel("\%mm6"), 0, "mm6 is an FPU register" );
is ( is_reg_opmask_intel("\%mm6"), 0, "mm6 is an opmask register" );

is ( is_reg_intel   ("\%st0"), 0, "st0 is a register" );
is ( is_reg8_intel  ("\%st0"), 0, "st0 is an 8-bit register" );
is ( is_reg16_intel ("\%st0"), 0, "st0 is a 16-bit register" );
is ( is_reg32_intel ("\%st0"), 0, "st0 is a 32-bit register" );
is ( is_reg64_intel ("\%st0"), 0, "st0 is a 64-bit register" );
is ( is_reg_mm_intel("\%st0"), 0, "st0 is a multimedia register" );
is ( is_segreg_intel("\%st0"), 0, "st0 is a segment register" );
is ( is_reg_fpu_intel("\%st0"), 0, "st0 is an FPU register" );
is ( is_reg_opmask_intel("\%st0"), 0, "st0 is an opmask register" );

is ( is_reg_intel   ("\%cs"), 0, "cs is a register" );
is ( is_reg8_intel  ("\%ds"), 0, "ds is an 8-bit register" );
is ( is_reg16_intel ("\%Es"), 0, "Es is a 16-bit register" );
is ( is_reg32_intel ("\%ss"), 0, "ss is a 32-bit register" );
is ( is_reg64_intel ("\%fS"), 0, "fS is a 64-bit register" );
is ( is_reg_mm_intel("\%gs"), 0, "gs is a multimedia register" );
is ( is_segreg_intel("\%cs"), 0, "cs is a segment register" );
is ( is_reg_fpu_intel("\%ds"), 0, "ds is an FPU register" );
is ( is_reg_opmask_intel("\%ds"), 0, "ds is an opmask register" );

is ( is_segreg_intel("\%cs"), 0, "cs is a segment register" );
is ( is_segreg_intel("\%ds"), 0, "ds is a segment register" );
is ( is_segreg_intel("\%Es"), 0, "Es is a segment register" );
is ( is_segreg_intel("\%ss"), 0, "ss is a segment register" );
is ( is_segreg_intel("\%fS"), 0, "fS is a segment register" );
is ( is_segreg_intel("\%gs"), 0, "gs is a segment register" );

is ( is_reg_intel   ("\%ymm0"), 0, "ymm0 is a register" );
is ( is_reg8_intel  ("\%ymm0"), 0, "ymm0 is an 8-bit register" );
is ( is_reg16_intel ("\%ymm0"), 0, "ymm0 is a 16-bit register" );
is ( is_reg32_intel ("\%ymm0"), 0, "ymm0 is a 32-bit register" );
is ( is_reg64_intel ("\%ymm0"), 0, "ymm0 is a 64-bit register" );
is ( is_reg_mm_intel("\%ymm0"), 0, "ymm0 is a multimedia register" );
is ( is_segreg_intel("\%ymm0"), 0, "ymm0 is a segment register" );
is ( is_reg_fpu_intel("\%ymm0"), 0, "ymm0 is an FPU register" );
is ( is_reg_opmask_intel("\%ymm0"), 0, "ymm0 is an opmask register" );

is ( is_reg_intel   ("\%zmm0"), 0, "zmm0 is a register" );
is ( is_reg8_intel  ("\%zmm0"), 0, "zmm0 is an 8-bit register" );
is ( is_reg16_intel ("\%zmm0"), 0, "zmm0 is a 16-bit register" );
is ( is_reg32_intel ("\%zmm0"), 0, "zmm0 is a 32-bit register" );
is ( is_reg64_intel ("\%zmm0"), 0, "zmm0 is a 64-bit register" );
is ( is_reg_mm_intel("\%zmm0"), 0, "zmm0 is a multimedia register" );
is ( is_segreg_intel("\%zmm0"), 0, "zmm0 is a segment register" );
is ( is_reg_fpu_intel("\%zmm0"), 0, "zmm0 is an FPU register" );
is ( is_reg_opmask_intel("\%zmm0"), 0, "zmm0 is an opmask register" );

is ( is_reg_intel   ("\%k1"), 0, "k1 is a register" );
is ( is_reg8_intel  ("\%k1"), 0, "k1 is an 8-bit register" );
is ( is_reg16_intel ("\%k1"), 0, "k1 is a 16-bit register" );
is ( is_reg32_intel ("\%k1"), 0, "k1 is a 32-bit register" );
is ( is_reg64_intel ("\%k1"), 0, "k1 is a 64-bit register" );
is ( is_reg_mm_intel("\%k1"), 0, "k1 is a multimedia register" );
is ( is_segreg_intel("\%k1"), 0, "k1 is a segment register" );
is ( is_reg_fpu_intel("\%k1"), 0, "k1 is an FPU register" );
is ( is_reg_opmask_intel("\%k1"), 0, "k1 is an opmask register" );

is ( is_reg_intel   ("\%axmm6"), 0, "axmm6 is a register" );
is ( is_reg_intel   ("\%cax"), 0, "cax is a register" );
is ( is_reg_intel   ("\%abx"), 0, "abx is a register" );
is ( is_reg_intel   ("\%dal"), 0, "dal is a register" );
is ( is_reg_intel   ("\%ald"), 0, "ald is a register" );
is ( is_reg_intel   ("\%rsid"), 0, "rsid is a register" );
is ( is_reg_intel   ("\%eabx"), 0, "eabx is a register" );
is ( is_reg_intel   ("\%ceax"), 0, "ceax is a register" );
is ( is_reg_intel   ("\%ebxc"), 0, "ebxc is a register" );
is ( is_reg_intel   ("\%amm1"), 0, "amm1 is a register" );
is ( is_reg_intel   ("\%mm30"), 0, "mm30 is a register" );
is ( is_reg_intel   ("\%r15db"), 0, "r15db is a register" );
is ( is_reg_intel   ("\%ar15d"), 0, "ar15d is a register" );
is ( is_segreg_intel("\%ads"), 0, "ads is a segment register" );
is ( is_segreg_intel("\%esx"), 0, "esx is a segment register" );
is ( is_reg_fpu_intel("\%ast0"), 0, "ast0 is an FPU register" );
is ( is_reg_fpu_intel("\%st5b"), 0, "st5b is an FPU register" );
is ( is_reg_intel   ("\%ads"), 0, "ads is a register" );
is ( is_reg_intel   ("\%esx"), 0, "esx is a register" );
is ( is_reg_intel   ("\%ast0"), 0, "ast0 is a register" );
is ( is_reg_intel   ("\%st5b"), 0, "st5b is a register" );
is ( is_reg_intel   ("\%k02"), 0, "k02 is a register" );

# ---------------------------------------------------------------

is ( is_reg   ("\%AL"), 1, "AL is a register" );
is ( is_reg8  ("\%AL"), 1, "AL is an 8-bit register" );
is ( is_reg16 ("\%AL"), 0, "AL is a 16-bit register" );
is ( is_reg32 ("\%AL"), 0, "AL is a 32-bit register" );
is ( is_reg64 ("\%AL"), 0, "AL is a 64-bit register" );
is ( is_reg_mm("\%AL"), 0, "AL is a multimedia register" );
is ( is_segreg("\%AL"), 0, "AL is a segment register" );
is ( is_reg_fpu("\%AL"), 0, "AL is an FPU register" );
is ( is_reg_opmask("\%AL"), 0, "AL is an opmask register" );

is ( is_reg   ("\%r15b"), 1, "r15b is a register" );
is ( is_reg8  ("\%r15b"), 1, "r15b is an 8-bit register" );
is ( is_reg16 ("\%r15b"), 0, "r15b is a 16-bit register" );
is ( is_reg32 ("\%r15b"), 0, "r15b is a 32-bit register" );
is ( is_reg64 ("\%r15b"), 0, "r15b is a 64-bit register" );
is ( is_reg_mm("\%r15b"), 0, "r15b is a multimedia register" );
is ( is_segreg("\%r15b"), 0, "r15b is a segment register" );
is ( is_reg_fpu("\%r15b"), 0, "r15b is an FPU register" );
is ( is_reg_opmask("\%r15b"), 0, "r15b is an opmask register" );

is ( is_reg   ("\%AX"), 1, "AX is a register" );
is ( is_reg8  ("\%AX"), 0, "AX is an 8-bit register" );
is ( is_reg16 ("\%AX"), 1, "AX is a 16-bit register" );
is ( is_reg32 ("\%AX"), 0, "AX is a 32-bit register" );
is ( is_reg64 ("\%AX"), 0, "AX is a 64-bit register" );
is ( is_reg_mm("\%AX"), 0, "AX is a multimedia register" );
is ( is_segreg("\%AX"), 0, "AX is a segment register" );
is ( is_reg_fpu("\%AX"), 0, "AX is an FPU register" );
is ( is_reg_opmask("\%AX"), 0, "AX is an opmask register" );

is ( is_reg   ("\%r10w"), 1, "r10w is a register" );
is ( is_reg8  ("\%r10w"), 0, "r10w is an 8-bit register" );
is ( is_reg16 ("\%r10w"), 1, "r10w is a 16-bit register" );
is ( is_reg32 ("\%r10w"), 0, "r10w is a 32-bit register" );
is ( is_reg64 ("\%r10w"), 0, "r10w is a 64-bit register" );
is ( is_reg_mm("\%r10w"), 0, "r10w is a multimedia register" );
is ( is_segreg("\%r10w"), 0, "r10w is a segment register" );
is ( is_reg_fpu("\%r10w"), 0, "r10w is an FPU register" );
is ( is_reg_opmask("\%r10w"), 0, "r10w is an opmask register" );

is ( is_reg   ("\%EBX"), 1, "EBX is a register" );
is ( is_reg8  ("\%EBX"), 0, "EBX is an 8-bit register" );
is ( is_reg16 ("\%EBX"), 0, "EBX is a 16-bit register" );
is ( is_reg32 ("\%EBX"), 1, "EBX is a 32-bit register" );
is ( is_reg64 ("\%EBX"), 0, "EBX is a 64-bit register" );
is ( is_reg_mm("\%EBX"), 0, "EBX is a multimedia register" );
is ( is_segreg("\%EBX"), 0, "EBX is a segment register" );
is ( is_reg_fpu("\%EBX"), 0, "EBX is an FPU register" );
is ( is_reg_opmask("\%EBX"), 0, "EBX is an opmask register" );

is ( is_reg   ("\%r8l"), 1, "r8l is a register" );
is ( is_reg8  ("\%r8l"), 0, "r8l is an 8-bit register" );
is ( is_reg16 ("\%r8l"), 0, "r8l is a 16-bit register" );
is ( is_reg32 ("\%r8l"), 1, "r8l is a 32-bit register" );
is ( is_reg64 ("\%r8l"), 0, "r8l is a 64-bit register" );
is ( is_reg_mm("\%r8l"), 0, "r8l is a multimedia register" );
is ( is_segreg("\%r8l"), 0, "r8l is a segment register" );
is ( is_reg_fpu("\%r8l"), 0, "r8l is an FPU register" );
is ( is_reg_opmask("\%r8l"), 0, "r8l is an opmask register" );

is ( is_reg   ("\%rdi"), 1, "rdi is a register" );
is ( is_reg8  ("\%rdi"), 0, "rdi is an 8-bit register" );
is ( is_reg16 ("\%rdi"), 0, "rdi is a 16-bit register" );
is ( is_reg32 ("\%rdi"), 0, "rdi is a 32-bit register" );
is ( is_reg64 ("\%rdi"), 1, "rdi is a 64-bit register" );
is ( is_reg_mm("\%rdi"), 0, "rdi is a multimedia register" );
is ( is_segreg("\%rdi"), 0, "rdi is a segment register" );
is ( is_reg_fpu("\%rdi"), 0, "rdi is an FPU register" );
is ( is_reg_opmask("\%rdi"), 0, "rdi is an opmask register" );

is ( is_reg   ("\%xmm9"), 1, "xmm9 is a register" );
is ( is_reg8  ("\%xmm9"), 0, "xmm9 is an 8-bit register" );
is ( is_reg16 ("\%xmm9"), 0, "xmm9 is a 16-bit register" );
is ( is_reg32 ("\%xmm9"), 0, "xmm9 is a 32-bit register" );
is ( is_reg64 ("\%xmm9"), 0, "xmm9 is a 64-bit register" );
is ( is_reg_mm("\%xmm9"), 1, "xmm9 is a multimedia register" );
is ( is_segreg("\%xmm9"), 0, "xmm9 is a segment register" );
is ( is_reg_fpu("\%xmm9"), 0, "xmm9 is an FPU register" );
is ( is_reg_opmask("\%xmm9"), 0, "xmm9 is an opmask register" );

is ( is_reg   ("\%mm6"), 1, "mm6 is a register" );
is ( is_reg8  ("\%mm6"), 0, "mm6 is an 8-bit register" );
is ( is_reg16 ("\%mm6"), 0, "mm6 is a 16-bit register" );
is ( is_reg32 ("\%mm6"), 0, "mm6 is a 32-bit register" );
is ( is_reg64 ("\%mm6"), 0, "mm6 is a 64-bit register" );
is ( is_reg_mm("\%mm6"), 1, "mm6 is a multimedia register" );
is ( is_segreg("\%mm6"), 0, "mm6 is a segment register" );
is ( is_reg_fpu("\%mm6"), 0, "mm6 is an FPU register" );
is ( is_reg_opmask("\%mm6"), 0, "mm6 is an opmask register" );

is ( is_reg   ("\%st0"), 1, "st0 is a register" );
is ( is_reg8  ("\%st0"), 0, "st0 is an 8-bit register" );
is ( is_reg16 ("\%st0"), 0, "st0 is a 16-bit register" );
is ( is_reg32 ("\%st0"), 0, "st0 is a 32-bit register" );
is ( is_reg64 ("\%st0"), 0, "st0 is a 64-bit register" );
is ( is_reg_mm("\%st0"), 0, "st0 is a multimedia register" );
is ( is_segreg("\%st0"), 0, "st0 is a segment register" );
is ( is_reg_fpu("\%st0"), 1, "st0 is an FPU register" );
is ( is_reg_opmask("\%st0"), 0, "st0 is an opmask register" );

is ( is_reg   ("\%cs"), 1, "cs is a register" );
is ( is_reg8  ("\%ds"), 0, "ds is an 8-bit register" );
is ( is_reg16 ("\%Es"), 1, "Es is a 16-bit register" );
is ( is_reg32 ("\%ss"), 0, "ss is a 32-bit register" );
is ( is_reg64 ("\%fS"), 0, "fS is a 64-bit register" );
is ( is_reg_mm("\%gs"), 0, "gs is a multimedia register" );
is ( is_segreg("\%cs"), 1, "cs is a segment register" );
is ( is_reg_fpu("\%ds"), 0, "ds is an FPU register" );
is ( is_reg_opmask("\%ds"), 0, "ds is an opmask register" );

is ( is_segreg("\%cs"), 1, "cs is a segment register" );
is ( is_segreg("\%ds"), 1, "ds is a segment register" );
is ( is_segreg("\%Es"), 1, "Es is a segment register" );
is ( is_segreg("\%ss"), 1, "ss is a segment register" );
is ( is_segreg("\%fS"), 1, "fS is a segment register" );
is ( is_segreg("\%gs"), 1, "gs is a segment register" );

is ( is_reg   ("\%ymm0"), 1, "ymm0 is a register" );
is ( is_reg8  ("\%ymm0"), 0, "ymm0 is an 8-bit register" );
is ( is_reg16 ("\%ymm0"), 0, "ymm0 is a 16-bit register" );
is ( is_reg32 ("\%ymm0"), 0, "ymm0 is a 32-bit register" );
is ( is_reg64 ("\%ymm0"), 0, "ymm0 is a 64-bit register" );
is ( is_reg_mm("\%ymm0"), 1, "ymm0 is a multimedia register" );
is ( is_segreg("\%ymm0"), 0, "ymm0 is a segment register" );
is ( is_reg_fpu("\%ymm0"), 0, "ymm0 is an FPU register" );
is ( is_reg_opmask("\%ymm0"), 0, "ymm0 is an opmask register" );

is ( is_reg   ("\%zmm0"), 1, "zmm0 is a register" );
is ( is_reg8  ("\%zmm0"), 0, "zmm0 is an 8-bit register" );
is ( is_reg16 ("\%zmm0"), 0, "zmm0 is a 16-bit register" );
is ( is_reg32 ("\%zmm0"), 0, "zmm0 is a 32-bit register" );
is ( is_reg64 ("\%zmm0"), 0, "zmm0 is a 64-bit register" );
is ( is_reg_mm("\%zmm0"), 1, "zmm0 is a multimedia register" );
is ( is_segreg("\%zmm0"), 0, "zmm0 is a segment register" );
is ( is_reg_fpu("\%zmm0"), 0, "zmm0 is an FPU register" );
is ( is_reg_opmask("\%zmm0"), 0, "zmm0 is an opmask register" );

is ( is_reg   ("\%k1"), 1, "k1 is a register" );
is ( is_reg8  ("\%k1"), 0, "k1 is an 8-bit register" );
is ( is_reg16 ("\%k1"), 0, "k1 is a 16-bit register" );
is ( is_reg32 ("\%k1"), 0, "k1 is a 32-bit register" );
is ( is_reg64 ("\%k1"), 0, "k1 is a 64-bit register" );
is ( is_reg_mm("\%k1"), 0, "k1 is a multimedia register" );
is ( is_segreg("\%k1"), 0, "k1 is a segment register" );
is ( is_reg_fpu("\%k1"), 0, "k1 is an FPU register" );
is ( is_reg_opmask("\%k1"), 1, "k1 is an opmask register" );

is ( is_reg   ("\%axmm6"), 0, "axmm6 is a register" );
is ( is_reg   ("\%cax"), 0, "cax is a register" );
is ( is_reg   ("\%abx"), 0, "abx is a register" );
is ( is_reg   ("\%dal"), 0, "dal is a register" );
is ( is_reg   ("\%ald"), 0, "ald is a register" );
is ( is_reg   ("\%rsid"), 0, "rsid is a register" );
is ( is_reg   ("\%eabx"), 0, "eabx is a register" );
is ( is_reg   ("\%ceax"), 0, "ceax is a register" );
is ( is_reg   ("\%ebxc"), 0, "ebxc is a register" );
is ( is_reg   ("\%amm1"), 0, "amm1 is a register" );
is ( is_reg   ("\%mm30"), 0, "mm30 is a register" );
is ( is_reg   ("\%r15db"), 0, "r15db is a register" );
is ( is_reg   ("\%ar15d"), 0, "ar15d is a register" );
is ( is_segreg("\%ads"), 0, "ads is a segment register" );
is ( is_segreg("\%esx"), 0, "esx is a segment register" );
is ( is_reg_fpu("\%ast0"), 0, "ast0 is an FPU register" );
is ( is_reg_fpu("\%st5b"), 0, "st5b is an FPU register" );
is ( is_reg   ("\%ads"), 0, "ads is a register" );
is ( is_reg   ("\%esx"), 0, "esx is a register" );
is ( is_reg   ("\%ast0"), 0, "ast0 is a register" );
is ( is_reg   ("\%st5b"), 0, "st5b is a register" );
is ( is_reg   ("\%k02"), 0, "k02 is a register" );

# ---------------------------------------------------------------

is ( is_reg   ("AL"), 1, "AL is a register" );
is ( is_reg8  ("AL"), 1, "AL is an 8-bit register" );
is ( is_reg16 ("AL"), 0, "AL is a 16-bit register" );
is ( is_reg32 ("AL"), 0, "AL is a 32-bit register" );
is ( is_reg64 ("AL"), 0, "AL is a 64-bit register" );
is ( is_reg_mm("AL"), 0, "AL is a multimedia register" );
is ( is_segreg("AL"), 0, "AL is a segment register" );
is ( is_reg_fpu("AL"), 0, "AL is an FPU register" );
is ( is_reg_opmask("AL"), 0, "AL is an opmask register" );

is ( is_reg   ("r15b"), 1, "r15b is a register" );
is ( is_reg8  ("r15b"), 1, "r15b is an 8-bit register" );
is ( is_reg16 ("r15b"), 0, "r15b is a 16-bit register" );
is ( is_reg32 ("r15b"), 0, "r15b is a 32-bit register" );
is ( is_reg64 ("r15b"), 0, "r15b is a 64-bit register" );
is ( is_reg_mm("r15b"), 0, "r15b is a multimedia register" );
is ( is_segreg("r15b"), 0, "r15b is a segment register" );
is ( is_reg_fpu("r15b"), 0, "r15b is an FPU register" );
is ( is_reg_opmask("r15b"), 0, "r15b is an opmask register" );

is ( is_reg   ("AX"), 1, "AX is a register" );
is ( is_reg8  ("AX"), 0, "AX is an 8-bit register" );
is ( is_reg16 ("AX"), 1, "AX is a 16-bit register" );
is ( is_reg32 ("AX"), 0, "AX is a 32-bit register" );
is ( is_reg64 ("AX"), 0, "AX is a 64-bit register" );
is ( is_reg_mm("AX"), 0, "AX is a multimedia register" );
is ( is_segreg("AX"), 0, "AX is a segment register" );
is ( is_reg_fpu("AX"), 0, "AX is an FPU register" );
is ( is_reg_opmask("AX"), 0, "AX is an opmask register" );

is ( is_reg   ("r10w"), 1, "r10w is a register" );
is ( is_reg8  ("r10w"), 0, "r10w is an 8-bit register" );
is ( is_reg16 ("r10w"), 1, "r10w is a 16-bit register" );
is ( is_reg32 ("r10w"), 0, "r10w is a 32-bit register" );
is ( is_reg64 ("r10w"), 0, "r10w is a 64-bit register" );
is ( is_reg_mm("r10w"), 0, "r10w is a multimedia register" );
is ( is_segreg("r10w"), 0, "r10w is a segment register" );
is ( is_reg_fpu("r10w"), 0, "r10w is an FPU register" );
is ( is_reg_opmask("r10w"), 0, "r10w is an opmask register" );

is ( is_reg   ("EBX"), 1, "EBX is a register" );
is ( is_reg8  ("EBX"), 0, "EBX is an 8-bit register" );
is ( is_reg16 ("EBX"), 0, "EBX is a 16-bit register" );
is ( is_reg32 ("EBX"), 1, "EBX is a 32-bit register" );
is ( is_reg64 ("EBX"), 0, "EBX is a 64-bit register" );
is ( is_reg_mm("EBX"), 0, "EBX is a multimedia register" );
is ( is_segreg("EBX"), 0, "EBX is a segment register" );
is ( is_reg_fpu("EBX"), 0, "EBX is an FPU register" );
is ( is_reg_opmask("EBX"), 0, "EBX is an opmask register" );

is ( is_reg   ("r8l"), 1, "r8l is a register" );
is ( is_reg8  ("r8l"), 0, "r8l is an 8-bit register" );
is ( is_reg16 ("r8l"), 0, "r8l is a 16-bit register" );
is ( is_reg32 ("r8l"), 1, "r8l is a 32-bit register" );
is ( is_reg64 ("r8l"), 0, "r8l is a 64-bit register" );
is ( is_reg_mm("r8l"), 0, "r8l is a multimedia register" );
is ( is_segreg("r8l"), 0, "r8l is a segment register" );
is ( is_reg_fpu("r8l"), 0, "r8l is an FPU register" );
is ( is_reg_opmask("r8l"), 0, "r8l is an opmask register" );

is ( is_reg   ("rdi"), 1, "rdi is a register" );
is ( is_reg8  ("rdi"), 0, "rdi is an 8-bit register" );
is ( is_reg16 ("rdi"), 0, "rdi is a 16-bit register" );
is ( is_reg32 ("rdi"), 0, "rdi is a 32-bit register" );
is ( is_reg64 ("rdi"), 1, "rdi is a 64-bit register" );
is ( is_reg_mm("rdi"), 0, "rdi is a multimedia register" );
is ( is_segreg("rdi"), 0, "rdi is a segment register" );
is ( is_reg_fpu("rdi"), 0, "rdi is an FPU register" );
is ( is_reg_opmask("rdi"), 0, "rdi is an opmask register" );

is ( is_reg   ("xmm9"), 1, "xmm9 is a register" );
is ( is_reg8  ("xmm9"), 0, "xmm9 is an 8-bit register" );
is ( is_reg16 ("xmm9"), 0, "xmm9 is a 16-bit register" );
is ( is_reg32 ("xmm9"), 0, "xmm9 is a 32-bit register" );
is ( is_reg64 ("xmm9"), 0, "xmm9 is a 64-bit register" );
is ( is_reg_mm("xmm9"), 1, "xmm9 is a multimedia register" );
is ( is_segreg("xmm9"), 0, "xmm9 is a segment register" );
is ( is_reg_fpu("xmm9"), 0, "xmm9 is an FPU register" );
is ( is_reg_opmask("xmm9"), 0, "xmm9 is an opmask register" );

is ( is_reg   ("mm6"), 1, "mm6 is a register" );
is ( is_reg8  ("mm6"), 0, "mm6 is an 8-bit register" );
is ( is_reg16 ("mm6"), 0, "mm6 is a 16-bit register" );
is ( is_reg32 ("mm6"), 0, "mm6 is a 32-bit register" );
is ( is_reg64 ("mm6"), 0, "mm6 is a 64-bit register" );
is ( is_reg_mm("mm6"), 1, "mm6 is a multimedia register" );
is ( is_segreg("mm6"), 0, "mm6 is a segment register" );
is ( is_reg_fpu("mm6"), 0, "mm6 is an FPU register" );
is ( is_reg_opmask("mm6"), 0, "mm6 is an opmask register" );

is ( is_reg   ("st0"), 1, "st0 is a register" );
is ( is_reg8  ("st0"), 0, "st0 is an 8-bit register" );
is ( is_reg16 ("st0"), 0, "st0 is a 16-bit register" );
is ( is_reg32 ("st0"), 0, "st0 is a 32-bit register" );
is ( is_reg64 ("st0"), 0, "st0 is a 64-bit register" );
is ( is_reg_mm("st0"), 0, "st0 is a multimedia register" );
is ( is_segreg("st0"), 0, "st0 is a segment register" );
is ( is_reg_fpu("st0"), 1, "st0 is an FPU register" );
is ( is_reg_opmask("st0"), 0, "st0 is an opmask register" );

is ( is_reg   ("cs"), 1, "cs is a register" );
is ( is_reg8  ("ds"), 0, "ds is an 8-bit register" );
is ( is_reg16 ("Es"), 1, "Es is a 16-bit register" );
is ( is_reg32 ("ss"), 0, "ss is a 32-bit register" );
is ( is_reg64 ("fS"), 0, "fS is a 64-bit register" );
is ( is_reg_mm("gs"), 0, "gs is a multimedia register" );
is ( is_segreg("cs"), 1, "cs is a segment register" );
is ( is_reg_fpu("ds"), 0, "ds is an FPU register" );
is ( is_reg_opmask("ds"), 0, "ds is an opmask register" );

is ( is_segreg("cs"), 1, "cs is a segment register" );
is ( is_segreg("ds"), 1, "ds is a segment register" );
is ( is_segreg("Es"), 1, "Es is a segment register" );
is ( is_segreg("ss"), 1, "ss is a segment register" );
is ( is_segreg("fS"), 1, "fS is a segment register" );
is ( is_segreg("gs"), 1, "gs is a segment register" );

is ( is_reg   ("ymm0"), 1, "ymm0 is a register" );
is ( is_reg8  ("ymm0"), 0, "ymm0 is an 8-bit register" );
is ( is_reg16 ("ymm0"), 0, "ymm0 is a 16-bit register" );
is ( is_reg32 ("ymm0"), 0, "ymm0 is a 32-bit register" );
is ( is_reg64 ("ymm0"), 0, "ymm0 is a 64-bit register" );
is ( is_reg_mm("ymm0"), 1, "ymm0 is a multimedia register" );
is ( is_segreg("ymm0"), 0, "ymm0 is a segment register" );
is ( is_reg_fpu("ymm0"), 0, "ymm0 is an FPU register" );
is ( is_reg_opmask("ymm0"), 0, "ymm0 is an opmask register" );

is ( is_reg   ("zmm0"), 1, "zmm0 is a register" );
is ( is_reg8  ("zmm0"), 0, "zmm0 is an 8-bit register" );
is ( is_reg16 ("zmm0"), 0, "zmm0 is a 16-bit register" );
is ( is_reg32 ("zmm0"), 0, "zmm0 is a 32-bit register" );
is ( is_reg64 ("zmm0"), 0, "zmm0 is a 64-bit register" );
is ( is_reg_mm("zmm0"), 1, "zmm0 is a multimedia register" );
is ( is_segreg("zmm0"), 0, "zmm0 is a segment register" );
is ( is_reg_fpu("zmm0"), 0, "zmm0 is an FPU register" );
is ( is_reg_opmask("zmm0"), 0, "zmm0 is an opmask register" );

is ( is_reg   ("k1"), 1, "k1 is a register" );
is ( is_reg8  ("k1"), 0, "k1 is an 8-bit register" );
is ( is_reg16 ("k1"), 0, "k1 is a 16-bit register" );
is ( is_reg32 ("k1"), 0, "k1 is a 32-bit register" );
is ( is_reg64 ("k1"), 0, "k1 is a 64-bit register" );
is ( is_reg_mm("k1"), 0, "k1 is a multimedia register" );
is ( is_segreg("k1"), 0, "k1 is a segment register" );
is ( is_reg_fpu("k1"), 0, "k1 is an FPU register" );
is ( is_reg_opmask("k1"), 1, "k1 is an opmask register" );

is ( is_reg   ("axmm6"), 0, "axmm6 is a register" );
is ( is_reg   ("cax"), 0, "cax is a register" );
is ( is_reg   ("abx"), 0, "abx is a register" );
is ( is_reg   ("dal"), 0, "dal is a register" );
is ( is_reg   ("ald"), 0, "ald is a register" );
is ( is_reg   ("rsid"), 0, "rsid is a register" );
is ( is_reg   ("eabx"), 0, "eabx is a register" );
is ( is_reg   ("ceax"), 0, "ceax is a register" );
is ( is_reg   ("ebxc"), 0, "ebxc is a register" );
is ( is_reg   ("amm1"), 0, "amm1 is a register" );
is ( is_reg   ("mm30"), 0, "mm30 is a register" );
is ( is_reg   ("r15db"), 0, "r15db is a register" );
is ( is_reg   ("ar15d"), 0, "ar15d is a register" );
is ( is_segreg("ads"), 0, "ads is a segment register" );
is ( is_segreg("esx"), 0, "esx is a segment register" );
is ( is_reg_fpu("ast0"), 0, "ast0 is an FPU register" );
is ( is_reg_fpu("st5b"), 0, "st5b is an FPU register" );
is ( is_reg   ("ads"), 0, "ads is a register" );
is ( is_reg   ("esx"), 0, "esx is a register" );
is ( is_reg   ("ast0"), 0, "ast0 is a register" );
is ( is_reg   ("st5b"), 0, "st5b is a register" );
is ( is_reg   ("k02"), 0, "k02 is a register" );

