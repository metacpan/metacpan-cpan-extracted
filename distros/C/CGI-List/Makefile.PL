use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::List',
    AUTHOR              => 'David Romero Garcia <romdav@gmail.com>',
    VERSION_FROM        => 'lib/CGI/List.pm',
    ABSTRACT_FROM       => 'lib/CGI/List.pm',
    PREREQ_PM => {
        'Test::More' => 0,
        'Math::Round' => 0.01,
        'Number::Format' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-List-*' },
);
