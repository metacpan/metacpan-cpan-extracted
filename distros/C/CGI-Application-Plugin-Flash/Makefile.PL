use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Application::Plugin::Flash',
    AUTHOR              => 'Bradley C Bailey <cap-flash@brad.memoryleak.org>',
    VERSION_FROM        => 'lib/CGI/Application/Plugin/Flash.pm',
    ABSTRACT_FROM       => 'lib/CGI/Application/Plugin/Flash.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                        => 0,
        'CGI::Application'                  => 4,
        'CGI::Application::Plugin::Session' => 1.0,
        'CGI::Session::Flash'               => 0.02,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Plugin-Flash-*' },
);
