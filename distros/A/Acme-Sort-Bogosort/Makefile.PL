use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Sort::Bogosort',
    AUTHOR              => q{David Oswald <davido[at]cpan.org>},
    VERSION_FROM        => 'lib/Acme/Sort/Bogosort.pm',
    ABSTRACT_FROM       => 'lib/Acme/Sort/Bogosort.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Try::Tiny'  => 0,
        'Test::More' => 0,
        'parent'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Sort-Bogosort-*' },
);
