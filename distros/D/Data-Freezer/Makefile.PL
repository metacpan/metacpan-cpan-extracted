use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Freezer',
    AUTHOR              => 'Jerome Eteve <jerome@eteve.net>',
    VERSION_FROM        => 'lib/Data/Freezer.pm',
    ABSTRACT_FROM       => 'lib/Data/Freezer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Pixie' => '2.06',
	'Class::AutoAccess' => '0.02'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Freezer-*' },
);
