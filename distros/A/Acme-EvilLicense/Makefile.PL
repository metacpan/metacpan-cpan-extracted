use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::EvilLicense',
    AUTHOR              => q{Evil Hacker <blackhole@krot.org>},
    VERSION_FROM        => 'lib/Acme/EvilLicense.pm',
    ABSTRACT_FROM       => 'lib/Acme/EvilLicense.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'evil')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-EvilLicense-*' },
);
