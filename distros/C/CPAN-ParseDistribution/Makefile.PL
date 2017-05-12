use ExtUtils::MakeMaker;
use strict;
use warnings;
WriteMakefile(
    NAME         => 'CPAN::ParseDistribution',
    META_MERGE => {
        resources => {
            bugtracker => 'https://github.com/DrHyde/perl-modules-CPAN-ParseDistribution/issues',
            repository => 'https://github.com/DrHyde/perl-modules-CPAN-ParseDistribution',
        }
    },
    VERSION_FROM => 'lib/CPAN/ParseDistribution.pm',
    PREREQ_PM    => {
        'Test::More'   => '0.88', # done_testing
        'Archive::Tar' => 0,
        'Archive::Zip' => 0,
        'File::Find::Rule' => 0,
        'YAML' => 0.60,
        'File::Temp' => 0,
        'File::Path' => 0,
        'Parallel::ForkManager' => 1.03,
        'Devel::CheckOS'        => 0,
    },
    EXE_FILES => [qw(
        bin/dumpcpandist
    )],
);
