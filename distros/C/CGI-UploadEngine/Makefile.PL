use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::UploadEngine',
    AUTHOR              => 'Roger A Hall <rogerhall@cpan.org>',
    VERSION_FROM        => 'lib/CGI/UploadEngine.pm',
    ABSTRACT            => 'Upload Engine for Multi-App Web Servers',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'           => 0,
        'version'              => 0,
        'Class::Std'           => 0.0.9,
        'Class::Std::Utils'    => 0.0.3,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-UploadEngine-*' },
);

