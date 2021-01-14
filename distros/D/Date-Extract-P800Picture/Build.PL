use strict;
use warnings;
use Module::Build;
Module::Build->new(
    module_name => 'Date::Extract::P800Picture',
    license     => 'perl',
    dist_author => 'Roland van Ipenburg <roland@rolandvanipenburg.com>',
    requires    => {
        'perl'                    => '5.14.0',
        'POSIX'                   => 0,
        'Exception::Class'        => 0,
        'English'                 => 0,
        'Readonly'                => 0,
        'DateTime'                => 0,
        'Moose'                   => 0,
        'Log::Log4perl'           => 0,
        'Image::ExifTool'         => 0,
        'File::Basename'          => 0,
        'File::Slurp'             => 0,
        'File::stat'              => 0,
        'Getopt::Long'            => 0,
        'Pod::Usage'              => 0,
        'Pod::Usage::CommandLine' => 0,
    },
    configure_requires => { 'Module::Build' => 0.40, },
    build_requires     => { 'Test::More'    => 0.81, },
    recommends         => {
        'Module::Signature' => 0,
    },
    test_requires => {
        'Test::Compile'              => 0,
        'Test::Pod'                  => 1.00,
        'Test::Pod::Coverage'        => 1.00,
        'Test::TestCoverage'         => 0.08,
        'Test::Kwalitee'             => 0,
        'Perl::Critic'               => 0,
        'Perl::Critic::StricterSubs' => 0,
    },
    script_files => [ qw(bin/p800date bin/p800exif), ],
    sign         => 1,
    meta_merge   => {
        resources => {
            repository =>
              'https://bitbucket.org/rolandvanipenburg/date-extract-p800picture',
            bugtracker => {
              web => 'https://bitbucket.org/rolandvanipenburg/date-extract-p800picture/issues'
            }
        }
    },
)->create_build_script;
