use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AuthCAS',
    AUTHOR              => 'Olivier Salaun <os AT cru.fr>',
    VERSION_FROM        => 'lib/AuthCAS.pm',
    ABSTRACT_FROM       => 'lib/AuthCAS.pm',
    PREREQ_PM => {
        'IO::Socket::SSL' => 0,
	'LWP::UserAgent' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AuthCAS-*' },
);
