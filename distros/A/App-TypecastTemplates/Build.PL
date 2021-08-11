use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'App::TypecastTemplates',
    license             => 'artistic_2',
    dist_author         => q{Mathias Weidner <mamawe@cpan.org>},
    dist_version_from   => 'lib/App/TypecastTemplates.pm',
    release_status      => 'stable',
    configure_requires  => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More'    => '0',
    },
    requires => {
        'Template'      => 0,
        'Text::CSV'     => 0,
    },
    add_to_cleanup      => [ 'App-TypecastTemplates-*' ],
    script_files        => [ 'bin/create_cloginrc' ],
);

$builder->create_build_script();
