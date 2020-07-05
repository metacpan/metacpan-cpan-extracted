use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker;


my %WriteMakefileArgs = (
    "ABSTRACT" => "Pack PAR executables, finding dynamic libs automatically",
    "AUTHOR"   => 'Shawn Laffan <shawnlaffan@gmail.com>',
    "NAME"     => "App::PP::Autolink",
    "VERSION_FROM" => "lib/App/PP/Autolink.pm",
    "CONFIGURE_REQUIRES" => {
    },
    "BUILD_REQUIRES" => {
    },
    "TEST_REQUIRES" => {
        "Test::More" => 0,
        "File::Which" => 0,
    },
    "PREREQ_PM" => {
        'Capture::Tiny'    => '0.48',
        'File::Find::Rule' => 0,
        'File::Which'      => 0,
        'Getopt::ArgvFile' => 0,
        'Module::ScanDeps' => '1.27',
        'PAR::Packer'      => '1.049',
        'Path::Tiny'       => '0.108',
        'rlib'             => '0.02',
        'List::Util'       => '1.45',
        'Env'              => 0,
    },
    EXE_FILES		=> [
        'bin/pp_autolink.pl',
    ],
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/shawnlaffan/perl-pp-autolink',
            },
            bugtracker => {
                web => 'https://github.com/shawnlaffan/perl-pp-autolink/issues/',
            },
        },
    },
    "DISTNAME" => "App-PP-Autolink",
    "LICENSE"  => "perl_5",
);


WriteMakefile(%WriteMakefileArgs);

