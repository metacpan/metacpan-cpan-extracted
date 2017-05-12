use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name	   => 'Bundle::GimpTest',
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    VERSION_FROM => 'lib/Bundle/GimpTest.pm',
    requires =>
    {
        'Digest::MD5' => 0,
        'Getopt::Long' => 0,
        'IO::All' => 0,
        'Net::SeedServe' => 0,
        'String::ShellQuote' => 0,
        'Time::HiRes' => 0,
        'YAML' => 0,
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
            repository => "https://bitbucket.org/shlomif/gimp-test-suite",
        },
    },
);

$build->create_build_script;
