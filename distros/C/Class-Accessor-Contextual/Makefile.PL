use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::Accessor::Contextual',
    AUTHOR              => q{Brian Duggan <bduggan@matatu.org>},
    VERSION_FROM        => 'lib/Class/Accessor/Contextual.pm',
    ABSTRACT_FROM       => 'lib/Class/Accessor/Contextual.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Class::Accessor' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-Accessor-Contextual-*' },
);
