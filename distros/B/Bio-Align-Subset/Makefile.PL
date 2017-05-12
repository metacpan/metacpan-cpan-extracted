use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bio::Align::Subset',
    AUTHOR              => q{Hector Valverde and Juan Carlos Aledo <hvalverdeuma.es>},
    VERSION_FROM        => 'lib/Bio/Align/Subset.pm',
    ABSTRACT_FROM       => 'lib/Bio/Align/Subset.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bio-Align-Subset-*' },
);
