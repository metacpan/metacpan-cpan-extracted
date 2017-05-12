use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bio::MaxQuant::Evidence::Statistics',
    AUTHOR              => q{jimi <j@0na.me>},
    VERSION_FROM        => 'lib/Bio/MaxQuant/Evidence/Statistics.pm',
    ABSTRACT_FROM       => 'lib/Bio/MaxQuant/Evidence/Statistics.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'artistic2')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
        'Text::CSV' => 0,
        'Test::More::Behaviour' => 0,
        'Statistics::Distributions' =>0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bio-MaxQuant-Evidence-Statistics-*' },
);
