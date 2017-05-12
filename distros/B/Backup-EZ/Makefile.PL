use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Backup::EZ',
    AUTHOR             => q{John Gravatt <john@gravatt.org>},
    VERSION_FROM       => 'lib/Backup/EZ.pm',
    ABSTRACT_FROM      => 'lib/Backup/EZ.pm',
    LICENSE            => 'Artistic_2_0',
    EXE_FILES          => ['bin/ezbackup'],
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    PREREQ_PM          => {
        'Config::General'         => 0,
        'File::Slurp'             => 0,
        'Data::UUID'              => 0,
        'Unix::Syslog'            => 0,
        'Data::Printer'           => 0,
        'File::ShareDir'          => 0,
        'File::ShareDir::Install' => 0,
        'Devel::Confess'          => 0,
        'Data::Dumper'            => 0,
        'File::RandomGenerator'   => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'              => 0,
        'File::ShareDir::Install' => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Backup-EZ-*' },
);

package MY;
use File::ShareDir::Install qw( postamble );
