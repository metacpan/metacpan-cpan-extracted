use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Application::Plugin::BrowserDetect',
    AUTHOR              => 'Bradley C Bailey <cap-browserdetect@brad.memoryleak.org>',
    VERSION_FROM        => 'lib/CGI/Application/Plugin/BrowserDetect.pm',
    ABSTRACT_FROM       => 'lib/CGI/Application/Plugin/BrowserDetect.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'          => 0,
        'CGI::Application'    => 4,
        'HTTP::BrowserDetect' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Plugin-BrowserDetect-*' },
);
