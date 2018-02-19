use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::CopyrightImage',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/App/CopyrightImage.pm',
    ABSTRACT_FROM    => 'lib/App/CopyrightImage.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    EXE_FILES        => [
        'bin/imgcopyright'
    ],
    MIN_PERL_VERSION => 5.006,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/stevieb9/p5-app-copyrightimage/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/p5-app-copyrightimage.git',
                web => 'https://github.com/stevieb9/p5-app-copyrightimage',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'File::Copy' => 0,
        'File::Path' => 0,
        'Hook::Output::Tiny' => 0.05,
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'File::Find::Rule'  => 0,
        'Getopt::Long'      => 0,
        'Image::ExifTool'   => 10.20,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-CopyrightImage-*' },
);
