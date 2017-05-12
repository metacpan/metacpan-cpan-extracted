#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Bisect::Perl::UsingGit',
    VERSION_FROM => 'lib/Bisect/Perl/UsingGit.pm',
    ABSTRACT     => 'Help you to bisect Perl',
    LICENSE      => 'perl',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    PREREQ_PM    => {
        'Capture::Tiny'              => '0',
        'Moose'                      => '0',
        'MooseX::Getopt'             => '0',
        'MooseX::Types::Path::Class' => '0',
        'Test::More'                 => '0.01',
    },
    EXE_FILES => ['bin/bisect_perl_using_git'],
);
