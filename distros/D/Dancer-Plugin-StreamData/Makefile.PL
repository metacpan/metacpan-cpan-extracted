use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Dancer::Plugin::StreamData',
    VERSION_FROM      => 'lib/Dancer/Plugin/StreamData.pm',
    ABSTRACT_FROM     => 'lib/Dancer/Plugin/StreamData.pm',
    PREREQ_PM         => { Dancer => 1.3 },
    AUTHOR            => 'Michael McClennen <mmcclenn@cpan.org>',
    LICENSE	      => 'perl',
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean             => { FILES => 'Dancer-Plugin-StreamData-*' },
);
