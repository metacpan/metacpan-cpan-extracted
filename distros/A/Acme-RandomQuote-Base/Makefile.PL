use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::RandomQuote::Base',
    AUTHOR              => 'Diogo Neves <dafneves@mangaru.net>',
    VERSION_FROM        => 'lib/Acme/RandomQuote/Base.pm',
    ABSTRACT_FROM       => 'lib/Acme/RandomQuote/Base.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'File::RandomLine' => '0.19',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-RandomQuote-Base-*' },
);
