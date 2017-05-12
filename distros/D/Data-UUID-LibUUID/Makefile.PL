#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

my $conf = WriteMakefile(
    NAME         => 'Data::UUID::LibUUID',
    VERSION_FROM => 'lib/Data/UUID/LibUUID.pm',
    INSTALLDIRS  => 'site',
    SIGN         => 1,
    PL_FILES     => { },
    LIBS         => [ "-luuid" ],
    PREREQ_PM    => {
        'Test::use::ok' => 0,
        'Test::More' => 0,
        'Sub::Exporter' => 0,
        'MIME::Base64' => 0,
        'asa' => 0,
    },
);

unless ( try_compiling($conf, "hdr_check.h") ) {
    warn "\n*** ERROR: <uuid/uuid.h> seems to be missing ***\n"
       . "please install libuuid from e2fsprogs (available as uuid-dev on debian)\n\n";

    # Or CPAN::Reporter reports a failure
    unlink("Makefile");

    exit 0; # not a fail
}

use File::Spec;

sub try_compiling {
    my ($conf, $file) = @_;

    my @cc = ( $conf->{CC}, '-c', $conf->{CCFLAGS}, $conf->{INC} || '' );

    if ( -e ( my $devnull = File::Spec->devnull ) ) {
        push @cc, '-o' => $devnull; # precompiled headers are pretty big
    }

    my $cmd = join " ", @cc, $file;

    warn "trying $cmd\n";

    return ( system($cmd) == 0 )
}
