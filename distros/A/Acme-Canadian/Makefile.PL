use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Canadian',
    AUTHOR              => 'John Cappiello <jcap at cpan.org>',
    VERSION_FROM        => 'lib/Acme/Canadian.pm',
    ABSTRACT_FROM       => 'lib/Acme/Canadian.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Canadian-*' },
);
