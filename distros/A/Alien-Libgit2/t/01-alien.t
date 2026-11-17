#!/usr/bin/env perl
use Test2::V0;
use Test::Alien;
use Alien::Libgit2;
use FFI::Platypus 2.00;

alien_ok 'Alien::Libgit2';

note 'install type: ', Alien::Libgit2->install_type;

# Each CI job pins ALIEN_INSTALL_TYPE; without that pin a failed probe falls
# through to the other path and the job reports green for a path it never ran.
if ( my $forced = $ENV{ALIEN_INSTALL_TYPE} ) {
    is( Alien::Libgit2->install_type, $forced, "install type is the forced '$forced'" );
}

ffi_ok { symbols => [ 'git_libgit2_init', 'git_libgit2_shutdown', 'git_libgit2_version' ] },
    with_subtest {
        my ($ffi) = @_;
        $ffi->attach( git_libgit2_init     => []                          => 'int' );
        $ffi->attach( git_libgit2_shutdown => []                          => 'int' );
        $ffi->attach( git_libgit2_version  => [ 'int*', 'int*', 'int*' ]  => 'int' );

        my $rc = git_libgit2_init();
        ok( $rc >= 1, "git_libgit2_init returned refcount $rc" );

        my ( $maj, $min, $rev );
        git_libgit2_version( \$maj, \$min, \$rev );
        my $version = join '.', map { $_ // '?' } $maj, $min, $rev;

        # 1.9.3 is the floor this distribution exists for: below it libgit2's
        # ssh transport hangs forever on a silent peer (PR #7165). pkg-config
        # enforces it at build time for the system path -- this asserts it
        # against the library actually loaded, on either install type.
        my $at_floor = defined $maj && defined $min && defined $rev
            && ( $maj <=> 1 || $min <=> 9 || $rev <=> 3 ) >= 0;
        ok( $at_floor, "libgit2 $version is at or above the 1.9.3 floor" );

        git_libgit2_shutdown();
    };

done_testing;
