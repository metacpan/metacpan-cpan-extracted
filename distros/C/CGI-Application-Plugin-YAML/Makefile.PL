use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Application::Plugin::YAML',
    AUTHOR              => 'Lyle Hopkins <webmaster@cosmicperl.com>',
    VERSION_FROM        => 'lib/CGI/Application/Plugin/YAML.pm',
    ABSTRACT_FROM       => 'lib/CGI/Application/Plugin/YAML.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'       => 0,
        'YAML'             => 0.67,
        'CGI::Application' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Plugin-YAML-*' },
);
