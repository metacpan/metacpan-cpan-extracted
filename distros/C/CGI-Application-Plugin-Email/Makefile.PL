use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Application::Plugin::Email',
    AUTHOR              => 'Lyle Hopkins <webmaster@cosmicperl.com>',
    VERSION_FROM        => 'lib/CGI/Application/Plugin/Email.pm',
    ABSTRACT_FROM       => 'lib/CGI/Application/Plugin/Email.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'       => 0,
        'Email::Stuff'     => 0,
        'CGI::Application' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Plugin-Email-*' },
);
