use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::RohlfsC',
    AUTHOR              => q{Chris Rohlfs <chris@rohlfs.org>},
    VERSION_FROM        => 'lib/Acme/RohlfsC.pm',
    ABSTRACT_FROM       => 'lib/Acme/RohlfsC.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-RohlfsC-*' },
);
