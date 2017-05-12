use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DataFlow::Proc::DBF',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/DataFlow/Proc/DBF.pm',
    ABSTRACT_FROM       => 'lib/DataFlow/Proc/DBF.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'           => 0,
        'DataFlow'             => 1.111480, # DataFlow::Proc::Converter
        'Moose'                => 1.09,
        'MooseX::Aliases'      => 0,
        'XBase'                => 0,
        'File::Temp'           => 0,
        'File::Spec'           => 0,
        'autodie'              => 0,
        'namespace::autoclean' => 0,
    },

    META_MERGE      => {
        resources => {
            license     =>      'http://dev.perl.org/licenses/',
            bugtracker  =>      'http://rt.cpan.org/NoAuth/Bugs.html?Dist=DataFlow-Proc-DBF',
            repository  =>      'http://github.com/garu/DataFlow-Proc-DBF',
        },
    },

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DataFlow-Proc-DBF-*' },
);
