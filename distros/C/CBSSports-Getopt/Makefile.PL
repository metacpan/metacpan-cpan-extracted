use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'CBSSports::Getopt',
    AUTHOR        => 'Jeff Bisbee <jbisbee@cpan.org>',
    VERSION_FROM  => 'lib/CBSSports/Getopt.pm',
    ABSTRACT_FROM => 'lib/CBSSports/Getopt.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'     => 0,
        'Getopt::Long'   => 0,
        'Pod::Usage'     => 0,
        'File::HomeDir'  => 0,
        'File::Basename' => 0,
        'FindBin'        => 0,
    },
    EXE_FILES => ['bin/cbssports-script-starter'],
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'CBSSports-Getopt-*' },
);
