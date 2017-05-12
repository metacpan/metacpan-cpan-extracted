use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name => 'Catalyst::Plugin::Email::Japanese',
    license     => 'perl',
    requires    => {
        'MIME::Lite::TT::Japanese'       => 0,
        'MIME::Lite::TT::HTML::Japanese' => '0.05',
        Catalyst                         => '5.30',
    },
    recommends => { 'Template::Provider::Encoding' => 0, },
)->create_build_script;
