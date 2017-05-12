use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Predicate',
    AUTHOR              => q{"ayates" <"">},
    VERSION_FROM        => 'lib/Data/Predicate.pm',
#    ABSTRACT_FROM       => 'lib/Data/Predicate.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'bsd')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Scalar::Util' => 0,
        'Readonly' => 0,
        'Test::Exception' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Predicates-*' },
);
