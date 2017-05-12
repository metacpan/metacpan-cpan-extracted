use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    'module_name' => "Acme::Gosub",
    dist_author => 'Shlomi Fish <shlomif@cpan.org>',
    'requires' =>
    {
        'Carp' => 0,
        'Filter::Util::Call' => 0,
        'Text::Balanced' => 0,
        'perl' => '5.008',
        'strict' => 0,
        'vars' => 0,
        'warnings' => 0,
    },
    build_requires =>
    {
        'Module::Build' => '0.37',
        'Test::More' => 0,
    },
    'license' => "perl",
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/perl-acme-gosub",
        },
        keywords =>
        [
            "Acme",
            "BASIC",
            "black magick",
            "gosub",
            "joke",
            "retro",
            "source filter",
            "subroutine",
        ],
    },

);
$build->create_build_script;

