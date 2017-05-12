use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Authen::Simple::WebForm',
    AUTHOR              => 'Joshua I. Miller <unrtst@cpan.org>',
    VERSION_FROM        => 'lib/Authen/Simple/WebForm.pm',
    ABSTRACT_FROM       => 'lib/Authen/Simple/WebForm.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'URI'                       => 0,
        'LWP'                       => 0,
        'LWP::ConnCache'            => 0,
        'HTTP::Cookies'             => 0,
        'Test::More'                => 0,
        'Authen::Simple::Adapter'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Authen-Simple-WebForm-*' },
);
