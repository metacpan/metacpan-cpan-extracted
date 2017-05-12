use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME                => 'Bio::LITE::Taxonomy::NCBI',
              AUTHOR              => q{Miguel Pignatelli <emepyc@gmail.com>},
              VERSION_FROM        => 'lib/Bio/LITE/Taxonomy/NCBI.pm',
              ABSTRACT_FROM       => 'lib/Bio/LITE/Taxonomy/NCBI.pm',
              ($ExtUtils::MakeMaker::VERSION >= 6.3002
               ? ('LICENSE'=> 'perl')
               : ()),
              PL_FILES            => {},
              PREREQ_PM => {
		  'Test::More' => 0.87,
		  'Bio::LITE::Taxonomy' => 0.07,
                           },
              dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              clean               => { FILES => 'Bio-LITE-Taxonomy-NCBI-*' },
);
