use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'DBIx::Class::EncodeColumns',
    requires           => { 'DBIx::Class' => 0.00 },
    reccomends         => {},
    create_readme      => 1,
    sign               => 0,
);
$build->create_build_script;
