use warnings;
use strict;
use Test::More tests => 7;
use Archive::Tar::Wrapper;
use File::Spec;
use File::Which qw(which);

SKIP: {
    skip 'This test is designed to run only on OpenBSD', 7
      unless ( $^O eq 'openbsd' );
    my $tar_path = which('tar');
    note("tar available at $tar_path");

    my $tar = Archive::Tar::Wrapper->new( tar_read_options => 'p' );

    is( $tar->{tar_read_options},
        '-p', 'tar parameters on OpenBSD have a "-" prefix' );
    ok( $tar->_is_openbsd(), 'correctly identify the OS' );
    is_deeply(
        $tar->_read_openbsd_opts('z'),
        [ "$tar_path", '-z', '-x', '-p' ],
        'got correct options for gziped tarball'
    ) or diag( explain( $tar->_read_openbsd_opts('z') ) );
    is_deeply(
        $tar->_read_openbsd_opts('j'),
        [ "$tar_path", '-j', '-x', '-p' ],
        'got correct options for bziped tarball'
    ) or diag( explain( $tar->_read_openbsd_opts('j') ) );

    for my $file (qw(bar.tar foo.tgz foo.tar.bz2)) {
        ok( $tar->read( File::Spec->catfile( 't', 'data', $file ) ),
            "read tarball $file" );
    }
}

