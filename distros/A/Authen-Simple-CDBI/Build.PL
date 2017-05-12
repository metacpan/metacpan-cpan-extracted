use strict;
use Module::Build;

my $build = Module::Build->new(
    license            => 'perl',
    module_name        => 'Authen::Simple::CDBI',
    requires           => {
        'Authen::Simple' => 0.3,
        'Class::DBI'     => 0.96
    },
    create_makefile_pl => 'traditional',
    create_readme      => 1
);

$build->create_build_script;
