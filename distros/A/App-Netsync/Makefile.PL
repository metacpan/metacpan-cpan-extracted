use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'App::Netsync',
    AUTHOR             => 'dmtucker@ucsc.edu',
    VERSION_FROM       => 'lib/App/Netsync.pm',
    ABSTRACT_FROM      => 'lib/App/Netsync.pm',
    LICENSE            => 'Perl_5',
    META_MERGE => {
        'meta-spec' => {version => '2'},
        provides => {
            'App::Netsync' => {
                file    => 'lib/App/Netsync.pm',
                version => 'v4.0.0',
            },
            'App::Netsync::Configurator' => {
                file    => 'lib/App/Netsync/Configurator.pm',
                version => 'v4.0.0',
            },
            'App::Netsync::Network' => {
                file    => 'lib/App/Netsync/Network.pm',
                version => 'v4.0.0',
            },
            'App::Netsync::Scribe' => {
                file    => 'lib/App/Netsync/Scribe.pm',
                version => 'v4.0.0',
            },
            'App::Netsync::SNMP' => {
                file    => 'lib/App/Netsync/SNMP.pm',
                version => 'v4.0.0',
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/dmtucker/netsync.git',
                web  => 'https://github.com/dmtucker/netsync',
            },
        },
    },
    EXE_FILES => ['script/netsync'],
    MIN_PERL_VERSION => '5.010001',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::CheckManifest' => 0.9,
        'Test::Kwalitee'      => 0,
        'Test::More'          => 0,
        'Test::Pod'           => 1.22,
    },
    PREREQ_PM => {
        # Core
        'File::Basename' => 0,
        'Getopt::Std'    => 0,
        'Pod::Usage'     => 1.61,
        'POSIX'          => 0,
        'Scalar::Util'   => 1.32,
        'version'        => 0.9917,
        # App::Netsync
        'DBI'            => 1.622,
        'Net::DNS'       => 0.66,
        'Text::CSV'      => 1.32,
        # App::Netsync::Configurator
        'Config::Simple' => 4.58,
        # App::Netsync::Network
        'SNMP'           => 5.0702,
        'SNMP::Info'     => 3.05,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-Netsync-*' },
);
