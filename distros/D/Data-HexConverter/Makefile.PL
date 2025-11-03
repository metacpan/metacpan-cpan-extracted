use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my $is_x86 = ($Config{archname} =~ /x86_64|i[3456]86/) ? 1 : 0;

# global flags for XS code
# IMPORTANT: do NOT put -fvisibility=hidden here. it hides boot_Data__HexConverter
my $ccflags = $Config{ccflags} || '';
$ccflags .= ' -O3 -Wall -Wextra -fPIC -DHEXSIMD_BUILD';

if ($is_x86) {
    # generic x86-64, keep generic code safe. AVX is enabled per-function in src/hexsimd.c
    $ccflags .= ' -march=x86-64 -mno-avx -mno-avx2 -mno-avx512f';
}

# env-controlled AVX512
my $env = $ENV{HEXSIMD_ENABLE_AVX512} // '';
my $want_avx512 =
    ($env ne '' && $env ne '0' && lc($env) ne 'false') ? 1 : 0;

if ($want_avx512) {
    $ccflags .= ' -DHEXSIMD_ENABLE_AVX512';
}

WriteMakefile(
    NAME         => 'Data::HexConverter',
    VERSION_FROM => 'lib/Data/HexConverter.pm',
    ABSTRACT     => 'SIMD accelerated hex <-> binary with runtime dispatch',
    AUTHOR       => 'Jared Still',
    LICENSE      => 'perl',
    CCFLAGS      => $ccflags,
    INC          => '-Isrc',
    # force link of both XS and C core
    OBJECT       => 'HexConverter$(OBJ_EXT) src/hexsimd$(OBJ_EXT)',
    clean        => {
        FILES => 'Data-HexConverter-* *.gcov *.gcda *.gcno',
    },
    META_MERGE   => {
        resources => {
            repository => 'https://metacpan.org/release/Data-HexConverter',
        },
    },
);

# compile src/hexsimd.c with extra visibility=hidden. but NOT the XS.
sub MY::postamble {
    return <<'POST';
src/hexsimd$(OBJ_EXT): src/hexsimd.c src/hexsimd.h
	$(CC) $(CCFLAGS) -fvisibility=hidden $(OPTIMIZE) $(INC) -c src/hexsimd.c -o $@
POST
}
