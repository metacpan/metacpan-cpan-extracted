use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Application::Plugin::DBIProfile',
    AUTHOR              => 'Sam Tregar <sam@tregar.com>',
    VERSION_FROM        => 'lib/CGI/Application/Plugin/DBIProfile.pm',
    ABSTRACT_FROM       => 'lib/CGI/Application/Plugin/DBIProfile.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'IO::Scalar'       => 0,
        'Data::JavaScript' => 0,
        'Symbol'           => 0,
        'Test::More'       => 0,
        'CGI::Application' => 4,
        'DBI'              => 1.49,
        'Time::HiRes'      => 0,
        'HTML::Template'   => 2.6,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Plugin-DBIProfile-*' },
);
