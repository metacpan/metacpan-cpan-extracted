use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CairoX::CuttingLine',
    AUTHOR              => 'Cornelius <cornelius.howl@gmail.com>',
    VERSION_FROM        => 'lib/CairoX/CuttingLine.pm',
    ABSTRACT_FROM       => 'lib/CairoX/CuttingLine.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Cairo' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CairoX-CuttingLine-*' },
);
