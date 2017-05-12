use strict;
use warnings;

use constant {
    CS_ARCH_ARM   => 0,
    CS_ARCH_ARM64 => 1,
    CS_ARCH_MIPS  => 2,
    CS_ARCH_X86   => 3,
    CS_ARCH_PPC   => 4,
    CS_ARCH_SPARC => 5,
    CS_ARCH_SYSZ  => 6,
    CS_ARCH_XCORE => 7,
    CS_ARCH_MAX   => 8,
    CS_ARCH_ALL   => 0xFFFF
};

use constant {
    CS_MODE_ARM        => 0,
    CS_MODE_16         => 1<<1,
    CS_MODE_32         => 1<<2,
    CS_MODE_64         => 1<<3,
    CS_MODE_THUMB      => 1<<4,
    CS_MODE_MCLASS     => 1<<5,
    CS_MODE_V8         => 1<<6,
    CS_MODE_MICRO      => 1<<4,
    CS_MODE_MIPS3      => 1<<5,
    CS_MODE_MIPS32R6   => 1<<6,
    CS_MODE_MIPSGP64   => 1<<7,
    CS_MODE_V9         => 1<<4,
    CS_MODE_BIG_ENDIAN => 1 << 31,
    CS_MODE_MIPS32     => 1<<2,
    CS_MODE_MIPS64     => 1<<3
};

use constant {
    CS_OPT_SYNTAX         => 1,
    CS_OPT_DETAIL         => 2,
    CS_OPT_MODE           => 3,
    CS_OPT_MEM            => 4,
    CS_OPT_SKIPDATA       => 5,
    CS_OPT_SKIPDATA_SETUP => 6
};

use constant {
    CS_OPT_OFF              => 0,
    CS_OPT_ON               => 3,
    CS_OPT_SYNTAX_DEFAULT   => 0,
    CS_OPT_SYNTAX_INTEL     => 1,
    CS_OPT_SYNTAX_ATT       => 2,
    CS_OPT_SYNTAX_NOREGNAME => 3
};

use constant {
    CS_SUPPORT_DIET       => CS_ARCH_ALL+1,
    CS_SUPPORT_X86_REDUCE => CS_ARCH_ALL+2
};

1;
