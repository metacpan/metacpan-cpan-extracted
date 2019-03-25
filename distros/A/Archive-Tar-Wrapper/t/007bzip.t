use warnings;
use strict;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);
use File::Which;
use File::Temp qw(tempfile);
use Test::More tests => 5;
use File::Spec;

BEGIN { use_ok('Archive::Tar::Wrapper') }

my $bzip2_path = which('bzip2');

unless ( defined($bzip2_path) ) {
    diag(
'bzip2 is not available on your path! Beware that you will not be able to pack/unpack tarballs compressed with it, please install it ASAP!'
    );
}

SKIP: {
    skip 'bzip2 program is not available', 4 unless ( defined($bzip2_path) );
    my $TARDIR = 'data';
    $TARDIR = File::Spec->catdir( 't', $TARDIR ) unless -d $TARDIR;
    umask(0);
    my $arch = Archive::Tar::Wrapper->new();
    ok( $arch->read( File::Spec->catfile( $TARDIR, 'foo.tar.bz2' ) ),
        "opening compressed tarfile" );
    ok( $arch->locate('001Basic.t'),   "find 001Basic.t" );
    ok( $arch->locate('./001Basic.t'), "find ./001Basic.t" );
    ok( !$arch->locate('nonexist'),    "find nonexist" );
}
