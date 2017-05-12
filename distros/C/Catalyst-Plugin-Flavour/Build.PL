use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name => 'Catalyst::Plugin::Flavour',
    license     => 'perl',
    requires    => { Catalyst => '5.50', },
)->create_build_script;
