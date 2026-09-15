use v5.40;
use blib;
use Test2::V0;
use Exotic::Lsquic;
#
my $lsquic = Exotic::Lsquic->new;

# The package must actually be installed (a build-served snapshot or a store
# hit); otherwise there is nothing at all to exercise.
SKIP: {
    my $info = $lsquic->package_info;
    skip 'lsquic not installed; run the build first' => 1 unless $info;
    ok defined $lsquic->version, 'resolved package version is recorded';
}

# lsquic has no exported version getter, so load the installed library and
# confirm it answers a real call (lsquic_global_init(0) returns 0). First FFI
# backend that is installed (Affix, then FFI::Platypus); neither installed, or
# a static archive: skip.
SKIP: {
    my $info = $lsquic->package_info;
    skip 'package not installed, or resolved as a static archive with nothing to load' => 1 unless $info && $info->shared && $lsquic->ffi_lib;
    my $lib = $lsquic->ffi_lib;
    if ( eval { require Affix; Affix->import; 1 } ) {
        Affix::affix( $lib, 'lsquic_global_init', [ Affix::Int() ], Affix::Int() );
        my $rc = lsquic_global_init(0);
        diag "Affix loaded $lib; lsquic_global_init(0) rc=$rc";
        is $rc, 0, 'lsquic initializes (real library responds)';
    }
    elsif ( eval { require FFI::Platypus; 1 } ) {
        my $ffi = FFI::Platypus->new( api => 2, lib => [$lib] );
        $ffi->attach( 'lsquic_global_init' => ['int'] => 'int' );
        my $rc = lsquic_global_init(0);
        diag "FFI::Platypus loaded $lib; lsquic_global_init(0) rc=$rc";
        is $rc, 0, 'lsquic initializes (real library responds)';
    }
    else {
        skip 'neither Affix nor FFI::Platypus is installed' => 1;
    }
}
#
done_testing;
