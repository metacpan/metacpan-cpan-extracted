use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name	   => 'Bundle::Latemp',
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    requires =>
    {
        'CGI' => 0,
        'Class::Accessor' => 0,
        'Data::Dumper' => 0,
        'File::Basename' => 0,
        'File::Find::Rule' => 0,
        'File::Path' => 0,
        'Getopt::Long' => 0,
        'HTML::Latemp::GenMakeHelpers' => 0,
        'HTML::Latemp::NavLinks::GenHtml' => 0,
        'HTML::Latemp::News' => 0,
        'HTML::Widgets::NavMenu' => 0,
        'Pod::Usage' => 0,
        'Template' => 0,
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
            repository => "https://bitbucket.org/shlomif/latemp",
        },
    },
);

$build->create_build_script;
