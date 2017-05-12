use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::phillup',
    AUTHOR              => q{Phillip W. Upton <test@philsplace.org>},
    VERSION_FROM        => 'lib/Acme/phillup.pm',
    ABSTRACT_FROM       => 'lib/Acme/phillup.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-phillup-*' },
);
