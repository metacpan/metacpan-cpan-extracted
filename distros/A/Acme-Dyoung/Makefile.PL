use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Dyoung',
    AUTHOR              => q{Dan Young <foo@bar.com>},
    VERSION_FROM        => 'lib/Acme/Dyoung.pm',
    ABSTRACT_FROM       => 'lib/Acme/Dyoung.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Dyoung-*' },
);
