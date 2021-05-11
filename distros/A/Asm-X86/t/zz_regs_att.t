#!perl -T -w

use strict;
use warnings;

use Test::More tests => 9 + 188; # 9 + 14*9 + 6 + 22;
use Asm::X86 qw(
	@regs8_att @regs16_att @segregs_att @regs32_att @regs64_att
	@regs_mm_att @regs_att @regs_fpu_att @regs_opmask_att
	is_reg_att is_reg8_att is_reg16_att is_reg32_att is_reg64_att
	is_reg_mm_att is_segreg_att is_reg_fpu_att is_reg_opmask_att
	is_addressable32_att is_r32_in64_att
	);

cmp_ok ( $#regs8_att,   '>', 0, "Non-empty 8-bit register list" );
cmp_ok ( $#regs16_att,  '>', 0, "Non-empty 16-bit register list" );
cmp_ok ( $#segregs_att, '>', 0, "Non-empty segment register list" );
cmp_ok ( $#regs32_att,  '>', 0, "Non-empty 32-bit register list" );
cmp_ok ( $#regs64_att,  '>', 0, "Non-empty 64-bit register list" );
cmp_ok ( $#regs_mm_att, '>', 0, "Non-empty multimedia register list" );
cmp_ok ( $#regs_fpu_att,'>', 0, "Non-empty FPU register list" );
cmp_ok ( $#regs_opmask_att,'>', 0, "Non-empty opmask register list" );
cmp_ok ( $#regs_att,    '>', 0, "Non-empty register list" );

is ( is_reg_att   ('%AL'), 1, "AL is a register" );
is ( is_reg8_att  ("\%AL"), 1, "AL is an 8-bit register" );
is ( is_reg16_att ("\%AL"), 0, "AL is a 16-bit register" );
is ( is_reg32_att ("\%AL"), 0, "AL is a 32-bit register" );
is ( is_reg64_att ("\%AL"), 0, "AL is a 64-bit register" );
is ( is_reg_mm_att("\%AL"), 0, "AL is a multimedia register" );
is ( is_segreg_att("\%AL"), 0, "AL is a segment register" );
is ( is_reg_fpu_att("\%AL"), 0, "AL is an FPU register" );
is ( is_reg_opmask_att("\%AL"), 0, "AL is an opmask register" );

is ( is_reg_att   ("\%r15b"), 1, "r15b is a register" );
is ( is_reg8_att  ("\%r15b"), 1, "r15b is an 8-bit register" );
is ( is_reg16_att ("\%r15b"), 0, "r15b is a 16-bit register" );
is ( is_reg32_att ("\%r15b"), 0, "r15b is a 32-bit register" );
is ( is_reg64_att ("\%r15b"), 0, "r15b is a 64-bit register" );
is ( is_reg_mm_att("\%r15b"), 0, "r15b is a multimedia register" );
is ( is_segreg_att("\%r15b"), 0, "r15b is a segment register" );
is ( is_reg_fpu_att("\%r15b"), 0, "r15b is an FPU register" );
is ( is_reg_opmask_att("\%r15b"), 0, "r15b is an opmask register" );

is ( is_reg_att   ("\%AX"), 1, "AX is a register" );
is ( is_reg8_att  ("\%AX"), 0, "AX is an 8-bit register" );
is ( is_reg16_att ("\%AX"), 1, "AX is a 16-bit register" );
is ( is_reg32_att ("\%AX"), 0, "AX is a 32-bit register" );
is ( is_reg64_att ("\%AX"), 0, "AX is a 64-bit register" );
is ( is_reg_mm_att("\%AX"), 0, "AX is a multimedia register" );
is ( is_segreg_att("\%AX"), 0, "AX is a segment register" );
is ( is_reg_fpu_att("\%AX"), 0, "AX is an FPU register" );
is ( is_reg_opmask_att("\%AX"), 0, "AX is an opmask register" );

is ( is_reg_att   ("\%r10w"), 1, "r10w is a register" );
is ( is_reg8_att  ("\%r10w"), 0, "r10w is an 8-bit register" );
is ( is_reg16_att ("\%r10w"), 1, "r10w is a 16-bit register" );
is ( is_reg32_att ("\%r10w"), 0, "r10w is a 32-bit register" );
is ( is_reg64_att ("\%r10w"), 0, "r10w is a 64-bit register" );
is ( is_reg_mm_att("\%r10w"), 0, "r10w is a multimedia register" );
is ( is_segreg_att("\%r10w"), 0, "r10w is a segment register" );
is ( is_reg_fpu_att("\%r10w"), 0, "r10w is an FPU register" );
is ( is_reg_opmask_att("\%r10w"), 0, "r10w is an opmask register" );

is ( is_reg_att   ("\%EBX"), 1, "EBX is a register" );
is ( is_reg8_att  ("\%EBX"), 0, "EBX is an 8-bit register" );
is ( is_reg16_att ("\%EBX"), 0, "EBX is a 16-bit register" );
is ( is_reg32_att ("\%EBX"), 1, "EBX is a 32-bit register" );
is ( is_reg64_att ("\%EBX"), 0, "EBX is a 64-bit register" );
is ( is_reg_mm_att("\%EBX"), 0, "EBX is a multimedia register" );
is ( is_segreg_att("\%EBX"), 0, "EBX is a segment register" );
is ( is_reg_fpu_att("\%EBX"), 0, "EBX is an FPU register" );
is ( is_reg_opmask_att("\%EBX"), 0, "EBX is an opmask register" );

is ( is_reg_att   ("\%r8l"), 1, "r8l is a register" );
is ( is_reg8_att  ("\%r8l"), 0, "r8l is an 8-bit register" );
is ( is_reg16_att ("\%r8l"), 0, "r8l is a 16-bit register" );
is ( is_reg32_att ("\%r8l"), 1, "r8l is a 32-bit register" );
is ( is_reg64_att ("\%r8l"), 0, "r8l is a 64-bit register" );
is ( is_reg_mm_att("\%r8l"), 0, "r8l is a multimedia register" );
is ( is_segreg_att("\%r8l"), 0, "r8l is a segment register" );
is ( is_reg_fpu_att("\%r8l"), 0, "r8l is an FPU register" );
is ( is_reg_opmask_att("\%r8l"), 0, "r8l is an opmask register" );

is ( is_reg_att   ("\%rdi"), 1, "rdi is a register" );
is ( is_reg8_att  ("\%rdi"), 0, "rdi is an 8-bit register" );
is ( is_reg16_att ("\%rdi"), 0, "rdi is a 16-bit register" );
is ( is_reg32_att ("\%rdi"), 0, "rdi is a 32-bit register" );
is ( is_reg64_att ("\%rdi"), 1, "rdi is a 64-bit register" );
is ( is_reg_mm_att("\%rdi"), 0, "rdi is a multimedia register" );
is ( is_segreg_att("\%rdi"), 0, "rdi is a segment register" );
is ( is_reg_fpu_att("\%rdi"), 0, "rdi is an FPU register" );
is ( is_reg_opmask_att("\%rdi"), 0, "rdi is an opmask register" );

is ( is_reg_att   ("\%xmm9"), 1, "xmm9 is a register" );
is ( is_reg8_att  ("\%xmm9"), 0, "xmm9 is an 8-bit register" );
is ( is_reg16_att ("\%xmm9"), 0, "xmm9 is a 16-bit register" );
is ( is_reg32_att ("\%xmm9"), 0, "xmm9 is a 32-bit register" );
is ( is_reg64_att ("\%xmm9"), 0, "xmm9 is a 64-bit register" );
is ( is_reg_mm_att("\%xmm9"), 1, "xmm9 is a multimedia register" );
is ( is_segreg_att("\%xmm9"), 0, "xmm9 is a segment register" );
is ( is_reg_fpu_att("\%xmm9"), 0, "xmm9 is an FPU register" );
is ( is_reg_opmask_att("\%xmm9"), 0, "xmm9 is an opmask register" );

is ( is_reg_att   ("\%mm6"), 1, "mm6 is a register" );
is ( is_reg8_att  ("\%mm6"), 0, "mm6 is an 8-bit register" );
is ( is_reg16_att ("\%mm6"), 0, "mm6 is a 16-bit register" );
is ( is_reg32_att ("\%mm6"), 0, "mm6 is a 32-bit register" );
is ( is_reg64_att ("\%mm6"), 0, "mm6 is a 64-bit register" );
is ( is_reg_mm_att("\%mm6"), 1, "mm6 is a multimedia register" );
is ( is_segreg_att("\%mm6"), 0, "mm6 is a segment register" );
is ( is_reg_fpu_att("\%mm6"), 0, "mm6 is an FPU register" );
is ( is_reg_opmask_att("\%mm6"), 0, "mm6 is an opmask register" );

is ( is_reg_att   ("\%st0"), 1, "st0 is a register" );
is ( is_reg8_att  ("\%st0"), 0, "st0 is an 8-bit register" );
is ( is_reg16_att ("\%st0"), 0, "st0 is a 16-bit register" );
is ( is_reg32_att ("\%st0"), 0, "st0 is a 32-bit register" );
is ( is_reg64_att ("\%st0"), 0, "st0 is a 64-bit register" );
is ( is_reg_mm_att("\%st0"), 0, "st0 is a multimedia register" );
is ( is_segreg_att("\%st0"), 0, "st0 is a segment register" );
is ( is_reg_fpu_att("\%st0"), 1, "st0 is an FPU register" );
is ( is_reg_opmask_att("\%st0"), 0, "st0 is an opmask register" );

is ( is_reg_att   ("\%cs"), 1, "cs is a register" );
is ( is_reg8_att  ("\%ds"), 0, "ds is an 8-bit register" );
is ( is_reg16_att ("\%Es"), 1, "Es is a 16-bit register" );
is ( is_reg32_att ("\%ss"), 0, "ss is a 32-bit register" );
is ( is_reg64_att ("\%fS"), 0, "fS is a 64-bit register" );
is ( is_reg_mm_att("\%gs"), 0, "gs is a multimedia register" );
is ( is_segreg_att("\%cs"), 1, "cs is a segment register" );
is ( is_reg_fpu_att("\%ds"), 0, "ds is an FPU register" );
is ( is_reg_opmask_att("\%ds"), 0, "ds is an opmask register" );

is ( is_segreg_att("\%cs"), 1, "cs is a segment register" );
is ( is_segreg_att("\%ds"), 1, "ds is a segment register" );
is ( is_segreg_att("\%Es"), 1, "Es is a segment register" );
is ( is_segreg_att("\%ss"), 1, "ss is a segment register" );
is ( is_segreg_att("\%fS"), 1, "fS is a segment register" );
is ( is_segreg_att("\%gs"), 1, "gs is a segment register" );

is ( is_reg_att   ("\%ymm0"), 1, "ymm0 is a register" );
is ( is_reg8_att  ("\%ymm0"), 0, "ymm0 is an 8-bit register" );
is ( is_reg16_att ("\%ymm0"), 0, "ymm0 is a 16-bit register" );
is ( is_reg32_att ("\%ymm0"), 0, "ymm0 is a 32-bit register" );
is ( is_reg64_att ("\%ymm0"), 0, "ymm0 is a 64-bit register" );
is ( is_reg_mm_att("\%ymm0"), 1, "ymm0 is a multimedia register" );
is ( is_segreg_att("\%ymm0"), 0, "ymm0 is a segment register" );
is ( is_reg_fpu_att("\%ymm0"), 0, "ymm0 is an FPU register" );
is ( is_reg_opmask_att("\%ymm0"), 0, "ymm0 is an opmask register" );

is ( is_reg_att   ("\%zmm0"), 1, "zmm0 is a register" );
is ( is_reg8_att  ("\%zmm0"), 0, "zmm0 is an 8-bit register" );
is ( is_reg16_att ("\%zmm0"), 0, "zmm0 is a 16-bit register" );
is ( is_reg32_att ("\%zmm0"), 0, "zmm0 is a 32-bit register" );
is ( is_reg64_att ("\%zmm0"), 0, "zmm0 is a 64-bit register" );
is ( is_reg_mm_att("\%zmm0"), 1, "zmm0 is a multimedia register" );
is ( is_segreg_att("\%zmm0"), 0, "zmm0 is a segment register" );
is ( is_reg_fpu_att("\%zmm0"), 0, "zmm0 is an FPU register" );
is ( is_reg_opmask_att("\%zmm0"), 0, "zmm0 is an opmask register" );

is ( is_reg_att   ("\%k1"), 1, "k1 is a register" );
is ( is_reg8_att  ("\%k1"), 0, "k1 is an 8-bit register" );
is ( is_reg16_att ("\%k1"), 0, "k1 is a 16-bit register" );
is ( is_reg32_att ("\%k1"), 0, "k1 is a 32-bit register" );
is ( is_reg64_att ("\%k1"), 0, "k1 is a 64-bit register" );
is ( is_reg_mm_att("\%k1"), 0, "k1 is a multimedia register" );
is ( is_segreg_att("\%k1"), 0, "k1 is a segment register" );
is ( is_reg_fpu_att("\%k1"), 0, "k1 is an FPU register" );
is ( is_reg_opmask_att("\%k1"), 1, "k1 is an opmask register" );

is ( is_reg_att   ("\%axmm6"), 0, "axmm6 is a register" );
is ( is_reg_att   ("\%cax"), 0, "cax is a register" );
is ( is_reg_att   ("\%abx"), 0, "abx is a register" );
is ( is_reg_att   ("\%dal"), 0, "dal is a register" );
is ( is_reg_att   ("\%ald"), 0, "ald is a register" );
is ( is_reg_att   ("\%rsid"), 0, "rsid is a register" );
is ( is_reg_att   ("\%eabx"), 0, "eabx is a register" );
is ( is_reg_att   ("\%ceax"), 0, "ceax is a register" );
is ( is_reg_att   ("\%ebxc"), 0, "ebxc is a register" );
is ( is_reg_att   ("\%amm1"), 0, "amm1 is a register" );
is ( is_reg_att   ("\%mm30"), 0, "mm30 is a register" );
is ( is_reg_att   ("\%r15db"), 0, "r15db is a register" );
is ( is_reg_att   ("\%ar15d"), 0, "ar15d is a register" );
is ( is_segreg_att("\%ads"), 0, "ads is a segment register" );
is ( is_segreg_att("\%esx"), 0, "esx is a segment register" );
is ( is_reg_fpu_att("\%ast0"), 0, "ast0 is an FPU register" );
is ( is_reg_fpu_att("\%st5b"), 0, "st5b is an FPU register" );
is ( is_reg_att   ("\%ads"), 0, "ads is a register" );
is ( is_reg_att   ("\%esx"), 0, "esx is a register" );
is ( is_reg_att   ("\%ast0"), 0, "ast0 is a register" );
is ( is_reg_att   ("\%st5b"), 0, "st5b is a register" );
is ( is_reg_att   ("\%k02"), 0, "k02 is a register" );

is ( is_addressable32_att ("\%al"), 0, "AL can be used for addressing" );
is ( is_addressable32_att ("\%ax"), 0, "AX can be used for addressing" );
is ( is_addressable32_att ("\%eax"), 1, "EAX can be used for addressing" );
is ( is_addressable32_att ("\%mm0"), 0, "MM0 can be used for addressing" );
is ( is_addressable32_att ("\%xmm0"), 0, "XMM0 can be used for addressing" );
is ( is_addressable32_att ("\%ymm0"), 0, "YMM0 can be used for addressing" );
is ( is_addressable32_att ("\%zmm0"), 0, "ZMM0 can be used for addressing" );
is ( is_addressable32_att ("\%k2"), 0, "K2 can be used for addressing" );

is ( is_addressable32_att ("\%cal"), 0, "CAL can be used for addressing" );
is ( is_addressable32_att ("\%dax"), 0, "DAX can be used for addressing" );
is ( is_addressable32_att ("\%reax"), 0, "REAX can be used for addressing" );
is ( is_addressable32_att ("\%amm0"), 0, "AMM0 can be used for addressing" );
is ( is_addressable32_att ("\%xmm"), 0, "XMM can be used for addressing" );
is ( is_addressable32_att ("\%ymm"), 0, "YMM can be used for addressing" );
is ( is_addressable32_att ("\%zmm"), 0, "ZMM can be used for addressing" );
is ( is_addressable32_att ("\%k12"), 0, "K2 can be used for addressing" );

is ( is_r32_in64_att ("\%al"), 0, "AL can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%ax"), 0, "AX can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%eax"), 0, "EAX can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%r10d"), 1, "R10D can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%mm0"), 0, "MM0 can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%xmm0"), 0, "XMM0 can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%ymm0"), 0, "YMM0 can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%zmm0"), 0, "ZMM0 can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%k2"), 0, "K2 can be used for 32-in-64 addressing" );

is ( is_r32_in64_att ("\%ald"), 0, "ALD can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%axh"), 0, "AXH can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%eaxl"), 0, "EAXL can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%r10ld"), 0, "R10LD can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%mm0l"), 0, "MM0L can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%xmm0d"), 0, "XMM0D can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%ymm0l"), 0, "YMM0L can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%zmm0d"), 0, "ZMM0D can be used for 32-in-64 addressing" );
is ( is_r32_in64_att ("\%k3l"), 0, "K3L can be used for 32-in-64 addressing" );
