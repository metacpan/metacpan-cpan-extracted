use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Random::Nucleotides',
    AUTHOR              => q{Assaf Gordon <gordon@cshl.edu>},
    VERSION_FROM        => 'lib/Data/Random/Nucleotides.pm',
    ABSTRACT_FROM       => 'lib/Data/Random/Nucleotides.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Test::More'  => 0,
        'Data::Random' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Random-Nucleotides-*' },
);
