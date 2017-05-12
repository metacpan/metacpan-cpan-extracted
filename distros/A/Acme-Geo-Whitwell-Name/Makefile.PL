use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Geo::Whitwell::Name',
    AUTHOR              => 'Joe McMahon <mcmahon@cpan.org>',
    VERSION_FROM        => 'lib/Acme/Geo/Whitwell/Name.pm',
    ABSTRACT_FROM       => 'lib/Acme/Geo/Whitwell/Name.pm',
    LICENSE             => 'artistic',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Geo-Whitwell-Name-*' },
);
