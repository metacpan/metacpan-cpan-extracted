use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Array::Assign',
    AUTHOR              => q{M. Nunberg <mnunberg@haskalah.org>},
    VERSION_FROM        => 'lib/Array/Assign.pm',
    ABSTRACT_FROM       => 'lib/Array/Assign.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Array-Assign-*' },
);
