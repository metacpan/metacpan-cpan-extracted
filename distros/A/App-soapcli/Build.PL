#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use lib 'inc';
use Module::Build::My;

my $module = 'App::soapcli';

(my $dist = $module) =~ s/::/-/g;

my $build = Module::Build::My->new(
    module_name             => $module,
    dist_version_from       => 'script/soapcli.pl',
    license                 => 'perl',
    requires                => {
        'perl'                  => 5.010,   # use String::Print
        'Getopt::Long::Descriptive' => 0,
        'HTTP::Tiny'            => 0,
        'JSON::PP'              => 0,
        'Perl6::Slurp'          => 0,
        'XML::Compile::SOAP'    => 3.00,
        'XML::Compile::SOAP12'  => 0,
        'XML::Compile::WSDL11'  => 0,
        'YAML::Syck'            => 0,
        'YAML::XS'              => 0,
    },
    build_requires          => {
        'Test::More'            => 0,
    },
    script_files => 'script',
    auto_configure_requires => 0,
    create_makefile_pl      => 'traditional',
    create_readme           => 1,
    create_license          => 1,
    recursive_test_files    => 0,
    add_to_cleanup          => [
        '*.bak', '*.gz', '*.tgz', '*.ppd', '*.ppmx', '*.deb',
        'pm_to_blib', 'cover_db', 'Debian_CPANTS.txt',
        'compilet*', 'test-*',
        "$dist-*",
    ],
    meta_merge              => {
        resources               => {
            bugtracker => "http://github.com/dex4er/soapcli/issues",
            repository => "http://github.com/dex4er/soapcli",
        },
    },
);

$build->create_build_script;
