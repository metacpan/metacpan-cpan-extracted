use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::View::PDF::Reuse',
    AUTHOR              => 'Jon Allen <jj@pennysarcade.co.uk>',
    VERSION_FROM        => 'lib/Catalyst/View/PDF/Reuse.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/View/PDF/Reuse.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Catalyst::View::TT' => 0,
        'PDF::Reuse' => 0,
        'File::chdir' => 0,
        'Template::Plugin::Procedural' => 0,
        'parent' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-View-PDF-Reuse-*' },
);
