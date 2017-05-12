use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::kevinz',
    AUTHOR              => q{E. Kevin Zembower <kzembower@verizon.net>},
    VERSION_FROM        => 'lib/Acme/kevinz.pm',
    ABSTRACT_FROM       => 'lib/Acme/kevinz.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-kevinz-*' },
);
