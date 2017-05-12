use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Authen::Class::HtAuth',
    AUTHOR              => 'Ryan McGuigan <ryan@cardweb.com>',
    VERSION_FROM        => 'lib/Authen/Class/HtAuth.pm',
    ABSTRACT_FROM       => 'lib/Authen/Class/HtAuth.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Apache::Htpasswd' => 0,
        'Apache::Htgroup' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Authen-Class-HtAuth-*' },
);
