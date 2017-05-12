use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::UNIVERSAL::cannot',
    AUTHOR              => 'Tomas Doran <bobtfish@bobtfish.net>',
    VERSION_FROM        => 'lib/Acme/UNIVERSAL/cannot.pm',
    ABSTRACT_FROM       => 'lib/Acme/UNIVERSAL/cannot.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-UNIVERSAL-cannot-*' },
);
