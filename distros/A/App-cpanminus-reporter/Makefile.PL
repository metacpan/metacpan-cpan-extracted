use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::cpanminus::reporter',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/App/cpanminus/reporter.pm',
    ABSTRACT_FROM       => 'lib/App/cpanminus/reporter.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.48
        ? (MIN_PERL_VERSION    => '5.8.1')
        : ()
    ),
    PREREQ_PM => {
        'CPAN::Meta::Converter'         => 0,
        'CPAN::Testers::Common::Client' => 0.14,
        'Capture::Tiny'                 => 0,
        'Carp'                          => 0,
        'Config::Tiny'                  => 2.08,
        'File::Spec'                    => 3.19,
        'Getopt::Long'                  => 0,
        'IO::Prompt::Tiny'              => 0,
        'Metabase::Resource'            => 0,
        'Parse::CPAN::Meta'             => 0,
        'Pod::Usage'                    => 0,
        'Test::More'                    => 0,
        'Test::Reporter'                => '1.54',
        'Try::Tiny'                     => 0,
        'URI'                           => 0,

        # this should probably be under 'recommends',
        # but cpanm doesn't appear to handle recommendations
        'LWP::Protocol::https'                => 0,
        'Test::Reporter::Transport::Metabase' => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/garu/App-cpanminus-reporter',
            bugtracker => 'https://github.com/garu/App-cpanminus-reporter/issues/',
            license    => 'perl',
        },
    },

    EXE_FILES => [ 'bin/cpanm-reporter' ],
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean     => { FILES => 'App-cpanminus-reporter-*' },
);
