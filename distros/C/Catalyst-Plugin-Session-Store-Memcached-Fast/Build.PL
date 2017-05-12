use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Catalyst::Plugin::Session::Store::Memcached::Fast',
    requires           => { 'Catalyst::Runtime' => 5.7000, 'Cache::Memcached::Fast' => 0.00, 'Catalyst::Plugin::Session' => 0.01 },
    reccomends         => {},
    create_readme      => 1,
    sign               => 0,
);
$build->create_build_script;
