use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Application::Plugin::Routes',
    AUTHOR              => 'Julián Porta <julian.porta@gmail.com>',
    VERSION_FROM        => 'lib/CGI/Application/Plugin/Routes.pm',
    ABSTRACT_FROM       => 'lib/CGI/Application/Plugin/Routes.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Plugin-Routes-*' },
);
