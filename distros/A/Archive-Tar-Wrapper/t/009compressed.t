use warnings;
use strict;
use Test::More;
use Archive::Tar::Wrapper;
use File::Spec;
use File::Copy;
use File::Temp qw(tempdir);

my @dirs = qw(t data);
my $arch = Archive::Tar::Wrapper->new();
is( $arch->is_compressed( File::Spec->catdir( @dirs, 'foo.tgz' ) ),
    'z', 'Identify a gziped tarball' );
is( $arch->is_compressed( File::Spec->catdir( @dirs, 'foo.tar.bz2' ) ),
    'j', 'Identify a bziped tarball' );
is( $arch->is_compressed( File::Spec->catdir( @dirs, 'bar.tar' ) ),
    '', 'Identify non-compressed tarball' );
ok( !$arch->is_compressed( File::Spec->catdir( @dirs, 'bar.tar' ) ),
    'Non-compressed tarball evaluate as false' );
my $temp_dir = tempdir( CLEANUP => 1 );
my $gziped_undercover = File::Spec->catdir( $temp_dir, 'foo' );
copy( File::Spec->catdir( @dirs, 'foo.tgz' ), $gziped_undercover );
is( $arch->is_compressed($gziped_undercover),
    'z', 'Detects gziped file without file extension' );

done_testing;
