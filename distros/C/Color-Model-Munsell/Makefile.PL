use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Color::Model::Munsell',
    AUTHOR              => q{Takahiro Onodera <ong@garakuta.net>},
    VERSION_FROM        => 'lib/Color/Model/Munsell.pm',
    ABSTRACT_FROM       => 'lib/Color/Model/Munsell.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'bsd')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Color-Model-Munsell-*' },
);
