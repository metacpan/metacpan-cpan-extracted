use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Session::Flash',
    AUTHOR              => 'Bradley C Bailey <cgi-session-flash@brad.memoryleak.org>',
    VERSION_FROM        => 'lib/CGI/Session/Flash.pm',
    ABSTRACT_FROM       => 'lib/CGI/Session/Flash.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'   => 0,
        'CGI::Session' => 4,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Session-Flash-*' },
);
