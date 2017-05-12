use strict;

use Module::Build;

my $build = Module::Build->new(
    module_name        => 'DBIx::Class::Indexed',
    dist_author        => 'Adam Paynter <adapay@cpan.org>',
    license            => 'perl',
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    requires           => {
        'DBIx::Class' => 0,
        'Module::Load' => 0.22
    },
    build_requires     => {
        'Test::More' => 0
    }
);

$build->create_build_script;
