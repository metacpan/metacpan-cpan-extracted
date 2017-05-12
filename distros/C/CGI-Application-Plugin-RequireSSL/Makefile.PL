use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Application::Plugin::RequireSSL',
    AUTHOR              => 'Dan Horne <dhorne@cpan.org>',
    VERSION_FROM        => 'lib/CGI/Application/Plugin/RequireSSL.pm',
    ABSTRACT_FROM       => 'lib/CGI/Application/Plugin/RequireSSL.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'          => 0,
        'Attribute::Handlers' => 0,
        'CGI::Application'    => 4.01,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Plugin-RequireSSL-*' },
);
