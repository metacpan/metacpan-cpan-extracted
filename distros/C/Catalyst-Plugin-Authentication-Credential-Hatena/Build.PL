use Module::Build;

# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name => 'Catalyst::Plugin::Authentication::Credential::Hatena',
    license     => 'perl',
    requires    => {
        Catalyst            => '5.50',
        'Hatena::API::Auth' => '0.02',
    },
    build_requires => { 'Test::MockObject' => '1.06', },
)->create_build_script;
