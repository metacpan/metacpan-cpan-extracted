use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::Scoped',
    AUTHOR              => q{Roman Galeev <jamhedd@gmail.com>},
    VERSION_FROM        => 'lib/Dancer/Plugin/Scoped.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/Scoped.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-Scoped-*' },
);
