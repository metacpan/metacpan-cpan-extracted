use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'CPANPLUS::Shell::Default::Plugins::Diff',
    VERSION_FROM    => 'lib/CPANPLUS/Shell/Default/Plugins/Diff.pm',
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => {    'Text::Diff'                => 0,
                            'CPANPLUS'                  => '0.059',
                            'Params::Check'             => '0.23',
                            'Locale::Maketext::Simple'  => 0,
                    },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
    ABSTRACT        => 'CPANPLUS shell plugin for displaying differences between released modules'
);             

