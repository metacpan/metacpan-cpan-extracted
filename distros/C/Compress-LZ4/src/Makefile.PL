use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Compress::LZ4::lz4',
    NO_MYMETA => 1,
    SKIP      => [qw(all static static_lib dynamic dynamic_lib)],
    clean     => { FILES => 'lz4$(LIB_EXT)' },
);


sub MY::top_targets {
    return <<"    MAKE_FRAG";
all      :: static
pure_all :: static
static   :: lz4\$(LIB_EXT)
# https://rt.cpan.org/Public/Bug/Display.html?id=7417
dynamic  :: static

lz4\$(LIB_EXT): \$(O_FILES)
\t\$(AR) cr lz4\$(LIB_EXT) \$(O_FILES)
\t\$(RANLIB) lz4\$(LIB_EXT)
    MAKE_FRAG
}
