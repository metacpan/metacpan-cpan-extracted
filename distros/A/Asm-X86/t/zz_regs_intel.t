#!perl -T -w

use strict;
use warnings;

use Test::More tests => 9 + 14*9 + 6 + 22;
use Asm::X86 qw(
	@regs8_intel @regs16_intel @segregs_intel @regs32_intel @regs64_intel
	@regs_mm_intel @regs_intel @regs_fpu_intel @regs_opmask_intel
	is_reg_intel is_reg8_intel is_reg16_intel is_reg32_intel is_reg64_intel
	is_reg_mm_intel is_segreg_intel is_reg_fpu_intel is_reg_opmask_intel
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

is ( is_reg_intel   ("AL"), 1, "AL is a register" );
is ( is_reg8_intel  ("AL"), 1, "AL is an 8-bit register" );
is ( is_reg16_intel ("AL"), 0, "AL is a 16-bit register" );
is ( is_reg32_intel ("AL"), 0, "AL is a 32-bit register" );
is ( is_reg64_intel ("AL"), 0, "AL is a 64-bit register" );
is ( is_reg_mm_intel("AL"), 0, "AL is a multimedia register" );
is ( is_segreg_intel("AL"), 0, "AL is a segment register" );
is ( is_reg_fpu_intel("AL"), 0, "AL is an FPU register" );
is ( is_reg_opmask_intel("AL"), 0, "AL is an opmask register" );

is ( is_reg_intel   ("r15b"), 1, "r15b is a register" );
is ( is_reg8_intel  ("r15b"), 1, "r15b is an 8-bit register" );
is ( is_reg16_intel ("r15b"), 0, "r15b is a 16-bit register" );
is ( is_reg32_intel ("r15b"), 0, "r15b is a 32-bit register" );
is ( is_reg64_intel ("r15b"), 0, "r15b is a 64-bit register" );
is ( is_reg_mm_intel("r15b"), 0, "r15b is a multimedia register" );
is ( is_segreg_intel("r15b"), 0, "r15b is a segment register" );
is ( is_reg_fpu_intel("r15b"), 0, "r15b is an FPU register" );
is ( is_reg_opmask_intel("r15b"), 0, "r15b is an opmask register" );

is ( is_reg_intel   ("AX"), 1, "AX is a register" );
is ( is_reg8_intel  ("AX"), 0, "AX is an 8-bit register" );
is ( is_reg16_intel ("AX"), 1, "AX is a 16-bit register" );
is ( is_reg32_intel ("AX"), 0, "AX is a 32-bit register" );
is ( is_reg64_intel ("AX"), 0, "AX is a 64-bit register" );
is ( is_reg_mm_intel("AX"), 0, "AX is a multimedia register" );
is ( is_segreg_intel("AX"), 0, "AX is a segment register" );
is ( is_reg_fpu_intel("AX"), 0, "AX is an FPU register" );
is ( is_reg_opmask_intel("AX"), 0, "AX is an opmask register" );

is ( is_reg_intel   ("r10w"), 1, "r10w is a register" );
is ( is_reg8_intel  ("r10w"), 0, "r10w is an 8-bit register" );
is ( is_reg16_intel ("r10w"), 1, "r10w is a 16-bit register" );
is ( is_reg32_intel ("r10w"), 0, "r10w is a 32-bit register" );
is ( is_reg64_intel ("r10w"), 0, "r10w is a 64-bit register" );
is ( is_reg_mm_intel("r10w"), 0, "r10w is a multimedia register" );
is ( is_segreg_intel("r10w"), 0, "r10w is a segment register" );
is ( is_reg_fpu_intel("r10w"), 0, "r10w is an FPU register" );
is ( is_reg_opmask_intel("r10w"), 0, "r10w is an opmask register" );

is ( is_reg_intel   ("EBX"), 1, "EBX is a register" );
is ( is_reg8_intel  ("EBX"), 0, "EBX is an 8-bit register" );
is ( is_reg16_intel ("EBX"), 0, "EBX is a 16-bit register" );
is ( is_reg32_intel ("EBX"), 1, "EBX is a 32-bit register" );
is ( is_reg64_intel ("EBX"), 0, "EBX is a 64-bit register" );
is ( is_reg_mm_intel("EBX"), 0, "EBX is a multimedia register" );
is ( is_segreg_intel("EBX"), 0, "EBX is a segment register" );
is ( is_reg_fpu_intel("EBX"), 0, "EBX is an FPU register" );
is ( is_reg_opmask_intel("EBX"), 0, "EBX is an opmask register" );

is ( is_reg_intel   ("r8l"), 1, "r8l is a register" );
is ( is_reg8_intel  ("r8l"), 0, "r8l is an 8-bit register" );
is ( is_reg16_intel ("r8l"), 0, "r8l is a 16-bit register" );
is ( is_reg32_intel ("r8l"), 1, "r8l is a 32-bit register" );
is ( is_reg64_intel ("r8l"), 0, "r8l is a 64-bit register" );
is ( is_reg_mm_intel("r8l"), 0, "r8l is a multimedia register" );
is ( is_segreg_intel("r8l"), 0, "r8l is a segment register" );
is ( is_reg_fpu_intel("r8l"), 0, "r8l is an FPU register" );
is ( is_reg_opmask_intel("r8l"), 0, "r8l is an opmask register" );

is ( is_reg_intel   ("rdi"), 1, "rdi is a register" );
is ( is_reg8_intel  ("rdi"), 0, "rdi is an 8-bit register" );
is ( is_reg16_intel ("rdi"), 0, "rdi is a 16-bit register" );
is ( is_reg32_intel ("rdi"), 0, "rdi is a 32-bit register" );
is ( is_reg64_intel ("rdi"), 1, "rdi is a 64-bit register" );
is ( is_reg_mm_intel("rdi"), 0, "rdi is a multimedia register" );
is ( is_segreg_intel("rdi"), 0, "rdi is a segment register" );
is ( is_reg_fpu_intel("rdi"), 0, "rdi is an FPU register" );
is ( is_reg_opmask_intel("rdi"), 0, "rdi is an opmask register" );

is ( is_reg_intel   ("xmm9"), 1, "xmm9 is a register" );
is ( is_reg8_intel  ("xmm9"), 0, "xmm9 is an 8-bit register" );
is ( is_reg16_intel ("xmm9"), 0, "xmm9 is a 16-bit register" );
is ( is_reg32_intel ("xmm9"), 0, "xmm9 is a 32-bit register" );
is ( is_reg64_intel ("xmm9"), 0, "xmm9 is a 64-bit register" );
is ( is_reg_mm_intel("xmm9"), 1, "xmm9 is a multimedia register" );
is ( is_segreg_intel("xmm9"), 0, "xmm9 is a segment register" );
is ( is_reg_fpu_intel("xmm9"), 0, "xmm9 is an FPU register" );
is ( is_reg_opmask_intel("xmm9"), 0, "xmm9 is an opmask register" );

is ( is_reg_intel   ("mm6"), 1, "mm6 is a register" );
is ( is_reg8_intel  ("mm6"), 0, "mm6 is an 8-bit register" );
is ( is_reg16_intel ("mm6"), 0, "mm6 is a 16-bit register" );
is ( is_reg32_intel ("mm6"), 0, "mm6 is a 32-bit register" );
is ( is_reg64_intel ("mm6"), 0, "mm6 is a 64-bit register" );
is ( is_reg_mm_intel("mm6"), 1, "mm6 is a multimedia register" );
is ( is_segreg_intel("mm6"), 0, "mm6 is a segment register" );
is ( is_reg_fpu_intel("mm6"), 0, "mm6 is an FPU register" );
is ( is_reg_opmask_intel("mm6"), 0, "mm6 is an opmask register" );

is ( is_reg_intel   ("st0"), 1, "st0 is a register" );
is ( is_reg8_intel  ("st0"), 0, "st0 is an 8-bit register" );
is ( is_reg16_intel ("st0"), 0, "st0 is a 16-bit register" );
is ( is_reg32_intel ("st0"), 0, "st0 is a 32-bit register" );
is ( is_reg64_intel ("st0"), 0, "st0 is a 64-bit register" );
is ( is_reg_mm_intel("st0"), 0, "st0 is a multimedia register" );
is ( is_segreg_intel("st0"), 0, "st0 is a segment register" );
is ( is_reg_fpu_intel("st0"), 1, "st0 is an FPU register" );
is ( is_reg_opmask_intel("st0"), 0, "st0 is an opmask register" );

is ( is_reg_intel   ("cs"), 1, "cs is a register" );
is ( is_reg8_intel  ("ds"), 0, "ds is an 8-bit register" );
is ( is_reg16_intel ("Es"), 1, "Es is a 16-bit register" );
is ( is_reg32_intel ("ss"), 0, "ss is a 32-bit register" );
is ( is_reg64_intel ("fS"), 0, "fS is a 64-bit register" );
is ( is_reg_mm_intel("gs"), 0, "gs is a multimedia register" );
is ( is_segreg_intel("cs"), 1, "cs is a segment register" );
is ( is_reg_fpu_intel("ds"), 0, "ds is an FPU register" );
is ( is_reg_opmask_intel("ds"), 0, "ds is an opmask register" );

is ( is_segreg_intel("cs"), 1, "cs is a segment register" );
is ( is_segreg_intel("ds"), 1, "ds is a segment register" );
is ( is_segreg_intel("Es"), 1, "Es is a segment register" );
is ( is_segreg_intel("ss"), 1, "ss is a segment register" );
is ( is_segreg_intel("fS"), 1, "fS is a segment register" );
is ( is_segreg_intel("gs"), 1, "gs is a segment register" );

is ( is_reg_intel   ("ymm0"), 1, "ymm0 is a register" );
is ( is_reg8_intel  ("ymm0"), 0, "ymm0 is an 8-bit register" );
is ( is_reg16_intel ("ymm0"), 0, "ymm0 is a 16-bit register" );
is ( is_reg32_intel ("ymm0"), 0, "ymm0 is a 32-bit register" );
is ( is_reg64_intel ("ymm0"), 0, "ymm0 is a 64-bit register" );
is ( is_reg_mm_intel("ymm0"), 1, "ymm0 is a multimedia register" );
is ( is_segreg_intel("ymm0"), 0, "ymm0 is a segment register" );
is ( is_reg_fpu_intel("ymm0"), 0, "ymm0 is an FPU register" );
is ( is_reg_opmask_intel("ymm0"), 0, "ymm0 is an opmask register" );

is ( is_reg_intel   ("zmm0"), 1, "zmm0 is a register" );
is ( is_reg8_intel  ("zmm0"), 0, "zmm0 is an 8-bit register" );
is ( is_reg16_intel ("zmm0"), 0, "zmm0 is a 16-bit register" );
is ( is_reg32_intel ("zmm0"), 0, "zmm0 is a 32-bit register" );
is ( is_reg64_intel ("zmm0"), 0, "zmm0 is a 64-bit register" );
is ( is_reg_mm_intel("zmm0"), 1, "zmm0 is a multimedia register" );
is ( is_segreg_intel("zmm0"), 0, "zmm0 is a segment register" );
is ( is_reg_fpu_intel("zmm0"), 0, "zmm0 is an FPU register" );
is ( is_reg_opmask_intel("zmm0"), 0, "zmm0 is an opmask register" );

is ( is_reg_intel   ("k1"), 1, "k1 is a register" );
is ( is_reg8_intel  ("k1"), 0, "k1 is an 8-bit register" );
is ( is_reg16_intel ("k1"), 0, "k1 is a 16-bit register" );
is ( is_reg32_intel ("k1"), 0, "k1 is a 32-bit register" );
is ( is_reg64_intel ("k1"), 0, "k1 is a 64-bit register" );
is ( is_reg_mm_intel("k1"), 0, "k1 is a multimedia register" );
is ( is_segreg_intel("k1"), 0, "k1 is a segment register" );
is ( is_reg_fpu_intel("k1"), 0, "k1 is an FPU register" );
is ( is_reg_opmask_intel("k1"), 1, "k1 is an opmask register" );

is ( is_reg_intel   ("axmm6"), 0, "axmm6 is a register" );
is ( is_reg_intel   ("cax"), 0, "cax is a register" );
is ( is_reg_intel   ("abx"), 0, "abx is a register" );
is ( is_reg_intel   ("dal"), 0, "dal is a register" );
is ( is_reg_intel   ("ald"), 0, "ald is a register" );
is ( is_reg_intel   ("rsid"), 0, "rsid is a register" );
is ( is_reg_intel   ("eabx"), 0, "eabx is a register" );
is ( is_reg_intel   ("ceax"), 0, "ceax is a register" );
is ( is_reg_intel   ("ebxc"), 0, "ebxc is a register" );
is ( is_reg_intel   ("amm1"), 0, "amm1 is a register" );
is ( is_reg_intel   ("mm30"), 0, "mm30 is a register" );
is ( is_reg_intel   ("r15db"), 0, "r15db is a register" );
is ( is_reg_intel   ("ar15d"), 0, "ar15d is a register" );
is ( is_segreg_intel("ads"), 0, "ads is a segment register" );
is ( is_segreg_intel("esx"), 0, "esx is a segment register" );
is ( is_reg_fpu_intel("ast0"), 0, "ast0 is an FPU register" );
is ( is_reg_fpu_intel("st5b"), 0, "st5b is an FPU register" );
is ( is_reg_intel   ("ads"), 0, "ads is a register" );
is ( is_reg_intel   ("esx"), 0, "esx is a register" );
is ( is_reg_intel   ("ast0"), 0, "ast0 is a register" );
is ( is_reg_intel   ("st5b"), 0, "st5b is a register" );
is ( is_reg_intel   ("k02"), 0, "k02 is a register" );

