use 5.007003;

use strict;
use ExtUtils::MakeMaker;
use File::Spec;

my $conf = WriteMakefile(
    NAME              => 'CDB::TinyCDB',
    VERSION_FROM      => 'lib/CDB/TinyCDB.pm', # finds $VERSION
    BUILD_REQUIRES    => {
        'Test::More'       => 0,
        'Test::Exception'  => 0,
        'Test::NoWarnings' => 0,
    },
    PREREQ_PM         => {
        'XSLoader'         => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CDB/TinyCDB.pm', # retrieve abstract from module
       AUTHOR         => 'Alex J. G. Burzyński <ajgb@cpan.org>') : ()),
    LIBS              => [
        '-lcdb_pic',                  # RHEL
        '-L/usr/local/lib -lcdb_pic',
        '-lcdb',
        '-L/usr/local/lib -lcdb'
    ],
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    XSOPT             => '-prototypes',
    LICENSE           => 'perl',
);

# checking that library exists borrowed from Data::UUID::LibUUID
unless ( libcdb_installed() ) {
    warn "\n*** ERROR: <cdb.h> library not found ***\n",
         "please install TinyCDB library (libcdb-dev on debian/ubuntu)\n\n";

    unlink("Makefile");

    exit 1;
}

sub libcdb_installed {
    my @cc = (
        $conf->{CC}, '-c', $conf->{CCFLAGS},
        '-I/usr/include ', $conf->{INC} || ''
    );

    if ( -e ( my $devnull = File::Spec->devnull ) ) {
        # precompiled headers are pretty big
        push @cc, '-o' => $devnull;
    }

    my $cmd = join " ", @cc, "cdb-check.h";

    warn "trying $cmd\n";

    return ( system($cmd) == 0 );
}
