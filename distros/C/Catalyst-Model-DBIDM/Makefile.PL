use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Model::DBIDM',
    AUTHOR              => 'Cedric Bouvier <cbouvi@cpan.org>',
    VERSION_FROM        => 'lib/Catalyst/Model/DBIDM.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Model/DBIDM.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'DBIx::DataModel' => 0,
        'DBI'             => 0,
        'Catalyst::Model' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Model-DBIDM-*' },
);
