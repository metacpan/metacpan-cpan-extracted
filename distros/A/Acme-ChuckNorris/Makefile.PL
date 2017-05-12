use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Acme::ChuckNorris',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Acme/ChuckNorris.pm',
    ABSTRACT_FROM => 'lib/Acme/ChuckNorris.pod',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'     => 0,
        'Acme::EyeDrops' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Acme-ChuckNorris-*' },
);
