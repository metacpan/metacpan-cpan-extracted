use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name	   => 'Bundle::QuadPres',
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    requires =>
    {
        'CGI' => 0,
        'Config::IniFiles' => 0,
        'Data::Dumper' => 0,
        'Error' => 0,
        'File::Find' => 0,
        'Getopt::Long' => 0,
        'HTML::Links::Localize' => 0,
        'MIME::Types' => 0,
        'perl' => '5.008',
        'strict' => 0,
        'vars' => 0,
        'warnings' => 0,
    },
    license => "mit",
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/quad-pres",
        },
    },
);

$build->create_build_script;
