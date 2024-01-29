# -*- cperl; cperl-indent-level: 4 -*-
use 5.014;
use strict;
use warnings;
use Module::Build;
use lib 'inc';
use Date::Extract::P800Picture::Module::Build;

our $VERSION = v1.1.7;

Date::Extract::P800Picture::Module::Build->new(
    'module_name'   => 'Date::Extract::P800Picture',
    'license'       => 'perl',
    'dist_author'   => 'Roland van Ipenburg <roland@rolandvanipenburg.com>',
    'dist_abstract' => 'Extract the date from Sony Ericsson P800 pictures',
    'requires'      => {
        'DateTime'                => 0,
        'English'                 => 0,
        'Exception::Class'        => 0,
        'File::Basename'          => 0,
        'File::Slurp'             => 0,
        'File::stat'              => 0,
        'Getopt::Long'            => 0,
        'Image::ExifTool'         => 0,
        'Log::Log4perl'           => 0,
        'Moose'                   => 0,
        'POSIX'                   => 0,
        'Pod::Usage'              => 0,
        'Pod::Usage::CommandLine' => 0,
        'Readonly'                => 0,
        'perl'                    => '5.14.0',
        'strict'                  => 0,
        'utf8'                    => 0,
        'warnings'                => 0,
    },
    'configure_requires' => { 'Module::Build' => 0.40, },
    'build_requires'     => { 'Module::Build' => 0.40, },
    'recommends'         => {
        'Module::Signature' => 0,
    },
    'test_requires' => {
        'Test::Compile' => 0,
        'Test::More'    => 0.81,
    },
    'script_files' => [ qw(bin/p800date bin/p800exif), ],
    'sign'         => 1,
    'meta_merge'   => {
        'resources' => {
            'repository' =>
'https://bitbucket.org/rolandvanipenburg/date-extract-p800picture',
            'bugtracker' =>
'https://bitbucket.org/rolandvanipenburg/date-extract-p800picture/issues',
        },
        'x_authority' => 'cpan:IPENBURG',
    },
)->create_build_script;
