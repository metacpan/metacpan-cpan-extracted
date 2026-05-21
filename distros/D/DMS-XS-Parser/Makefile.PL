use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;
use Config;

# The C parser lives in the dms-c repo, vendored as a git submodule
# at ../external/dms-c for in-tree development. For released tarballs the
# same sources are bundled at vendor/dms-c/ so `cpan install` works without
# the surrounding repo. Prefer the bundled copy when present (so end-user
# installs are self-contained); otherwise fall back to the dev submodule.
my $vendored = File::Spec->rel2abs(File::Spec->catdir('vendor', 'dms-c'));
my $devsrc   = File::Spec->rel2abs(File::Spec->catdir('..', 'external', 'dms-c'));
my $c_dir;
if (-e File::Spec->catfile($vendored, 'dms.c')) {
    $c_dir = $vendored;
} elsif (-e File::Spec->catfile($devsrc, 'dms.c')) {
    $c_dir = $devsrc;
} else {
    die "dms-c sources not found.\n"
      . "  expected vendored at $vendored (release tarball)\n"
      . "  or submodule at $devsrc (dev clone — run: git submodule update --init --recursive)\n";
}

WriteMakefile(
    NAME          => 'DMS::XS::Parser',
    VERSION_FROM  => 'lib/DMS/XS/Parser.pm',
    ABSTRACT      => 'XS wrapper around the C DMS parser',
    AUTHOR        => 'DMS',
    LICENSE       => 'mit',
    MIN_PERL_VERSION => '5.014',
    XS            => { 'Parser.xs' => 'Parser.c' },
    C             => [ 'Parser.c', "$c_dir/dms.c", "$c_dir/vendor/utf8proc/utf8proc.c" ],
    OBJECT        => '$(BASEEXT)$(OBJ_EXT) dms$(OBJ_EXT) utf8proc$(OBJ_EXT)',
    INC           => "-I$c_dir -I$c_dir/vendor/utf8proc -I.",
    # -ffunction-sections / -fdata-sections + --gc-sections strips
    # utf8proc functions/tables we don't reach at link time. The bulk of
    # the DLL's weight is utf8proc's per-codepoint property data; we
    # only call utf8proc_map for NFC, which uses a subset.
    OPTIMIZE      => '-O2 -ffunction-sections -fdata-sections',
    # SPEC §Unicode normalization: -DUTF8PROC_STATIC suppresses Windows
    # __declspec(dllimport) on utf8proc symbols.
    DEFINE        => '-D_POSIX_C_SOURCE=200809L -DUTF8PROC_STATIC',
    # Append warning suppressions to perl's $Config{ccflags} — overriding
    # CCFLAGS entirely strips the perl-ABI macros (USE_ITHREADS, etc.) and
    # produces a DLL with a handshake-key mismatch at load time on Windows.
    CCFLAGS       => "$Config{ccflags} -Wall -Wno-unused-parameter -Wno-comment -Wno-unused-function -Wno-unused-variable",
    # --gc-sections drops unreferenced sections (the function/data
    # sections from -ffunction-sections / -fdata-sections above).
    # On the realistic fixture this trims the .dll from 512 KB to a
    # smaller footprint (utf8proc has many lookup paths we don't use).
    LDDLFLAGS     => "$Config{lddlflags} -Wl,--gc-sections",
    PREREQ_PM     => {
        'Tie::IxHash' => 0,
    },
    TEST_REQUIRES => {},
    clean         => { FILES => 'Parser.c dms.o utf8proc.o Parser.o' },
);

# Tell make how to find dms.c and utf8proc.c outside our dir.
package MY;
sub postamble {
    my $self  = shift;
    my $src   = "$c_dir/dms.c";
    my $usrc  = "$c_dir/vendor/utf8proc/utf8proc.c";
    my $uhdr  = "$c_dir/vendor/utf8proc/utf8proc.h";
    my $udata = "$c_dir/vendor/utf8proc/utf8proc_data.c";
    return <<"MAKE_FRAG";
dms\$(OBJ_EXT) : $src $c_dir/dms.h $uhdr
\t\$(CC) -c \$(CCFLAGS) \$(OPTIMIZE) \$(CCCDLFLAGS) \$(INC) \$(DEFINE) -o dms\$(OBJ_EXT) $src

utf8proc\$(OBJ_EXT) : $usrc $uhdr $udata
\t\$(CC) -c \$(CCFLAGS) \$(OPTIMIZE) \$(CCCDLFLAGS) \$(INC) \$(DEFINE) -o utf8proc\$(OBJ_EXT) $usrc
MAKE_FRAG
}
