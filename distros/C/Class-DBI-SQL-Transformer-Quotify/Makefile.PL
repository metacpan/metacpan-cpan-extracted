use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::DBI::SQL::Transformer::Quotify',
    AUTHOR              => 'David Westbrook <dwestbrook@gmail.com>',
    VERSION_FROM        => 'lib/Class/DBI/SQL/Transformer/Quotify.pm',
    ABSTRACT_FROM       => 'lib/Class/DBI/SQL/Transformer/Quotify.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Class::DBI' => '3.0.8',
	'DBD::Mock'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-DBI-SQL-Transformer-Quotify-*' },
);
