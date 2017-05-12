use strict;

use Module::Build;

my $build = Module::Build->new(
    module_name        => 'DBIx::Class::Loader::ADO',
    dist_author        => 'Brian Cassidy <bricas@cpan.org>',
    license            => 'perl',
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    requires           => {
        'DBIx::Class::Loader' => '0.21',
        'DBIx::Class'         => '0.07003',
        'DBD::ADO'            => 0
    },
    build_requires     => {
        'Test::More'  => 0
    },
);
$build->create_build_script;
