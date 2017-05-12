use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::EmptyGIF',
    AUTHOR              => q{David Moreno <david@axiombox.com},
    VERSION_FROM        => 'lib/Dancer/Plugin/EmptyGIF.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/EmptyGIF.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Dancer'        => 0,
        'Test::More'    => 0,
        'lib::abs'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-EmptyGIF-*' },
);
