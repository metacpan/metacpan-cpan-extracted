use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name	   => 'Bundle::Sites::BetterScm',
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
        'HTML::Widgets::NavMenu' => 0,
        'Template' => 0,
        'XML::CompareML' => 0,
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
            repository => "https://bitbucket.org/shlomif/better-scm/",
        },
    },
);

$build->create_build_script;
