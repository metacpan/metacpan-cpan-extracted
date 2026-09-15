use v5.40;
use blib;
use Test2::V0;
use Exotic::Zstandard;
#
my $zstd = Exotic::Zstandard->new;

# The package must actually be installed (a build-served snapshot or a store
# hit); otherwise there is nothing at all to exercise.
SKIP: {
    my $info = $zstd->package_info;
    skip 'zstd not installed; run the build first' => 1 unless $info;
    ok defined $zstd->version, 'resolved package version is recorded';
}

# Load the installed shared library and read its version with the first FFI
# backend that is installed (Affix, then FFI::Platypus). Neither installed,
# or the library resolved static (nothing to dlopen): skip.
SKIP: {
    my $info = $zstd->package_info;
    skip 'package not installed, or resolved as a static archive with nothing to load' => 1 unless $info && $info->shared && $zstd->ffi_lib;
    my $lib = $zstd->ffi_lib;
    if ( eval { require Affix; Affix->import; 1 } ) {
        Affix::affix( $lib, 'ZSTD_versionString', [], Affix::String() );
        my $version = ZSTD_versionString();
        diag "Affix loaded $lib: zstd $version";
        like $version, qr{^\d+\.\d+(?:\.\d+)?$}, 'ZSTD_versionString reports a semantic version';
    }
    elsif ( eval { require FFI::Platypus; 1 } ) {
        my $ffi = FFI::Platypus->new( api => 2, lib => [$lib] );
        $ffi->attach( 'ZSTD_versionString' => [] => 'string' );
        my $version = ZSTD_versionString();
        diag "FFI::Platypus loaded $lib: zstd $version";
        like $version, qr{^\d+\.\d+(?:\.\d+)?$}, 'ZSTD_versionString reports a semantic version';
    }
    else {
        skip 'neither Affix nor FFI::Platypus is installed' => 1;
    }
}
#
done_testing;
