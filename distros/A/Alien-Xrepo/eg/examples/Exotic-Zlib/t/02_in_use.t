use v5.40;
use blib;
use Test2::V0;
use Exotic::Zlib;
#
my $zlib = Exotic::Zlib->new;

# The package must actually be installed (a build-served snapshot or a store hit); otherwise there
# is nothing at all to exercise.
SKIP: {
    my $info = $zlib->package_info;
    skip 'zlib not installed; run the build first' => 1 unless $info;
    ok defined $zlib->version, 'resolved package version is recorded';
}

# Load the installed artifact and read its version with the first FFI backend that is installed
# (Affix, then FFI::Platypus). zlib resolves static here, so there is nothing to dlopen and this
# legitimately skips; on a platform where zlib ships shared it exercises the real library.
SKIP: {
    my $info = $zlib->package_info;
    skip 'package not installed, or resolved as a static archive with nothing to load' => 1 unless $info && $info->shared && $zlib->ffi_lib;
    my $lib = $zlib->ffi_lib;
    if ( eval { require Affix; Affix->import; 1 } ) {
        Affix::affix( $lib, 'zlibVersion', [], Affix::String() );
        my $version = zlibVersion();
        diag "Affix loaded $lib: zlib $version";
        like $version, qr[^\d+\.\d+(?:\.\d+)?$], 'zlibVersion reports a version';
    }
    elsif ( eval { require FFI::Platypus; 1 } ) {
        my $ffi = FFI::Platypus->new( api => 2, lib => [$lib] );
        $ffi->attach( 'zlibVersion' => [] => 'string' );
        my $version = zlibVersion();
        diag "FFI::Platypus loaded $lib: zlib $version";
        like $version, qr[^\d+\.\d+(?:\.\d+)?$], 'zlibVersion reports a version';
    }
    else {
        skip 'neither Affix nor FFI::Platypus is installed' => 1;
    }
}
#
done_testing;
