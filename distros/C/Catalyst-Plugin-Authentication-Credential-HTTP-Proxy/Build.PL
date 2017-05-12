use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name => 'Catalyst::Plugin::Authentication::Credential::HTTP::Proxy',
    requires    => {
        'Catalyst'                         => '5.5',
        'Catalyst::Plugin::Authentication' => 0,
        'Test::MockObject'                 => '1.01',
        'LWP::Simple'                      => 0,
    },
    create_readme => 1,
    sign          => 1,
);
$build->create_build_script;

