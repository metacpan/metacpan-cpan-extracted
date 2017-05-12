use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Rad::Plugin::TT',
    AUTHOR              => 'Fernando Correa de Oliveira <fco@cpan.org>',
    VERSION_FROM        => 'lib/App/Rad/Plugin/TT.pm',
    ABSTRACT_FROM       => 'lib/App/Rad/Plugin/TT.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'App::Rad'   => 1.00,
        'Template'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Rad-Plugin-TT-*' },
);
