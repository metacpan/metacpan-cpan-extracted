use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'CPANPLUS::Shell::Default::Plugins::RT',
    VERSION_FROM    => 'lib/CPANPLUS/Shell/Default/Plugins/RT.pm',
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => {    'LWP'                       => 0,
                            'CPANPLUS'                  => '0.059',
                            'Params::Check'             => '0.23',
                            'Locale::Maketext::Simple'  => 0,
                    },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
    ABSTRACT        => 'CPANPLUS shell plugin for for querying rt.cpan.org tickets for a given distribution'
);             
