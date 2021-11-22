#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $github_slug = 'acme/archive-peek';
WriteMakefile(
    NAME         => 'Archive::Peek',
    VERSION_FROM => 'lib/Archive/Peek.pm',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    ABSTRACT     => 'Peek into archives without extracting them',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Archive::Tar'               => '0',
        'Archive::Zip'               => '0',
        'Moo'                        => '0',
        'Types::Path::Tiny'          => '0',
        'Carp'                       => '0',
    },
    TEST_REQUIRES => {
        'Test::More'                 => '0',
        'File::Temp'                 => '0',
    },
    META_MERGE   => {
        "meta-spec" => { version => 2 },
        resources => {
            bugtracker  => { web => "https://github.com/$github_slug/issues" },
            repository  => {
                url => "git://github.com/$github_slug.git",
                type => 'git',
                web => "https://github.com/$github_slug",
            },
        },
        prereqs => {
            develop => {
                requires => {
                    'Test::Pod'      => '1.14',
                },
            },
        },
    },
);

