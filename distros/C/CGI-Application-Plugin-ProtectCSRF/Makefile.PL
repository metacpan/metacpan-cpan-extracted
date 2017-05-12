use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Application::Plugin::ProtectCSRF',
    AUTHOR              => 'Akira Horimoto <kurt0027@gmail.com>',
    VERSION_FROM        => 'CGI/Application/Plugin/ProtectCSRF.pm',
    ABSTRACT_FROM       => 'CGI/Application/Plugin/ProtectCSRF.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        "Attribute::Handlers"               => 0.78,
        "CGI::Application"                  => 4.04,
        "CGI::Application::Plugin::Session" => 1.01,
        "Digest::SHA1"                      => 2.07,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Plugin-ProtectCSRF-*' },
);
