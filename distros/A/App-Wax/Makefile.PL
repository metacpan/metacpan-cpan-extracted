use 5.014000;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval($ExtUtils::MakeMaker::VERSION);

my $META_MERGE = {
    resources => {
        repository => 'https://github.com/chocolateboy/wax',
        bugtracker => 'https://github.com/chocolateboy/wax/issues',
    },
};

my $TEST_REQUIRES = {
    'Test::Differences' => '0.72',

    # the latest version (0.05) is not available:
    # https://github.com/sukria/Test-TinyMocker/issues/8
    'Test::TinyMocker' => '0.03',
};

WriteMakefile(
    ABSTRACT_FROM  => 'lib/App/Wax.pod',
    AUTHOR         => 'chocolateboy <chocolate@cpan.org>',
    EXE_FILES      => ['bin/wax'],
    NAME           => 'App::Wax',
    VERSION_FROM   => 'lib/App/Wax.pm',
    PREREQ_PM      => {
        'Digest::SHA'                => '0',
        'File::BaseDir'              => '0.09',
        'File::Slurper'              => '0.014',
        'Function::Parameters'       => '2.002005',
        'IPC::System::Simple'        => '1.30',
        'LWP'                        => '6.79',
        'MIME::Types'                => '2.28',
        'Mouse'                      => 'v2.5.11',
        'Parallel::parallel_map'     => '0.03',
        'Try::Tiny'                  => '0.32',
        'URI'                        => '5.32',
        'version'                    => '0.77',
    },
    ($EUMM_VERSION >= 6.5503 ? (BUILD_REQUIRES => $TEST_REQUIRES) : ()),
    ($EUMM_VERSION >= 6.31 ? (LICENSE => 'artistic_2') : ()),
    ($EUMM_VERSION >= 6.46 ? (META_MERGE => $META_MERGE) : ()),
    ($EUMM_VERSION >= 6.48 ? (MIN_PERL_VERSION => '5.14.0') : ()),
);
