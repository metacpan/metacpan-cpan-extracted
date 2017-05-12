use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CPAN::Testers::Common::Client',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/CPAN/Testers/Common/Client.pm',
    ABSTRACT_FROM       => 'lib/CPAN/Testers/Common/Client.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp'                  => 0,
        'Capture::Tiny'         => 0,
        'Config::Perl::V'       => 0,
        'Devel::Platform::Info' => 0,
        'ExtUtils::MakeMaker'   => 6.36,
        'File::Glob'            => 0,
        'File::Spec'            => 3.19,
        'Probe::Perl'           => 0,
        'Test::More'            => 0,
        'Fcntl'                 => 0,
        'IO::File'              => 0,
        'CPAN::Version'         => 0,

        # C:T:C:C:Config also relies on:
        'File::HomeDir' => 0.58,
        'File::Path'    => 0,
        'IPC::Cmd'      => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/garu/CPAN-Testers-Common-Client',
            bugtracker => 'https://github.com/garu/CPAN-Testers-Common-Client/issues',
            license    => 'http://dev.perl.org/licenses/',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CPAN-Testers-Common-Client-*' },
);
