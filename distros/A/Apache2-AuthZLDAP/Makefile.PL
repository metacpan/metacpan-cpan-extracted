use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Apache2::AuthZLDAP',
    AUTHOR              => 'Dominique Launay <dominique.launay AT cru.fr>',
    VERSION_FROM        => 'lib/Apache2/AuthZLDAP.pm',
    ABSTRACT_FROM       => 'lib/Apache2/AuthZLDAP.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'mod_perl2' => 0,
	'Net::LDAPS' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache2-AuthZLDAP-*' },
);
