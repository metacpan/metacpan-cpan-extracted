use v5.40;
use blib;
use Test2::V0;
use Exotic::SQLite3;
#
my $sqlite = Exotic::SQLite3->new;

# The package must actually be installed (a build-served snapshot or a store hit); otherwise there
# is nothing at all to exercise.
SKIP: {
    my $info = $sqlite->package_info;
    skip 'sqlite3 not installed; run the build first' => 1 unless $info;
    ok defined $sqlite->version, 'resolved package version is recorded';
}

# Load the installed artifact and read its version with the first FFI backend that is installed
# (Affix, then FFI::Platypus). sqlite3 resolves static with the mingw toolchain here, so there is
# nothing to dlopen and this legitimately skips; on a platform where it ships shared it exercises
# the real library.
SKIP: {
    my $info = $sqlite->package_info;
    skip 'package not installed, or resolved as a static archive with nothing to load' => 1 unless $info && $info->shared && $sqlite->ffi_lib;
    my $lib = $sqlite->ffi_lib;
    if ( eval { require Affix; Affix->import; 1 } ) {
        Affix::affix( $lib, 'sqlite3_libversion', [], Affix::String() );
        my $version = sqlite3_libversion();
        diag "Affix loaded $lib: sqlite3 $version";
        like $version, qr{^\d+\.\d+(?:\.\d+)?$}, 'sqlite3_libversion reports a semantic version';
    }
    elsif ( eval { require FFI::Platypus; 1 } ) {
        my $ffi = FFI::Platypus->new( api => 2, lib => [$lib] );
        $ffi->attach( 'sqlite3_libversion' => [] => 'string' );
        my $version = sqlite3_libversion();
        diag "FFI::Platypus loaded $lib: sqlite3 $version";
        like $version, qr{^\d+\.\d+(?:\.\d+)?$}, 'sqlite3_libversion reports a semantic version';
    }
    else {
        skip 'neither Affix nor FFI::Platypus is installed' => 1;
    }
}
#
done_testing;
