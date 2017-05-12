use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Color::Model::RGB',
    AUTHOR              => q{T.Onodera <ong@garakuta.net>},
    VERSION_FROM        => 'lib/Color/Model/RGB.pm',
    ABSTRACT_FROM       => 'lib/Color/Model/RGB.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'POSIX' => 0,
        'Exporter' => 0,
        'Carp' => 0,
        'Scalar::Util' => 0,

        'Math::VectorReal' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Color-Model-RGB-*' },
);
