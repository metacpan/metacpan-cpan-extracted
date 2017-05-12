use strict;
use warnings;
use Module::Build::SysPath;

my $builder = Module::Build::SysPath->new(
    module_name => 'Acme::SysPath',
    license     => 'perl',
    configure_requires => {
        'IO::Any' => 0,
        'Module::Build::SysPath' => 0.09,
    },
    build_requires => {
        'Module::Build::SysPath' => 0.09,
    },
    requires => {
        'File::Spec' => 0,
        'IO::Any'    => 0,
    },
    conffiles => [
        [ 'conf', 'acme-syspath.cfg' ],
    ],
);

$builder->create_build_script();
