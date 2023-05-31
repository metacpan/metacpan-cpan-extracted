use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CPAN::Porters',
    AUTHOR       => q{Gabor Szabo <szabgab@cpan.org>},
    VERSION_FROM => 'lib/CPAN/Porters.pm',
    ABSTRACT     => 'Description on how to created binary packages from CPAN distributions',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
    },
    TEST_REQUIRES => {
          'Test::More'    => 1.001014,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/szabgab/CPAN-Porters.git',
                 web  => 'https://github.com/szabgab/CPAN-Porters',
             },
             bugtracker => {
                 web => 'https://github.com/szabgab/CPAN-Porters/issues'
             },
         },
    },
);
