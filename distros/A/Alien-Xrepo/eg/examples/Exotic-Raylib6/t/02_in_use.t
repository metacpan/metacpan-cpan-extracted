use v5.40;
use blib;
use Test2::V0;
use Exotic::Raylib6;
#
my $raylib = Exotic::Raylib6->new;

# The package must actually be installed (a build-served snapshot or a store
# hit); otherwise there is nothing at all to exercise.
SKIP: {
    my $info = $raylib->package_info;
    skip 'raylib not installed; run the build first' => 1 unless $info;
    ok defined $raylib->version, 'resolved package version is recorded';
}

# raylib has no exported version getter, so load the installed shared library
# and confirm it answers a real call (IsWindowReady is false before
# InitWindow). First FFI backend that is installed (Affix, then
# FFI::Platypus); neither installed, or a static archive: skip.
SKIP: {
    my $info = $raylib->package_info;
    skip 'package not installed, or resolved as a static archive with nothing to load' => 1 unless $info && $info->shared && $raylib->ffi_lib;
    my $lib = $raylib->ffi_lib;
    if ( eval { require Affix; Affix->import; 1 } ) {
        Affix::affix( $lib, 'IsWindowReady', [], Affix::Int() );
        my $ready = IsWindowReady();
        diag "Affix loaded $lib; IsWindowReady=$ready";
        is $ready, 0, 'raylib answers a real call (no window yet)';
    }
    elsif ( eval { require FFI::Platypus; 1 } ) {
        my $ffi = FFI::Platypus->new( api => 2, lib => [$lib] );
        $ffi->attach( 'IsWindowReady' => [] => 'int' );
        my $ready = IsWindowReady();
        diag "FFI::Platypus loaded $lib; IsWindowReady=$ready";
        is $ready, 0, 'raylib answers a real call (no window yet)';
    }
    else {
        skip 'neither Affix nor FFI::Platypus is installed' => 1;
    }
}
#
done_testing;
