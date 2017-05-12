use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Color::Model::Munsell::Util',
    AUTHOR              => q{Takahiro Onodera <ong@garakuta.net>},
    VERSION_FROM        => 'lib/Color/Model/Munsell/Util.pm',
    ABSTRACT_FROM       => 'lib/Color/Model/Munsell/Util.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'bsd')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Color::Model::RGB' => 0,
        'Color::Model::Munsell' => 0,
        'Math::VectorReal' => 0,
        'Scalar::Util' => 0,
        'List::Util' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Color-Model-Munsell-Util-*' },
);
