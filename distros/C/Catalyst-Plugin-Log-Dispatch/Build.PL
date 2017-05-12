use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Catalyst::Plugin::Log::Dispatch',
    license           => 'perl',
    dist_author       => 'Shota Takayama <shot[at]bindstorm.jp>',
    dist_version_from => 'lib/Catalyst/Plugin/Log/Dispatch.pm',
    requires          => {
        'Test::More'         => 0,
        'Log::Dispatch'      => '2.13',
        'Catalyst'           => '5.65',
        'UNIVERSAL::require' => 0
    },
    add_to_cleanup => ['Catalyst-Plugin-Log-Dispatch-*'],
);

$builder->create_build_script();
