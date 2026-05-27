use Test2::V0;
use Test::Alien;
use Alien::Libgit2;
use FFI::Platypus 2.00;

alien_ok 'Alien::Libgit2';

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
        ok( defined $maj && $maj >= 1, "libgit2 major version >= 1 (got $maj.$min.$rev)" );

        git_libgit2_shutdown();
    };

done_testing;
