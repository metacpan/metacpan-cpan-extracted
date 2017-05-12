use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    'module_name' => 'Class::Generate',
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    'requires' =>
    {
        Carp => 0,
        Symbol => 0,
        perl => '5.010',
        strict => 0,
        vars => 0,
        warnings => 0,
    },
    test_requires =>
    {
        'Text::Soundex' => 0,
        'Text::Tabs' => 0,
    },
    'license' => 'perl',
    meta_merge =>
    {
        resources =>
        {
            repository => 'https://github.com/shlomif/perl-Class-Generate',
        },
    },
);
$build->create_build_script;
