use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name => 'Catalyst::Plugin::Authentication::Credential::Flickr',
    license     => 'perl',
    requires    => {
        Catalyst                           => '5.50',
        'Flickr::API'                      => 0,
        'Catalyst::Plugin::Authentication' => 0,
        'Catalyst::Plugin::Session'        => 0,
        'UNIVERSAL::require'               => 0,
    },
)->create_build_script;
