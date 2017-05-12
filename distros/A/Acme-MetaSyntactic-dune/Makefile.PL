use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::MetaSyntactic::dune',
    AUTHOR              => q{Mike Cartmell <mike@mikec.me>},
    VERSION_FROM        => 'lib/Acme/MetaSyntactic/dune.pm',
    ABSTRACT_FROM       => 'lib/Acme/MetaSyntactic/dune.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
				'Acme::MetaSyntactic' => 1.00,
				'Acme::MetaSyntactic::List' => 1.00,
				'Acme::MetaSyntactic::MultiList' => 1.00,
				'parent' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-MetaSyntactic-dune-*' },
);
